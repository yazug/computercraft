--[[

  Rectangular Quarry Program 1.2b
  by Adam Smith "shiphorns"
  March 7 2013

  1.0b -	Original public release
  1.1b -	Fixes bug with turtle using the wrong axis order when trying to return home after hitting
			and undiggable block. I erroneously had it trying to do moveTo(0,0,0) instead of goHome()
			which would result in the turtle trying to move in the x-direction first, and possibly
			getting blocked by bedrock when trying to move home.
  1.2b -    Fix for turtle getting stuck if turtle simultaneous encounters bedrock in front and above it.

--]]
local tArgs = { ... }
local sizeZ -- Quarry is this long in direction turtle is initially facing, including block turtle is on
local sizeX -- Quarry is this wide to the right of where turtle is facing, including block turtle is on
local sizeY -- Quarry removes this many layers of blocks including layer where turtle starts
local bDebug= false

local goUnload	-- Forward declaration

if (#tArgs == 1) then
	sizeZ,sizeX,sizeY = tonumber(tArgs[1]),tonumber(tArgs[1]),256
elseif (#tArgs == 2) then
	sizeZ,sizeX,sizeY = tonumber(tArgs[1]),tonumber(tArgs[2]),256
elseif (#tArgs >= 3) then
	sizeZ,sizeX,sizeY = tonumber(tArgs[1]),tonumber(tArgs[2]),tonumber(tArgs[3])
	if (#tArgs > 3) then
		bDebug = (tonumber(tArgs[4])==1)
	end
else
	print( "Usage: quarry <sq. size> <optional width > <optional fixed depth> <optional 1 for debug mode>" )
	return
end

-- Validate dimensions
if (sizeX<2 or sizeZ<2 or sizeY<1) then
  print( "Dimensions given must be at least 2L x 2W x 1D. Efficiency is optimal if fixed depth is a multiple of 3." )
  return
end

local minFuel = math.ceil((math.ceil(sizeY/3)*(sizeX*sizeY)+(2*sizeY))/1200)
local maxFuel = "TBD"

print("Place fuel reserves in slot 1 (upper left) if desired and hit any key to start.")
os.pullEvent("key")

local tX,tZ,tY = 0,0,0    -- Place the turtle starts is considered block 0,0,0 in the turtle's local coordinate system
local xDir,zDir = 0,1     -- Turtle is considered as initially facing positive z direction, regardless of global world facing direction
local refuelSlot = 1      -- Turtle can fuel from any slot, but it will never dump this slot's contents so this is where fuel should be placed

-- Notice that all coordinates formated as 0,0,0 are in X,Z,Y order, NOT alphabetical X,Y,Z order, where Y is up/down axis
-- Y axis is always the minecraft world Y-axis, but X and Z in this turtle's local coordinate system won't necessarily match his
-- orientation in the global world system (turtle's system is relative to how he is initially facing, +Z is his facing direction)

local function checkFuel(bMovingAwayFromOrigin)
	if bDebug then print("checkFuel()") end
	-- This function returns true only if there is enough fuel left to move 1 block in any direction, 
	-- and still have enough left over for a return trip to 0,0,0 that might be needed for refuel or at
	-- the end of the quarrying. This ensures the turtle is never stranded in the quarry.
	local fuelLevel = turtle.getFuelLevel()
	
	if (fuelLevel == "unlimited") then
		-- Server has fuel requirement turned off in configs
		return true
	end
	
	-- If the turtle is attempting to move away from its starting location, it is going to
	-- consume the normal 1 fuel cost to move, but it will also add +1 to the cost of the
	-- trip to return home to dump/refuel/finish. If we know the turtle is moving closer to
	-- home, there is no extra cost since it is effectively part of the return trip.
	local fuelNeeded = math.abs(tX)+math.abs(tY)+math.abs(tZ)
	if (bMovingAwayFromOrigin == nil or bMovingAwayFromOrigin == true) then
		-- Turtle is moving away from 0,0,0 or direction is unspecified (assume worst case), add 2 fuel
		fuelNeeded = fuelNeeded + 2
	end
  
	if (fuelLevel >= fuelNeeded) then
		-- Turtle has enough fuel to do the next 1-block movement, plus enough to
		-- return home from there.
		return true
	end
  
	-- If we get here, turtle does not have enough fuel for the move plus a return to base
	-- First we will try to refuel from anything we find in the turtle's inventory. Failing that
	-- We will return to home and prompt the user to add fuel
	
	local slot = 1
	turtle.select(slot)
	
	if bDebug then print("Entering while true do in checkFuel") end
	while true do
		if turtle.refuel(1) then
			-- Found fuel in current slot, consume 1, see if it's enough, if not loop again
			if (turtle.getFuelLevel()>=fuelNeeded) then
				print("Refueled from inventory, resuming quarrying...")
				return true
			end
		else
			-- Couldn't refuel from currently-selected slot, try next slot. If there are no more slots, ask for player help.
			if (slot < 16) then
				slot = slot + 1
				turtle.select(slot)
			else
				-- There are no more slots to look in, reset selection so that we're ready to loop over all slots again, and so that the
				-- player sees slot 1 highlighted (fastest for turtle to find fuel in). Return to 0,0,0 if we can (in case turtle is
				-- under lava or otherwise inaccessible), prompt player to add fuel.

				return goUnload(true)
			end
		end
	end
end

local function turnLeft()
  turtle.turnLeft()
  xDir,zDir = -zDir,xDir
  return true
end

local function turnRight()
  turtle.turnRight()
  xDir,zDir = zDir,-xDir
  return true
end

local function goForward(bCheckFuel)
	if bDebug then print("goForward()") end
	-- Can't move without fuel. checkFuel() will wait on player if necessary.
	if (bCheckFuel==true or bCheckFuel==nil) then
    checkFuel((xDir>0 and tX>=0) or (xDir<0 and tX<=0) or (zDir>0 and tZ>=0) or (zDir<0 and tZ<=0))	-- Passes boolean true if moving away from 0,0,0
  end
  
	local tries = 3
	while not turtle.forward() do
		if bDebug then print("goForward: while not turtle.forward() do tries="..tries) end
		if turtle.detect() then
			if bDebug then print("goForward: detect") end
			if not turtle.dig() then
				print("Undiggable block encountered. Will retry in 5 seconds.")
				-- Turtle is blocked. In case this is a temporary glitch, we try 3 times before conceding hard failure
				tries = tries - 1
				if (tries <= 0) then
				  return false
				else
					if bDebug then print("goForward: sleep(5)") end
					sleep(5) -- Wait 5 seconds, hope the problem resolves itself
				end
			end
		elseif turtle.attack() then
			if bDebug then print("goForward: attack") end
			-- Had to attack player or mob. You can add additional code here such
			-- as turtle.suck() if you want to collect killed mob loot. This is a quarry program
			-- to collect ores, not rotten flesh and bones, so this block is empty.
		else
			-- Unknown obstruction, possibly a player in
			-- peaceful or creative mode. Try again in 0.5 seconds and hope it's gone.
			if bDebug then
				print("goForward: sleep(0.5) else block")
				print("Turtle fuel="..turtle.getFuelLevel())
			end
			sleep(0.5)
		end
	end

	tX = tX + xDir  -- If we're moving in the xDir, this will change tX by + or - 1
	tZ = tZ + zDir  -- If we're moving in the zDir, this will change tZ by + or - 1

	return true -- Turtle moved successfully
end

local function goDown(bCheckFuel)
	if bDebug then print("goDown()") end
	-- Can't move without fuel. checkFuel() will wait on player if necessary.
	if (bCheckFuel==true or bCheckFuel==nil) then
    checkFuel(tY<=0)	-- Passes boolean true if moving away from 0,0,0
  end
  
  local tries = 3
	while not turtle.down() do
		if bDebug then print("goDown: while not turtle.down() do tries="..tries) end
		if turtle.detectDown() then
			if bDebug then print("goDown: detectDown") end
			if not turtle.digDown() then
				print("Undiggable block encountered. Will retry in 5 seconds")
				-- Turtle is blocked. In case this is a temporary glitch, we try 3 times before conceding hard failure
				tries = tries - 1
				if (tries <= 0) then
				  return false
				else
					if bDebug then print("goDown: sleep(5)") end
				  sleep(5) -- Wait 5 seconds, hope the problem resolves itself
				end
			end
		elseif turtle.attackDown() then
			if bDebug then print("goDown: attack") end
			-- Had to attack player or mob. You can add additional code here such
			-- as turtle.suck() if you want to collect killed mob loot. This is a quarry program
			-- to collect ores, not rotten flesh and bones, so this block is empty.
		else
			-- Unknown obstruction, possibly a player in
			-- peaceful or creative mode. Try again in 0.5 seconds and hope it's gone.
			if bDebug then print("goDown: sleep(0.5)") end
			sleep(0.5)
		end
	end

	tY = tY - 1
	return true -- Turtle moved successfully
end

local function goUp(bCheckFuel)
	if bDebug then print("goUp()") end
	
  -- Can't move without fuel. checkFuel() will wait on player if necessary.
  if (bCheckFuel==true or bCheckFuel==nil) then
    checkFuel(tY>=0)	-- Passes boolean true if moving away from 0,0,0
  end
  
  local tries = 3
	while not turtle.up() do
		if bDebug then print("goUp: while not loop tries="..tries) end
		if turtle.detectUp() then
			if bDebug then print("goUp: detectUp") end
			  if not turtle.digUp() then
						print("Undiggable block encountered. Will retry in 5 seconds.")
						-- Turtle is blocked. In case this is a temporary glitch, we try 3 times before conceding hard failure
				tries = tries - 1
				if (tries <= 0) then
				  return false
				else
				  sleep(10) -- Wait 10 seconds, hope the problem resolves itself
				end
			end
		elseif turtle.attackUp() then
			if bDebug then print("goUp: attack") end
			-- Had to attack player or mob. You can add additional code here such
			-- as turtle.suck() if you want to collect killed mob loot. This is a quarry program
			-- to collect ores, not rotten flesh and bones, so this block is empty.
		else
			-- Unknown obstruction, possibly a player in
			-- peaceful or creative mode. Try again in 0.5 seconds and hope it's gone.
			if bDebug then print("goUp: sleep(0.5)") end
			sleep(0.5)
		end
	end

	tY = tY + 1
	return true -- Turtle moved successfully
end

local function orient(targetXdir, targetZdir)
	-- One of the supplied directions should be -1 or +1, the other should be 0.
    if ((targetXdir ~= 0) and (targetZdir ~= 0)) or ((targetXdir==0) and (targetZdir==0)) then
        print("orient() given mutually exclusive values: "..targetXdir..", "..targetZdir)
        return false
    end
    
    if (((targetXdir ~= 0) and (math.abs(targetXdir) ~= 1)) or ((targetZdir ~= 0) and (math.abs(targetZdir) ~= 1))) then
        print("orient() given bad values: "..targetXdir..", "..targetZdir)
        return false
    end
    
    if (targetXdir ~= 0) and (targetXdir ~= xDir) then
        -- x axis alignment requested, and differs from current alignment
        if (xDir ~= 0) then
            -- Turtle is x-axis aligned 180 from target
            turnLeft()
            turnLeft()
        elseif (zDir == targetXdir) then
            turnRight()
        else
            turnLeft()
        end
     elseif (targetZdir ~= 0) and (targetZdir ~= zDir) then
         -- z axis alignment requested, and differs from current alignment
        if (zDir ~= 0) then
            -- Turtle is z-axis aligned 180 from target
            turnLeft()
            turnLeft()
        elseif (xDir == targetZdir) then
            turnLeft()
        else
            turnRight()
        end
    end
    
    return true
end

local function goHome()
  -- This is similar to moveTo(0,0,0) but axis ordering of movement is reversed, so that turtle takes
  -- the same path to and from home location and where it left off. Also, this function passes false to
  -- goDown, goUp and goForward to make them skip the per-move fuel check, because making that check
  -- could result in circular function calling: goHome()->goFoward()->checkFuel()->goHome()->goFoward()->checkFuel().. etc.
  -- This function is set up to move along Y-axis first, then X, then finally Z, unless bReverse is true
  -- Note: The order doesn't matter much when digging out a space, but can matter when building something
  -- so that you don't dig a tunnel through what you're building.
  
  local fuelNeeded = math.abs(tX)+math.abs(tY)+math.abs(tZ)
  if not (turtle.getFuelLevel()>=fuelNeeded) then
    print("Error: Turtle ended up in the unexpected state of not having enough fuel to return home.")
    return false
  end

	while (tY<0) do
		if bDebug then print("goHome while tY<0 tY="..tY) end
		if not goUp(false) then
			-- Critical movement fail, bail
			return false
		end
	end
  
	while (tY>0) do
		if bDebug then print("goHome while tY>0 tY="..tY) end
		if not goDown(false) then
			-- Critical movement fail, bail
			return false
		end
	end

	-- If not at tX==targetX, move the right direction until tX==targetX
	if (tX>0) then orient(-1,0) end
	if (tX<0) then orient(1,0) end
	while (tX~=0) do
		if bDebug then print("goHome while tX~=0 tX="..tX) end
		if not goForward(false) then
		-- Critical movement fail, bail
		return false
		end
	end

	-- If not at tZ==targetZ, move the right direction until tZ==targetZ
	if (tZ>0) then orient(0,-1) end
	if (tZ<0) then orient(0,1) end
	while (tZ~=0) do
		if bDebug then print("goHome while tZ~=0 tZ="..tZ) end
		if not goForward(false) then
			-- Critical movement fail, bail
			return false
		end
	end

	return true
end

local function moveTo(targetX,targetZ,targetY)

	local fuelNeeded = math.abs(tX-targetX)+math.abs(tY-targetY)+math.abs(tZ-targetZ)
  if not (turtle.getFuelLevel()>=fuelNeeded) then
    print("Error: Turtle ended up in the unexpected state of not having enough fuel to return home.")
    return false
  end
  
	-- If not at tZ==targetZ, move the right direction until tZ==targetZ
	if (tZ>targetZ) then orient(0,-1) end
	if (tZ<targetZ) then orient(0,1) end
	while (tZ~=targetZ) do
		if bDebug then print("moveTo while tZ~=targetZ tZ="..tZ.." targetZ="..targetZ) end
		if not goForward(false) then
			-- Critical movement fail, bail
			return false
		end
	end
  
  -- If not at tX==targetX, move the right direction until tX==targetX
	if (tX>targetX) then orient(-1,0) end
	if (tX<targetX) then orient(1,0) end
	while (tX~=targetX) do
		if bDebug then print("moveTo while tX~=targetX tX="..tX.." targetX="..targetX) end
		if not goForward(false) then
			-- Critical movement fail, bail
			return false
		end
	end
  
	while (tY<targetY) do
		if bDebug then print("moveTo while tY<targetY tY="..tY.." targetY="..targetY) end
		if not goUp(false) then
			-- Critical movement fail, bail
			return false
		end
	end
  
	while (tY>targetY) do
		if bDebug then print("moveTo while tY>targetY tY="..tY.." targetY="..targetY) end
		if not goDown(false) then
			-- Critical movement fail, bail
			return false
		end
	end
  
  return true
end

function goUnload(bNeedsFuel)
	if bDebug then print("goUnload()") end
	-- Save position and orientation
	local saveX = tX
	local saveZ = tZ
	local saveY = tY
	local saveXdir = xDir
	local saveZdir = zDir
	
	if not goHome() then
	-- Critical failure to move
		return false
	end
	
	orient(0,-1)
	
	-- Drop items. Turtle will not empty the slot designated as the refuel slot.
	for i=1,16 do
		if (i ~= refuelSlot) then
		  turtle.select(i)
		  turtle.drop()
		end
	end
	
	orient(0,1)
	
	-- Select first empty slot, might be a now-empty fuel slot, we don't really care
	for i=1,16 do
		if (turtle.getItemCount(i)==0) then
		  turtle.select(i)
		  break
		end
	end
	
	
	-- Since we had to bring the turtle all the way home, calculate
	-- the fuel needed to get back to where turtle left off mining, do at least one
	-- full layer's worth of work, plus approximately enough to get back home again. It would be
	-- silly to leave base with anything less than that, since the fuel would go nearly all to moving
	-- the turtle through already-mined space doing no work...
	local fuelNeeded = 2 * (math.abs(tX-saveX) + math.abs(tY-saveY) + math.abs(tZ-saveZ)) + (sizeX * sizeZ)
	
	while (turtle.getFuelLevel() < fuelNeeded) do
		
		if bDebug then print("Entering while true do in goUnload fuel check stage") end
		
		-- Scan inventory for fuel
		local slot = 1
		turtle.select(slot)
		local bRefueled = false
		
		while true do
			if turtle.refuel(1) then
				-- Found fuel in current slot, consume 1, see if it's enough, if not loop again
				print("Consuming fuel item from slot "..slot)
				if (turtle.getFuelLevel()>=fuelNeeded) then
					print("Refueled from inventory, resuming quarrying...")
					bRefueled = true
					break
				end
			else
				-- Couldn't refuel from currently-selected slot, try next slot. If there are no more slots, ask for player help.
				if (slot < 16) then
					slot = slot + 1
					turtle.select(slot)
				else
					-- There are no more slots to look in, reset selection so that we're ready to loop over all slots again, and so that the
					slot = 1
					break
				end
			end
		end
		
		if not bRefueled then
			turtle.select(1)
			print("Please add more fuel items to the turtle and press any key. Has:"..turtle.getFuelLevel().." Needs:"..fuelNeeded)
			os.pullEvent("key")    -- suspend code execution awaiting user keypress
		end
	end
	
	if not moveTo(saveX,saveZ,saveY) then
		-- Critical failure to move
		return false
	end
	
	orient(saveXdir,saveZdir)
	
	return true
end

local function checkFreeSlot()
  -- This function will return true if the designated refuelSlot is empty, because if there is no fuel reserve there, there
  -- is no reason not to allow item collection into this slot.
	for i=1,16 do
		if turtle.getItemCount(i)==0 then
		  return true
		end
	end
  
  -- Turtle does not have empty slot, goUnload
	if not goUnload() then
		return false
	end
  
	return true
end

--[[

  START OF THE MAIN PROGRAM
  
--]]

checkFreeSlot()

local abort = false
local traversal = 1 -- Counts x-z layers we're rasterizing. Used to determine turning directions at end of columns and layers
local lowestY = 1-sizeY
local bDigBelow, bDigAbove = false, false -- initially false
while true do -- This loops digging layers
  print("Main loop traversal="..traversal.." tY="..tY.." lowestY="..lowestY)
  
  if (traversal==1) then --special case since turtle initially starts NOT on a layer that it just dug out.
	if ((tY - lowestY) == 0) then
		bDigBelow, bDigAbove = false, false
	elseif ((tY - lowestY) == 1) then
		bDigBelow, bDigAbove = true, false
	elseif ((tY - lowestY) >= 2) then
		bDigBelow, bDigAbove = true, true
		if not goDown() then
          -- Turtle can't dig down, adjust lowestY because we can't go as deep as planned
		  lowestY = tY - 1
		end
	else
		-- Error: turtle is not in an expected place
		print("Error: Turtle vertical position is not what we expect on 1st traversal. Aborting, please debug.")
		abort = true
		break
	end
  else
	-- Not our first traversal, and turtle should now be on the last layer it dug out.
	if ((tY - lowestY) == 1) then
		bDigBelow, bDigAbove = true, false
	elseif ((tY - lowestY) == 2) then
		bDigBelow, bDigAbove = true, false
		if not goDown() then
          -- Turtle can't go down, adjust lowestY because we can't go as deep as planned
		  lowestY = tY - 1
		end
	elseif ((tY - lowestY) >= 3) then
		bDigBelow, bDigAbove = true, true
		-- Try to descend 2, if either fails, adjust lowestY to just below where turtle is able to get to, and
		-- cancel the need to digAbove
		for j=1,2 do
			if not goDown() then
			  -- Turtle can't dig down, adjust lowestY because we can't go as deep as planned
			  lowestY = tY - 1
			  bDigAbove = false
			end
		end
	else
		-- Error: turtle is not in an expected place
		print("Error: Turtle vertical position is not what we expect on traversal>1. Aborting, please debug.")
		abort = true
		break
	end
  end
  
  
  
  for column=1,sizeX  do  -- This loops sizeX times digging out columns
    for block=1,(sizeZ-1) do -- this loops (sizeZ-1) times doing digDown and goForward to do all but the end of each column
      
      -- Since we're about to do a potentially ore-digging move, check for free space in inventory.
      -- hasFreeSlot() calls goUnload if necessary
      if not checkFreeSlot() then
        print("Error: checkFreeSlot failure.")
        abort = true
        break
      end
      
      if bDigBelow and turtle.detectDown() then
        if not turtle.digDown() then
          -- Turtle can't dig down, but we're not moving down so this is not a fatal error.
          -- It might be bedrock below turtle, but that's not a concern until turtle is level with it.
        end
      end
      
      if bDigAbove and turtle.detectUp() then
        if not turtle.digUp() then
          -- Turtle can't dig up. This is actually concerning since we don't want to get him trapped under bedrock.
          -- Because of the danger of entrapment, we're ending our quarrying here.
          print("Turtle below undiggable block, backing out and returning home.")
          turnRight()
          turnRight()
          if not goForward() then
            -- This failure we care about, because there is something blocking us that we
            -- can't dig, attack or otherwise resolve. Bust out of our digging loops and attempt to return home
            print("Fatal Error during column goForward tX="..tX.." tZ="..tZ.." tY="..tY)
          end
		  abort = true
          break
        end
		sleep(0.5) -- wait to see if anything falls on turtle from above (sand, gravel)
		
		-- First dig up was successful, so we haven't got an undiggable block above, and undiggables can't fall, so we can
		-- safely loop trying to dig up as long as something is falling on us (gravel, sand)
		while turtle.detectUp() do
			if bDebug then print("in while turtrle.detectUp() loop.") end
			if not turtle.digUp() then
				-- whatever is up there, we couldn't dig it, but it's not bedrock. Just move on...
				break
			end
			sleep(0.5)
		end
      end
      
      if not goForward() then
        -- This failure we care about, because there is something blocking us that we
        -- can't dig, attack or otherwise resolve. Bust out of our digging loops and attempt to return home
        -- after first checking to be sure the turtle is not under bedrock (if digging above)
        print("Fatal Error during column goForward tX="..tX.." tZ="..tZ.." tY="..tY)
        abort = true
        break
      end
    end -- end of block loop
    
    -- If movement failed while traversing column, escape out, backing out from under bedrock if needed
    if abort then
      if bDigAbove and turtle.detectUp() then
      	if not turtle.digUp() then
          -- Turtle can't dig up. This is actually concerning since we don't want to get him trapped under bedrock.
          -- Because of the danger of entrapment, we're ending our quarrying here.
          print("Turtle below undiggable block, backing out and returning home.")
          turnRight()
          turnRight()
          if not goForward() then
            -- This failure we care about, because there is something blocking us that we
            -- can't dig, attack or otherwise resolve. Bust out of our digging loops and attempt to return home
            print("Fatal Error during column goForward tX="..tX.." tZ="..tZ.." tY="..tY)
          end
        end
      end
    
      -- unwinding
      break
    end
    
    -- Dig out the last block of this column
    if bDigBelow and turtle.detectDown() then
      if not turtle.digDown() then
        -- Turtle can't dig down, but we're not moving down so this is not a fatal error.
        -- It might be bedrock below turtle, but that's not a concern until turtle is level with it.
      end
    end
    
    -- Do last digUp in this column, if required by bDigAbove
    if bDigAbove and turtle.detectUp() then
        if not turtle.digUp() then
          -- Turtle can't dig up. This is actually concerning since we don't want to get him trapped under bedrock.
          -- Because of the danger of entrapment, we're ending our quarrying here.
          print("Turtle below undiggable block, backing out and returning home.")
          turnRight()
          turnRight()
          if not goForward() then
            -- This failure we care about, because there is something blocking us that we
            -- can't dig, attack or otherwise resolve. Bust out of our digging loops and attempt to return home
            print("Fatal Error during column goForward tX="..tX.." tZ="..tZ.." tY="..tY)
          end
		  abort = true
          break
        end
		sleep(0.5) -- wait to see if anything falls on turtle from above (sand, gravel)
		
		-- First dig up was successful, so we haven't got an undiggable block above, and undiggables can't fall, so we can
		-- safely loop trying to dig up as long as something is falling on us (gravel, sand)
		while turtle.detectUp() do
			if bDebug then print("in while turtrle.detectUp() loop.") end
			if not turtle.digUp() then
				-- whatever is up there, we couldn't dig it, but it's not bedrock. Just move on...
				break
			end
			sleep(0.5)
		end
    end
    
    -- Turtle just finished the column, figure out if we need to advance to a new column, or
    -- if we've finished the layer. If we need to turn to start a new column, we have to figure out which
    -- direction to turn
    if (column<sizeX) then
      -- Turtle is at the end of a z column, but not the end of the whole x-z layer traversal
      
      -- FYI: These odd/even values are based on 1-based block, column, traversal numbers not 0-based tX, tZ, tY
      -- sorry if that's confusing, but Lua convention is to start loop indicies at 1
      local evenCol = ((column%2)==0)
      local evenWidth = ((sizeX%2)==0)
      local evenLayer = ((traversal%2)==0)
      local backtrackingLayer = (evenWidth and evenLayer)
      
      if ((not evenCol and not backtrackingLayer) or (evenCol and backtrackingLayer)) then
        turnRight() -- turn towards next row
        if not goForward() then
          print("Fatal Error during goForward from column "..column.." to column "..(column+1).." tX="..tX.." tZ="..tZ.." tY="..tY)
          abort = true
          break
        end
        
        -- Danger check to see if we've moved under an undiggable block
        if bDigAbove and turtle.detectUp() and not turtle.digUp() then
          print("Turtle below undiggable block, backing out 1 and returning home.")
          turnRight()
          turnRight()
          if not goForward() then
            -- This failure we care about, because there is something blocking us that we
            -- can't dig, attack or otherwise resolve. Bust out of our digging loops and attempt to return home
            print("Fatal Error during column goForward tX="..tX.." tZ="..tZ.." tY="..tY)
          end
          abort = true
          break
        end
        
        turnRight()
      else
        turnLeft()
        if not goForward() then
          print("Fatal Error during goForward from column "..column.." to column "..(column+1).." tX="..tX.." tZ="..tZ.." tY="..tY)
          abort = true
          break
        end
        
        -- Danger check to see if we've moved under an undiggable block
        if bDigAbove and turtle.detectUp() and not turtle.digUp() then
          print("Turtle below undiggable block, backing out 1 and returning home.")
          turnRight()
          turnRight()
          if not goForward() then
            -- This failure we care about, because there is something blocking us that we
            -- can't dig, attack or otherwise resolve. Bust out of our digging loops and attempt to return home
            print("Fatal Error during column goForward tX="..tX.." tZ="..tZ.." tY="..tY)
          end
          abort = true
          break
        end
        
        turnLeft()
      end
      -- Turtle is now ready to start the next column
    else
      -- Turtle is at the end of the layer, rotate 180
      turnRight()
      turnRight()
    end
  end -- end of column loop
  
  if abort then
	print("Abort breaking out of while true loop.")
    -- abort in progress, unwinding out of loops
    break
  end
  
  -- See if we're done yet
  if ((tY - lowestY) == 0) or (((tY - lowestY) == 1) and (bDigBelow == true)) then
    -- We're done. We've finished digging our lowest layer either by digging forward or with digDown.
    done = true
    break
  end
  
  -- If we got past the last if-then, we are not done, so we need to descend in preparation for next layer traversal
  if bDigBelow then
    -- We were digging below us on the traversal we just finished, so we need to drop down 2 levels to be on an undug layer
    -- First we try to descend through the dug-down layer, but since that could have bedrock (we we skimming above it not caring)
    -- we need to test to see if we can descend into that layer at our current tX,tZ location
    if not goDown() then
      print("Turtle finished a traversal and was digging below. Turtle can't go further down, we're done quarrying.")
      abort = true
      break
    end
  end
  
  traversal = traversal + 1
end -- end of while not done loop

-- Quarrying ended, either normally or because of encountering undiggable block. Try to return to 0,0,0
if not goHome(0,0,0) then
  -- Can't even get back home :-( Notify the user
  print("Turtle was not able to safely get back to starting location")
  abort = true
else
	orient(0,-1)
  
	-- Drop everything
	-- Drop items. Turtle will not empty the slot designated as the refuel slot.
  print("Unloading all contents...")
	for i=1,16 do
		turtle.select(i)
		turtle.drop()
	end
	orient(0,1)
end

if abort then
  print("Quarrying ended due to encounter with undiggable block.")
else
  print("Quarrying complete to desired depth.")
end