-- ********************************************************************************** --
-- **                                                                              ** --
-- **   Minecraft Mining Turtle Ore Quarry v0.7 by AustinKK                        ** --
-- **   ---------------------------------------------------                        ** -- 
-- **                                                                              ** --
-- **   For instructions on how to use:                                            ** --
-- **                                                                              ** --
-- **     http://www.youtube.com/watch?v=PIugLVzUz3g                               ** --
-- **                                                                              ** --
-- **  Change Log:                                                                 ** --
-- **    27th Dec 2012: [v0.2] Initial Draft Release                               ** --
-- **    29th Dec 2012: [v0.3] Minor Performance Improvements                      ** --
-- **    30th Dec 2012: [v0.4] Further Performance Improvements                    ** --
-- **    9th  Jan 2013: [v0.5] Debug Version (dropping off chest)                  ** --
-- **    10th Jan 2013: [v0.51] Further Debug (dropping off chest)                 ** --
-- **    10th Jan 2013: [v0.52] Fix for dropping off chest bug                     ** --
-- **    11th Jan 2013: [v0.53] Fix for dropping off chest bug (release)           ** --
-- **    12th Jan 2013: [v0.6] Added support for resume                            ** --
-- **    31st Mar 2013: [v0.7] Fixes for ComputerCraft v1.52                       ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Enumeration to store the the different types of message that can be written
messageLevel = { DEBUG=0, INFO=1, WARNING=2, ERROR=3, FATAL=4 }
 
-- Enumeration to store names for the 6 directions
direction = { FORWARD=0, RIGHT=1, BACK=2, LEFT=3, UP=4, DOWN=5 }
 
-- Enumeration of mining states
miningState = { START=0, LAYER=1, EMPTYCHESTDOWN=2, EMPTYINVENTORY=3 }
 
local messageOutputLevel = messageLevel.INFO
local messageOutputFileName
local fuelLevelToRefuelAt = 5
local refuelItemsToUseWhenRefuelling = 63
local emergencyFuelToRetain = 0
local maximumGravelStackSupported = 25 -- The number of stacked gravel or sand blocks supported
local noiseBlocksCount
local bottomLayer = 5 -- The y co-ords of the layer immediately above bedrock
local returningToStart = false
local lookForChests = false -- Determines if chests should be located as part of the quarrying
local miningOffset -- The offset to the mining layer. This is set depending on whether chests are being looked for or not
local lastEmptySlot -- The last inventory slot that was empty when the program started (is either 15 if not looking for chests or 14 if we are)
local turtleId
local isWirelessTurtle
local currentlySelectedSlot = 0 -- The slot that the last noise block was found in
local lastMoveNeededDig = true -- Determines whether the last move needed a dig first
local haveBeenAtZeroZeroOnLayer -- Determines whether the turtle has been at (0, 0) in this mining layer
local orientationAtZeroZero -- The turtle's orientation when it was at (0, 0)
local levelToReturnTo -- The level that the turtle should return to in order to head back to the start to unload

-- Variables used to support a resume
local startupParamsFile = "OreQuarryParams.txt"
local oreQuarryLocation = "OreQuarryLocation.txt"
local returnToStartFile = "OreQuarryReturn.txt"
local startupBackup = "startup_bak"
local supportResume = true -- Determines whether the turtle is being run in the mode that supports resume
local resuming = false -- Determines whether the turtle is currently in the process of resuming
local resumeX
local resumeY
local resumeZ
local resumeOrient
local resumeMiningState

-- Variables to store the current location and orientation of the turtle. x is right, left, y is up, down and
-- z is forward, back with relation to the starting orientation. Y is the actual turtle level, x and z are
-- in relation to the starting point (i.e. the starting point is (0, 0))
local currX
local currY
local currZ
local currOrient
local currMiningState = miningState.START
 
-- Command line parameters
local startHeight -- Represents the height (y co-ord) that the turtle started at
local quarryWidth -- Represents the length of the mines that the turtle will dig
 
-- ********************************************************************************** --
-- Writes an output message
-- ********************************************************************************** --
function writeMessage(message, msgLevel)
  if (msgLevel >= messageOutputLevel) then
    print(message)

    -- If this turtle has a modem, then write the message to red net
    if (isWirelessTurtle == true) then
      if (turtleId == nil) then
        rednet.broadcast(message)
      else
        -- Broadcast the message (prefixed with the turtle's id)
        rednet.broadcast("[".. turtleId.."] "..message)
      end
    end

    if (messageOutputFileName ~= nil) then
      -- Open file, write message and close file (flush doesn't seem to work!)
      local outputFile = io.open(messageOutputFileName, "a")
      outputFile:write(message)
      outputFile:write("\n")
      outputFile:close()
    end
  end
end
 
-- ********************************************************************************** --
-- Ensures that the turtle has fuel
-- ********************************************************************************** --
function ensureFuel()
 
  -- Determine whether a refuel is required
  local fuelLevel = turtle.getFuelLevel()
  if (fuelLevel ~= "unlimited") then
    if (fuelLevel < fuelLevelToRefuelAt) then
      -- Need to refuel
      turtle.select(16)
      currentlySelectedSlot = 16
      local fuelItems = turtle.getItemCount(16)
 
      -- Do we need to impact the emergency fuel to continue? (always  
      -- keep one fuel item in slot 16)
      if (fuelItems == 0) then
        writeMessage("Completely out of fuel!", messageLevel.FATAL)
      elseif (fuelItems == 1) then
        writeMessage("Out of Fuel!", messageLevel.ERROR)
        turtle.refuel()
      elseif (fuelItems <= (emergencyFuelToRetain + 1)) then
        writeMessage("Consuming emergency fuel supply. "..(fuelItems - 2).." emergency fuel items remain", messageLevel.WARNING)
        turtle.refuel(1)
      else
        -- Refuel the lesser of the refuelItemsToUseWhenRefuelling and the number of items more than
        -- the emergency fuel level
        if (fuelItems - (emergencyFuelToRetain + 1) < refuelItemsToUseWhenRefuelling) then
          turtle.refuel(fuelItems - (emergencyFuelToRetain + 1))
        else
          turtle.refuel(refuelItemsToUseWhenRefuelling)
        end
      end
    end
  end
end        
 
-- ********************************************************************************** --
-- Checks that the turtle has inventory space by checking for spare slots and returning
-- to the starting point to empty out if it doesn't.
--
-- Takes the position required to move to in order to empty the turtle's inventory
-- should it be full as arguments
-- ********************************************************************************** --
function ensureInventorySpace()
 
  -- If already returning to start, then don't need to do anything
  if (returningToStart == false) then
 
    -- If the last inventory slot is full, then need to return to the start and empty
    if (turtle.getItemCount(lastEmptySlot) > 0) then
 
      -- Return to the starting point and empty the inventory, then go back to mining
      returnToStartAndUnload(true)
    end
  end
end
 
-- ********************************************************************************** --
-- Function to move to the starting point, call a function that is passed in
-- and return to the same location (if required)
-- ********************************************************************************** --
function returnToStartAndUnload(returnBackToMiningPoint)
 
  writeMessage("returnToStartAndUnload called", messageLevel.DEBUG)
  returningToStart = true
  local storedX, storedY, storedZ, storedOrient
  local prevMiningState = currMiningState

  if (resuming == true) then
    -- Get the stored parameters from the necessary file
    local resumeFile = fs.open(returnToStartFile, "r")
    if (resumeFile ~= nil) then
      -- Restore the parameters from the file
      local beenAtZero = resumeFile.readLine()
      if (beenAtZero == "y") then
        haveBeenAtZeroZeroOnLayer = true
      else
        haveBeenAtZeroZeroOnLayer = false
      end

      local miningPointFlag = resumeFile.readLine()
      if (miningPointFlag == "y") then
        returnBackToMiningPoint = true
      else
        returnBackToMiningPoint = false
      end

      currX = readNumber(resumeFile)
      currY = readNumber(resumeFile)
      currZ = readNumber(resumeFile)
      currOrient = readNumber(resumeFile)
      levelToReturnTo = readNumber(resumeFile)
      prevMiningState = readNumber(resumeFile)
      orientationAtZeroZero = readNumber(resumeFile)
      resumeFile.close()

    else
      writeMessage("Failed to read return to start file", messageLevel.ERROR)
    end
  elseif (supportResume == true) then

    local outputFile = io.open(returnToStartFile, "w")

    if (haveBeenAtZeroZeroOnLayer == true) then
      outputFile:write("y\n")
    else
      outputFile:write("n\n")
    end
    if (returnBackToMiningPoint == true) then
      outputFile:write("y\n")
    else
      outputFile:write("n\n")
    end

    outputFile:write(currX)
    outputFile:write("\n")
    outputFile:write(currY)
    outputFile:write("\n")
    outputFile:write(currZ)
    outputFile:write("\n")
    outputFile:write(currOrient)
    outputFile:write("\n")
    outputFile:write(levelToReturnTo)
    outputFile:write("\n")
    outputFile:write(prevMiningState)
    outputFile:write("\n")
    outputFile:write(orientationAtZeroZero)
    outputFile:write("\n")

    outputFile:close()
  end
    
  storedX = currX
  storedY = currY
  storedZ = currZ
  storedOrient = currOrient
 
  -- Store the current location and orientation so that it can be returned to
  currMiningState = miningState.EMPTYINVENTORY
  writeMessage("last item count = "..turtle.getItemCount(lastEmptySlot), messageLevel.DEBUG)

  if ((turtle.getItemCount(lastEmptySlot) > 0) or (returnBackToMiningPoint == false)) then

    writeMessage("Heading back to surface", messageLevel.DEBUG)

    -- Move down to the correct layer to return via
    if (currY > levelToReturnTo) then
      while (currY > levelToReturnTo) do
        turtleDown()
      end
    elseif (currY < levelToReturnTo) then 
      while (currY < levelToReturnTo) do
        turtleUp()
      end
    end
 
    if ((haveBeenAtZeroZeroOnLayer == false) or (orientationAtZeroZero == direction.FORWARD)) then
      -- Move back to the correct X position first
      if (currX > 0) then
        turtleSetOrientation(direction.LEFT)
        while (currX > 0) do
          turtleForward()
        end
      elseif (currX < 0) then
        -- This should never happen
        writeMessage("Current x is less than 0 in returnToStartAndUnload", messageLevel.ERROR)
      end
 
      -- Then move back to the correct Z position
      if (currZ > 0) then
        turtleSetOrientation(direction.BACK)
        while (currZ > 0) do
          turtleForward()
        end
      elseif (currZ < 0) then
        -- This should never happen
        writeMessage("Current z is less than 0 in returnToStartAndUnload", messageLevel.ERROR)
      end
    else
      -- Move back to the correct Z position first
      if (currZ > 0) then
        turtleSetOrientation(direction.BACK)
        while (currZ > 0) do
          turtleForward()
        end
      elseif (currZ < 0) then
        -- This should never happen
        writeMessage("Current z is less than 0 in returnToStartAndUnload", messageLevel.ERROR)
      end

      -- Then move back to the correct X position
      if (currX > 0) then
        turtleSetOrientation(direction.LEFT)
        while (currX > 0) do
          turtleForward()
        end
      elseif (currX < 0) then
        -- This should never happen
        writeMessage("Current x is less than 0 in returnToStartAndUnload", messageLevel.ERROR)
      end
    end
 
    -- Return to the starting layer
    if (currY < startHeight) then
      while (currY < startHeight) do
        turtleUp()
      end
    elseif (currY > startHeight) then
      -- This should never happen
      writeMessage("Current height is greater than start height in returnToStartAndUnload", messageLevel.ERROR)
    end
 
    -- Empty the inventory
    local slotLoop = 1
 
    -- Face the chest
    turtleSetOrientation(direction.BACK)
 
    -- Loop over each of the slots (except the 16th one which stores fuel)
    while (slotLoop < 16) do
      -- If this is one of the slots that contains a noise block, empty all blocks except
      -- one
      turtle.select(slotLoop) -- Don't bother updating selected slot variable as it will set later in this function
      if ((slotLoop <= noiseBlocksCount) or ((slotLoop == 15) and (lastEmptySlot == 14))) then
        writeMessage("Dropping (n-1) from slot "..slotLoop.." ["..turtle.getItemCount(slotLoop).."]", messageLevel.DEBUG)  
        if (turtle.getItemCount(slotLoop) > 0) then
          turtle.drop(turtle.getItemCount(slotLoop) - 1)
        end
      else
        -- Not a noise block, drop all of the items in this slot
        writeMessage("Dropping (all) from slot "..slotLoop.." ["..turtle.getItemCount(slotLoop).."]", messageLevel.DEBUG)  
        if (turtle.getItemCount(slotLoop) > 0) then
          turtle.drop()
        end
      end
     
      slotLoop = slotLoop + 1
    end

    -- While we are here, refill the fuel items if there is capacity
    if (turtle.getItemCount(16) < 64) then
      turtleSetOrientation(direction.LEFT)
      turtle.select(16) -- Don't bother updating selected slot variable as it will set later in this function
      local currFuelItems = turtle.getItemCount(16)
      turtle.suck()
      while ((currFuelItems ~= turtle.getItemCount(16)) and (turtle.getItemCount(16) < 64)) do
        currFuelItems = turtle.getItemCount(16)
        turtle.suck()
      end
 
      slotLoop = noiseBlocksCount + 1
      -- Have now picked up all the items that we can. If we have also picked up some
      -- additional fuel in some of the other slots, then drop it again
      while (slotLoop <= lastEmptySlot) do
        -- Drop any items found in this slot
        if (turtle.getItemCount(slotLoop) > 0) then 
          turtle.select(slotLoop) -- Don't bother updating selected slot variable as it will set later in this function
          turtle.drop()
        end
        slotLoop = slotLoop + 1
      end
    end

    -- Select the 1st slot because sometimes when leaving the 15th or 16th slots selected it can result
    -- in that slot being immediately filled (resulting in the turtle returning to base again too soon)
    turtle.select(1)
    currentlySelectedSlot = 1
  end 

  -- If required, move back to the point that we were mining at before returning to the start
  if (returnBackToMiningPoint == true) then

    -- If resuming, refresh the starting point to be the top of the return shaft
    if (resuming == true) then
      currX = 0
      currY = startHeight
      currZ = 0
      currOrient = resumeOrient
    end

    -- Return back to the required layer
    while (currY > levelToReturnTo) do
      turtleDown()
    end

    if ((haveBeenAtZeroZeroOnLayer == false) or (orientationAtZeroZero == direction.FORWARD)) then
      -- Move back to the correct Z position first
      writeMessage("Stored Z: "..storedZ..", currZ: "..currZ, messageLevel.DEBUG)
      if (storedZ > currZ) then
        writeMessage("Orienting forward", messageLevel.DEBUG)
        writeMessage("Moving in z direction", messageLevel.DEBUG)
        turtleSetOrientation(direction.FORWARD)
        while (storedZ > currZ) do
          turtleForward()
        end
      elseif (storedZ < currZ) then
        -- This should never happen
        writeMessage("Stored z is less than current z in returnToStartAndUnload", messageLevel.ERROR)
      end

      -- Then move back to the correct X position
      if (storedX > currX) then
        writeMessage("Stored X: "..storedX..", currX: "..currX, messageLevel.DEBUG)
        writeMessage("Orienting right", messageLevel.DEBUG)
        writeMessage("Moving in x direction", messageLevel.DEBUG)
        turtleSetOrientation(direction.RIGHT)
        while (storedX > currX) do
          turtleForward()
        end
      elseif (storedX < currX) then
        -- This should never happen
        writeMessage("Stored x is less than current x in returnToStartAndUnload", messageLevel.ERROR)
      end
    else 
      -- Move back to the correct X position first
      if (storedX > currX) then
        writeMessage("Stored X: "..storedX..", currX: "..currX, messageLevel.DEBUG)
        writeMessage("Orienting right", messageLevel.DEBUG)
        writeMessage("Moving in x direction", messageLevel.DEBUG)
        turtleSetOrientation(direction.RIGHT)
        while (storedX > currX) do
          turtleForward()
        end
      elseif (storedX < currX) then
        -- This should never happen
        writeMessage("Stored x is less than current x in returnToStartAndUnload", messageLevel.ERROR)
      end
 
      -- Then move back to the correct Z position
      writeMessage("Stored Z: "..storedZ..", currZ: "..currZ, messageLevel.DEBUG)
      if (storedZ > currZ) then
        writeMessage("Orienting forward", messageLevel.DEBUG)
        writeMessage("Moving in z direction", messageLevel.DEBUG)
        turtleSetOrientation(direction.FORWARD)
        while (storedZ > currZ) do
          turtleForward()
        end
      elseif (storedZ < currZ) then
        -- This should never happen
        writeMessage("Stored z is less than current z in returnToStartAndUnload", messageLevel.ERROR)
      end
    end
 
    -- Move back to the correct layer
    if (storedY < currY) then
      while (storedY < currY) do
        turtleDown()
      end
    elseif (storedY > currY) then 
      while (storedY > currY) do
        turtleUp()
      end
    end
 
    -- Finally, set the correct orientation
    turtleSetOrientation(storedOrient)
 
    writeMessage("Have returned to the mining point", messageLevel.DEBUG)
  end

  -- Store the current location and orientation so that it can be returned to
  currMiningState = prevMiningState
 
  returningToStart = false
 
end
 
-- ********************************************************************************** --
-- Empties a chest's contents
-- ********************************************************************************** --
function emptyChest(suckFn)
 
  local prevInventoryCount = {}
  local inventoryLoop
  local chestEmptied = false
 
  -- Record the number of items in each of the inventory slots
  for inventoryLoop = 1, 16 do
    prevInventoryCount[inventoryLoop] = turtle.getItemCount(inventoryLoop)
  end
 
  while (chestEmptied == false) do
    -- Pick up the next item
    suckFn()
 
    -- Determine the number of items in each of the inventory slots now
    local newInventoryCount = {}
    for inventoryLoop = 1, 16 do
      newInventoryCount[inventoryLoop] = turtle.getItemCount(inventoryLoop)
    end
 
    -- Now, determine whether there have been any items taken from the chest
    local foundDifferentItemCount = false
    inventoryLoop = 1
    while ((foundDifferentItemCount == false) and (inventoryLoop <= 16)) do
      if (prevInventoryCount[inventoryLoop] ~= newInventoryCount[inventoryLoop]) then
        foundDifferentItemCount = true
      else
        inventoryLoop = inventoryLoop + 1
      end
    end
   
    -- If no items have been found with a different item count, then the chest has been emptied
    chestEmptied = not foundDifferentItemCount
 
    if (chestEmptied == false) then
      prevInventoryCount = newInventoryCount
      -- Check that there is sufficient inventory space as may have picked up a block
      ensureInventorySpace()
    end
  end
 
  writeMessage("Finished emptying chest", messageLevel.DEBUG)
end

-- ********************************************************************************** --
-- Write the current location to a file
-- ********************************************************************************** --
function saveLocation()

  -- Write the x, y, z and orientation to the file
  if ((supportResume == true) and (resuming == false)) then
    local outputFile = io.open(oreQuarryLocation, "w")
    outputFile:write(currMiningState)
    outputFile:write("\n")
    outputFile:write(currX)
    outputFile:write("\n")
    outputFile:write(currY)
    outputFile:write("\n")
    outputFile:write(currZ)
    outputFile:write("\n")
    outputFile:write(currOrient)
    outputFile:write("\n")
    outputFile:close()
  end

end

-- ********************************************************************************** --
-- If the turtle is resuming and the current co-ordinates, orientation and 
-- mining state have been matched, then no longer resuming
-- ********************************************************************************** --
function updateResumingFlag()
  
  if (resuming == true) then
    if ((resumeMiningState == currMiningState) and (resumeX == currX) and (resumeY == currY) and (resumeZ == currZ) and (resumeOrient == currOrient)) then
      resuming = false
    end
  end

end
 
-- ********************************************************************************** --
-- Generic function to move the Turtle (pushing through any gravel or other
-- things such as mobs that might get in the way).
--
-- The only thing that should stop the turtle moving is bedrock. Where this is
-- found, the function will return after 15 seconds returning false
-- ********************************************************************************** --
function moveTurtle(moveFn, detectFn, digFn, attackFn, compareFn, suckFn, maxDigCount, newX, newY, newZ)
 
  local moveSuccess = false

  -- If we are resuming, then don't do anything in this function other than updating the
  -- co-ordinates as if the turtle had moved
  if (resuming == true) then
    -- Set the move success to true (but don't move) - unless this is below bedrock level
    -- in which case return false
    if (currY <= 0) then
      moveSuccess = false
    else
      moveSuccess = true
    end

    -- Update the co-ordinates to reflect the movement
    currX = newX
    currY = newY
    currZ = newZ

  else
    local prevX, prevY, prevZ
    prevX = currX
    prevY = currY
    prevZ = currZ

    ensureFuel()
 
    -- Flag to determine whether digging has been tried yet. If it has
    -- then pause briefly before digging again to allow sand or gravel to
    -- drop
    local digCount = 0

    if (lastMoveNeededDig == false) then
      -- Didn't need to dig last time the turtle moved, so try moving first

      currX = newX
      currY = newY
      currZ = newZ
      saveLocation()

      moveSuccess = moveFn()

      -- If move failed, update the co-ords back to the previous co-ords
      if (moveSuccess == false) then
        currX = prevX
        currY = prevY
        currZ = prevZ
        saveLocation()
      end

      -- Don't need to set the last move needed dig. It is already false, if 
      -- move success is now true, then it won't be changed
    else    
      -- If we are looking for chests, then check that this isn't a chest before trying to dig it
      if (lookForChests == true) then
        if (isNoiseBlock(compareFn) == false) then
          if (detectFn() == true) then
            -- Determine if it is a chest before digging it
            if (isChestBlock(compareFn) == true) then
              -- Have found a chest, empty it before continuing
              emptyChest (suckFn)
            end
          end
        end
      end
 
      -- Try to dig (without doing a detect as it is quicker)
      local digSuccess = digFn()
      if (digSuccess == true) then
        digCount = 1
      end

      currX = newX
      currY = newY
      currZ = newZ
      saveLocation()

      moveSuccess = moveFn()

      if (moveSuccess == true) then
        lastMoveNeededDig = digSuccess
      else
        currX = prevX
        currY = prevY
        currZ = prevZ
        saveLocation()
      end

    end
 
    -- Loop until we've successfully moved
    if (moveSuccess == false) then
      while ((moveSuccess == false) and (digCount < maxDigCount)) do
 
        -- If there is a block in front, dig it
        if (detectFn() == true) then
       
            -- If we've already tried digging, then pause before digging again to let
            -- any sand or gravel drop, otherwise check for a chest before digging
            if(digCount == 0) then
              -- Am about to dig a block - check that it is not a chest if necessary
              -- If we are looking for chests, then check that this isn't a chest before moving
              if (lookForChests == true) then
                if (isNoiseBlock(compareFn) == false) then
                  if (detectFn() == true) then
                    -- Determine if it is a chest before digging it
                    if (isChestBlock(compareFn) == true) then
                      -- Have found a chest, empty it before continuing
                      emptyChest (suckFn)
                    end
                  end
                end
              end
            else
              sleep(0.1)
            end
 
            digFn()
            digCount = digCount + 1
        else
           -- Am being stopped from moving by a mob, attack it
           attackFn()
        end
 
        currX = newX
        currY = newY
        currZ = newZ
        saveLocation()

        -- Try the move again
        moveSuccess = moveFn()

        if (moveSuccess == false) then
          currX = prevX
          currY = prevY
          currZ = prevZ
          saveLocation()
        end
      end

      if (digCount == 0) then
        lastMoveNeededDig = false
      else
        lastMoveNeededDig = true
      end
    end
  end 

  -- If we are resuming and the current co-ordinates and orientation are the resume point
  -- then are no longer resuming
  if (moveSuccess == true) then
    updateResumingFlag()
  end

  -- Return the move success
  return moveSuccess
 
end
 
-- ********************************************************************************** --
-- Move the turtle forward one block (updating the turtle's position)
-- ********************************************************************************** --
function turtleForward()

  -- Determine the new co-ordinate that the turtle will be moving to
  local newX, newZ

  -- Update the current co-ordinates
  if (currOrient == direction.FORWARD) then
    newZ = currZ + 1
    newX = currX
  elseif (currOrient == direction.LEFT) then
    newX = currX - 1
    newZ = currZ
  elseif (currOrient == direction.BACK) then
    newZ = currZ - 1
    newX = currX
  elseif (currOrient == direction.RIGHT) then
    newX = currX + 1
    newZ = currZ
  else
    writeMessage ("Invalid currOrient in turtleForward function", messageLevel.ERROR)
  end

  local returnVal = moveTurtle(turtle.forward, turtle.detect, turtle.dig, turtle.attack, turtle.compare, turtle.suck, maximumGravelStackSupported, newX, currY, newZ)

  if (returnVal == true) then
    -- Check that there is sufficient inventory space as may have picked up a block
    ensureInventorySpace()
  end
 
  return returnVal
end
 
-- ********************************************************************************** --
-- Move the turtle up one block (updating the turtle's position)
-- ********************************************************************************** --
function turtleUp()

  local returnVal = moveTurtle(turtle.up, turtle.detectUp, turtle.digUp, turtle.attackUp, turtle.compareUp, turtle.suckUp, maximumGravelStackSupported, currX, currY + 1, currZ)

  if (returnVal == true) then
    -- Check that there is sufficient inventory space as may have picked up a block
    ensureInventorySpace()
  end
 
  return returnVal
end
 
-- ********************************************************************************** --
-- Move the turtle down one block (updating the turtle's position)
-- ********************************************************************************** --
function turtleDown()

  local returnVal = moveTurtle(turtle.down, turtle.detectDown, turtle.digDown, turtle.attackDown, turtle.compareDown, turtle.suckDown, 1, currX, currY - 1, currZ)

  if (returnVal == true) then
    -- Check that there is sufficient inventory space as may have picked up a block
    ensureInventorySpace()
  end
 
  return returnVal

end
 
-- ********************************************************************************** --
-- Move the turtle back one block (updating the turtle's position)
-- ********************************************************************************** --
function turtleBack()

  -- Assume that the turtle will move, and switch the co-ords back if it doesn't 
  -- (do this so that we can write the co-ords to a file before moving)
  local newX, newZ
  local prevX, prevZ
  prevX = currX
  prevZ = currZ

  -- Update the current co-ordinates
  if (currOrient == direction.FORWARD) then
    newZ = currZ - 1
    newX = currX
  elseif (currOrient == direction.LEFT) then
    newX = currX + 1
    newZ = currZ
  elseif (currOrient == direction.BACK) then
    newZ = currZ + 1
    newX = currX
  elseif (currOrient == direction.RIGHT) then
    newX = currX - 1
    newZ = currZ
  else
    writeMessage ("Invalid currOrient in turtleBack function", messageLevel.ERROR)
  end

  -- First try to move back using the standard function
  
  currX = newX
  currZ = newZ
  saveLocation()
  local returnVal = turtle.back()

  if (returnVal == false) then
    -- Didn't move. Reset the co-ordinates to the previous value
    currX = prevX
    currZ = prevZ

    -- Reset the location back to the previous location (because the turn takes 0.8 of a second
    -- so could be stopped before getting to the forward function)
    saveLocation()
  
    turtle.turnRight()
    turtle.turnRight()

    -- Try to move by using the forward function (note, the orientation will be set as 
    -- the same way as this function started because if the function stops, that is the
    -- direction that we want to consider the turtle to be pointing)

    returnVal = moveTurtle(turtle.forward, turtle.detect, turtle.dig, turtle.attack, turtle.compare, turtle.suck, maximumGravelStackSupported, newX, currY, newZ)

    turtle.turnRight()
    turtle.turnRight()
  end

  if (returnVal == true) then
    -- Check that there is sufficient inventory space as may have picked up a block
    ensureInventorySpace()
  end
   
  return returnVal
end
 
-- ********************************************************************************** --
-- Turns the turtle (updating the current orientation at the same time)
-- ********************************************************************************** --
function turtleTurn(turnDir)
 
  if (turnDir == direction.LEFT) then
    if (currOrient == direction.FORWARD) then
      currOrient = direction.LEFT
    elseif (currOrient == direction.LEFT) then
      currOrient = direction.BACK
    elseif (currOrient == direction.BACK) then
      currOrient = direction.RIGHT
    elseif (currOrient == direction.RIGHT) then
      currOrient = direction.FORWARD
    else
      writeMessage ("Invalid currOrient in turtleTurn function", messageLevel.ERROR)
    end

    -- If we are resuming, just check to see whether have reached the resume point, otherwise
    -- turn
    if (resuming == true) then
      updateResumingFlag()
    else
      -- Write the new orientation and turn
      saveLocation()
      turtle.turnLeft()
    end

  elseif (turnDir == direction.RIGHT) then
    if (currOrient == direction.FORWARD) then
      currOrient = direction.RIGHT
    elseif (currOrient == direction.LEFT) then
      currOrient = direction.FORWARD
    elseif (currOrient == direction.BACK) then
      currOrient = direction.LEFT
    elseif (currOrient == direction.RIGHT) then
      currOrient = direction.BACK
    else
      writeMessage ("Invalid currOrient in turtleTurn function", messageLevel.ERROR)
    end

    -- If we are resuming, just check to see whether have reached the resume point, otherwise
    -- turn
    if (resuming == true) then
      updateResumingFlag()

      writeMessage("["..currMiningState..", "..currX..", "..currY..", "..currZ..", "..currOrient.."]", messageLevel.DEBUG)
    else
      -- Write the new orientation and turn
      saveLocation()
      turtle.turnRight()
    end
  else
    writeMessage ("Invalid turnDir in turtleTurn function", messageLevel.ERROR)
  end
end
 
-- ********************************************************************************** --
-- Sets the turtle to a specific orientation, irrespective of its current orientation
-- ********************************************************************************** --
function turtleSetOrientation(newOrient)
 
  if (currOrient ~= newOrient) then
    if (currOrient == direction.FORWARD) then
      if (newOrient == direction.RIGHT) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
        end
      elseif (newOrient == direction.BACK) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
          turtle.turnRight()
        end
      elseif (newOrient == direction.LEFT) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnLeft()
        end
      else
        writeMessage ("Invalid newOrient in turtleSetOrientation function", messageLevel.ERROR)
      end
    elseif (currOrient == direction.RIGHT) then
      if (newOrient == direction.BACK) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
        end
      elseif (newOrient == direction.LEFT) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
          turtle.turnRight()
        end
      elseif (newOrient == direction.FORWARD) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnLeft()
        end
      else
        writeMessage ("Invalid newOrient in turtleSetOrientation function", messageLevel.ERROR)
      end
    elseif (currOrient == direction.BACK) then
      if (newOrient == direction.LEFT) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
        end
      elseif (newOrient == direction.FORWARD) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
          turtle.turnRight()
        end
      elseif (newOrient == direction.RIGHT) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnLeft()
        end
      else
        writeMessage ("Invalid newOrient in turtleSetOrientation function", messageLevel.ERROR)
      end
    elseif (currOrient == direction.LEFT) then
      if (newOrient == direction.FORWARD) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
        end
      elseif (newOrient == direction.RIGHT) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnRight()
          turtle.turnRight()
        end
      elseif (newOrient == direction.BACK) then
        currOrient = newOrient

        -- If resuming, check whether the resume point has been reached, otherwise turn
        if (resuming == true) then
          updateResumingFlag()
        else
          -- Write the new orientation and turn
          saveLocation()
          turtle.turnLeft()
        end
      else
        writeMessage ("Invalid newOrient in turtleSetOrientation function", messageLevel.ERROR)
      end
    else
      writeMessage ("Invalid currOrient in turtleTurn function", messageLevel.ERROR)
    end
  end
end
 
-- ********************************************************************************** --
-- Determines if a particular block is considered a noise block or not. A noise
-- block is one that is a standard block in the game (stone, dirt, gravel etc.) and
-- is one to ignore as not being an ore. Function works by comparing the block
-- in question against a set of blocks in the turtle's inventory which are known not to
-- be noise blocks. Param is the function to use to compare the block for a noise block
-- ********************************************************************************** --
function isNoiseBlock(compareFn)
 
  -- Consider air to be a noise block
  local returnVal = false

  if (resuming == true) then
    returnVal = true
  else
    local seamLoop = 1
    local prevSelectedSlot  

    -- If the currently selected slot is a noise block, then compare against this first
    -- so that the slot doesn't need to be selected again (there is a 0.05s cost to do
    -- this even if it is the currently selected slot)
    if (currentlySelectedSlot <= noiseBlocksCount) then
      returnVal = compareFn()
    end

    if (returnVal == false) then
      prevSelectedSlot = currentlySelectedSlot
      while((returnVal == false) and (seamLoop <= noiseBlocksCount)) do
        if (seamLoop ~= prevSelectedSlot) then
          turtle.select(seamLoop) 
          currentlySelectedSlot = seamLoop
          returnVal = compareFn()
        end
        seamLoop = seamLoop + 1
      end
    end
  end

  -- Return the calculated value
  return returnVal
 
end
 
-- ********************************************************************************** --
-- Determines if a particular block is a chest. Returns false if it is not a chest
-- or chests are not being detected
-- ********************************************************************************** --
function isChestBlock(compareFn)
 
  -- Check the block in the appropriate direction to see whether it is a chest. Only
  -- do this if we are looking for chests
  local returnVal = false
  if (lookForChests == true) then
    turtle.select(15)
    currentlySelectedSlot = 15
    returnVal = compareFn()
  end
 
  -- Return the calculated value
  return returnVal
 
end
 
-- ********************************************************************************** --
-- Function to calculate the number of non seam blocks in the turtle's inventory. This
-- is all of the blocks at the start of the inventory (before the first empty slot is
-- found
-- ********************************************************************************** --
function determineNoiseBlocksCountCount()
  -- Determine the location of the first empty inventory slot. All items before this represent
  -- noise items.
  local foundFirstBlankInventorySlot = false
  noiseBlocksCount = 1
  while ((noiseBlocksCount < 16) and (foundFirstBlankInventorySlot == false)) do
    if (turtle.getItemCount(noiseBlocksCount) > 0) then
      noiseBlocksCount = noiseBlocksCount + 1
    else
      foundFirstBlankInventorySlot = true
    end
  end
  noiseBlocksCount = noiseBlocksCount - 1
 
  -- Determine whether a chest was provided, and hence whether we should support
  -- looking for chests
  if (turtle.getItemCount(15) > 0) then
    lookForChests = true
    lastEmptySlot = 14
    miningOffset = 0
    writeMessage("Looking for chests...", messageLevel.DEBUG)
  else
    lastEmptySlot = 15
    miningOffset = 1
    writeMessage("Ignoring chests...", messageLevel.DEBUG)
  end
end
 
-- ********************************************************************************** --
-- Creates a quarry mining out only ores and leaving behind any noise blocks
-- ********************************************************************************** --
function createQuarry()
 
  -- Determine the top mining layer layer. The turtle mines in layers of 3, and the bottom layer
  -- is the layer directly above bedrock.
  --
  -- The actual layer that the turtle operates in is the middle of these three layers,
  -- so determine the top layer
  local topMiningLayer = startHeight + ((bottomLayer - startHeight - 2) % 3) - 1 + miningOffset
 
  -- If the top layer is up, then ignore it and move to the next layer
  if (topMiningLayer > currY) then
    topMiningLayer = topMiningLayer - 3
  end
 
  local startedLayerToRight = true -- Only used where the quarry is of an odd width
 
  -- Loop over each mining row
  local miningLevel
  for miningLevel = (bottomLayer + miningOffset), topMiningLayer, 3 do
    writeMessage("Mining Layer: "..miningLevel, messageLevel.INFO)
    haveBeenAtZeroZeroOnLayer = false
 
    -- While the initial shaft is being dug out, set the level to return to in order to unload
    -- to the just take the turtle straight back up
    if (miningLevel == (bottomLayer + miningOffset)) then
      levelToReturnTo = startHeight
    end

    -- Move to the correct level to start mining
    if (currY > miningLevel) then
      while (currY > miningLevel) do
        turtleDown()
      end
    elseif (currY < miningLevel) then
      while (currY < miningLevel) do
        turtleUp()
      end
    end
 
    -- Am now mining the levels (update the mining state to reflect that fact)
    currMiningState = miningState.LAYER

    -- Set the layer to return via when returning to the surface as the one below the currently
    -- mined one
    if (miningLevel == (bottomLayer + miningOffset)) then
      levelToReturnTo = (bottomLayer + miningOffset)
    else
      levelToReturnTo = miningLevel - 3
    end
 
    -- Move turtle into the correct orientation to start mining (if this is the
    -- first row to be mined, then don't need to turn, otherwise turn towards the next
    -- mining section)

    writeMessage("Mining Level: "..miningLevel..", Bottom Layer: "..bottomLayer..", Mining Offset: "..miningOffset, messageLevel.DEBUG)

    if (miningLevel > (bottomLayer + miningOffset)) then
      -- Turn towards the next mining layer
      if (quarryWidth % 2 == 0) then
        -- An even width quarry, always turn right
        turtleTurn(direction.RIGHT)
      else
        -- Turn the opposite direction to that which we turned before
        if (startedLayerToRight == true) then
          turtleTurn(direction.LEFT)
          startedLayerToRight = false
        else
          turtleTurn(direction.RIGHT)
          startedLayerToRight = true
        end
      end
    end
 
    local mineRows
    local onNearSideOfQuarry = true
    local diggingAway = true
    for mineRows = 1, quarryWidth do

      -- If this is not the first row, then get into position to mine the next row
      if ((mineRows == 1) and (lookForChests == false)) then
        -- Not looking for chests, check the block below for being an ore. Only do this
        -- if we're not looking for chests since the program doesn't support chests in
        -- bedrock
        if (isNoiseBlock(turtle.compareDown) == false) then
          turtle.digDown()
          ensureInventorySpace()
        end
      elseif (mineRows > 1) then
        -- Move into position for mining the next row
        if (onNearSideOfQuarry == diggingAway) then
          if (startedLayerToRight == true) then
            turtleTurn(direction.LEFT)
          else
            turtleTurn(direction.RIGHT)
          end
        else
          if (startedLayerToRight == true) then
            turtleTurn(direction.RIGHT)
          else
            turtleTurn(direction.LEFT)
          end
        end
 
        turtleForward()
 
        -- Before making the final turn, check the block below. Do this
        -- now because if it is a chest, then we want to back up and 
        -- approach it from the side (so that we don't lose items if we 
        -- have to return to the start through it). 
        --
        -- This is the point at which it is safe to back up without moving
        -- out of the quarry area (unless at bedrock in which case don't bother
        -- as we'll be digging down anyway)
        if (miningLevel ~= bottomLayer) then
          if (isNoiseBlock(turtle.compareDown) == false) then
            -- If we are not looking for chests, then just dig it (it takes 
            -- less time to try to dig and fail as it does to do detect and
            -- only dig if there is a block there)
            if (lookForChests == false) then
              turtle.digDown()
              ensureInventorySpace()
            elseif (turtle.detectDown() == true) then
              if (isChestBlock(turtle.compareDown) == true) then
                -- There is a chest block below. Move back and approach
                -- from the side to ensure that we don't need to return to
                -- start through the chest itself (potentially losing items) 
                turtleBack()
                turtleDown()
                currMiningState = miningState.EMPTYCHESTDOWN
                emptyChest(turtle.suck)
                currMiningState = miningState.LAYER
                turtleUp()
                turtleForward()
                turtle.digDown()
                ensureInventorySpace()
              else
                turtle.digDown()
                ensureInventorySpace()
              end
            end
          end
        end
 
        -- Move into final position for mining the next row
        if (onNearSideOfQuarry == diggingAway) then
          if (startedLayerToRight == true) then
            turtleTurn(direction.LEFT)
          else
            turtleTurn(direction.RIGHT)
          end
        else
          if (startedLayerToRight == true) then
            turtleTurn(direction.RIGHT)
          else
            turtleTurn(direction.LEFT)
          end
        end
      end
 
      -- Dig to the other side of the quarry
      local blocksMined
      for blocksMined = 0, (quarryWidth - 1) do
        if (blocksMined > 0) then
          -- Only move forward if this is not the first space
          turtleForward()
        end

        -- If the current block is (0,0), then record the fact that the 
        -- turtle has been through this block and what it's orientation was and update the layer
        -- that it should return via to get back to the surface (it no longer needs to go down
        -- a level to prevent losing ores). 
        if ((currX == 0) and (currZ == 0)) then
          -- Am at (0, 0). Remember this, and what direction I was facing so that the quickest route
          -- to the surface can be taken
          levelToReturnTo = miningLevel
          haveBeenAtZeroZeroOnLayer = true
          orientationAtZeroZero = currOrient
        end

        -- If currently at bedrock, just move down until the turtle can't go any
        -- further. This allows the blocks within the bedrock to be mined
        if (miningLevel == bottomLayer) then
          -- Temporarily turn off looking for chests to increase bedrock mining speed (this
          -- means that the program doesn't support chests below level 5 - but I think
          -- they they don't exist anyway)
          local lookForChestsPrev = lookForChests
          lookForChests = false

          -- Manually set the flag to determine whether the turtle should try to move first or
          -- dig first. At bedrock, is very rarely any space

          -- Just above bedrock layer, dig down until can't dig any lower, and then
          -- come back up. This replicates how the quarry functions
          lastMoveNeededDig = true
          local moveDownSuccess = turtleDown()
          while (moveDownSuccess == true) do
            moveDownSuccess = turtleDown()
          end

          -- Know that we are moving back up through air, therefore set the flag to force the
          -- turtle to try moving first 
          lastMoveNeededDig = false

          -- Have now hit bedrock, move back to the mining layer
          while (currY < bottomLayer) do
            turtleUp()
          end

          -- Now back at the level above bedrock, again reset the flag to tell the turtle to 
          -- try digging again (because it is rare to find air at bedrock level)
          lastMoveNeededDig = false

          -- Reset the look for chests value
          lookForChests = lookForChestsPrev
        elseif ((blocksMined > 0) and ((currX ~= 0) or (currZ ~= 0))) then
          -- This isn't the first block of the row, nor are we at (0, 0) so we need to check the
          -- block below

          -- Check the block down for being a noise block (don't need to check the first
          -- block as it has already been checked in the outer loop)
          if (isNoiseBlock(turtle.compareDown) == false) then
            -- If we are not looking for chests, then just dig it (it takes 
            -- less time to try to dig and fail as it does to do detect and
            -- only dig if there is a block there)
            if (lookForChests == false) then
              turtle.digDown()
              ensureInventorySpace()
            elseif (turtle.detectDown() == true) then
              if (isChestBlock(turtle.compareDown) == true) then
                -- There is a chest block below. Move back and approach
                -- from the side to ensure that we don't need to return to
                -- start through the chest itself (potentially losing items) 
                turtleBack()
                currMiningState = miningState.EMPTYCHESTDOWN
                turtleDown()
                emptyChest(turtle.suck)
                currMiningState = miningState.LAYER
                turtleUp()
                turtleForward()
                turtle.digDown()
                ensureInventorySpace()
              else
                turtle.digDown()
                ensureInventorySpace()
              end
            end
          end
        end
       
        -- Check the block above for ores (if we're not a (0, 0) in which case
        -- we know it's air)
        if ((currX ~= 0) or (currZ ~= 0)) then
          if (isNoiseBlock(turtle.compareUp) == false) then
            -- If we are not looking for chests, then just dig it (it takes 
            -- less time to try to dig and fail as it does to do detect and
            -- only dig if there is a block there)
            if (lookForChests == false) then
              turtle.digUp()
              ensureInventorySpace()
            elseif (turtle.detectUp() == true) then
              -- Determine if it is a chest before digging it
              if (isChestBlock(turtle.compareUp) == true) then
                -- There is a chest block above. Empty it before digging it
                emptyChest(turtle.suckUp)
                turtle.digUp()
                ensureInventorySpace()
              else
                turtle.digUp()
                ensureInventorySpace()
              end
            end
          end
        end
      end
 
      -- Am now at the other side of the quarry
      onNearSideOfQuarry = not onNearSideOfQuarry
    end
 
    -- If we were digging away from the starting point, will be digging
    -- back towards it on the next layer
    diggingAway = not diggingAway
  end
 
  -- Return to the start
  returnToStartAndUnload(false)
 
  -- Face forward
  turtleSetOrientation(direction.FORWARD)
end

-- ********************************************************************************** --
-- Reads the next number from a given file
-- ********************************************************************************** --
function readNumber(inputFile)

  local returnVal
  local nextLine = inputFile.readLine()
  if (nextLine ~= nil) then
    returnVal = tonumber(nextLine)
  end

  return returnVal
end

-- ********************************************************************************** --
-- Startup function to support resuming mining turtle
-- ********************************************************************************** --
function isResume()

  local returnVal = false

  -- Try to open the resume file
  local resumeFile = fs.open(startupParamsFile, "r")
  if (resumeFile == nil) then
    -- No resume file (presume that we are not supporting it)
    supportResume = false
  else
    writeMessage("Found startup params file", messageLevel.DEBUG)

    -- Read in the startup params
    quarryWidth = readNumber(resumeFile)
    startHeight = readNumber(resumeFile)
    noiseBlocksCount = readNumber(resumeFile)
    lastEmptySlot = readNumber(resumeFile)
    resumeFile.close()

    -- If the parameters were successfully read, then set the resuming flag to true
    if ((quarryWidth ~= nil) and (startHeight ~= nil) and (noiseBlocksCount ~= nil) and (lastEmptySlot ~= nil)) then

      resuming = true
      writeMessage("Read params", messageLevel.DEBUG)

      -- Determine the look for chest and mining offset
      if (lastEmptySlot == 14) then
        lookForChests = true
        miningOffset = 0
      else
        lookForChests = false
        miningOffset = 1
      end

      -- Get the turtle resume location
      resumeFile = fs.open(oreQuarryLocation, "r")
      if (resumeFile ~= nil) then

        resumeMiningState = readNumber(resumeFile)
        resumeX = readNumber(resumeFile)
        resumeY = readNumber(resumeFile)
        resumeZ = readNumber(resumeFile)
        resumeOrient = readNumber(resumeFile)
        resumeFile.close()

        -- Ensure that the resume location has been found
        if ((resumeMiningState ~= nil) and (resumeX ~= nil) and (resumeY ~= nil) and (resumeZ ~= nil) and (resumeOrient ~= nil)) then
          returnVal = true
          local emptiedInventory = false

          -- Perform any mining state specific startup
          if (resumeMiningState == miningState.EMPTYINVENTORY) then
            -- Am mid way through an empty inventory cycle. Complete it before
            -- starting the main Quarry function
            returnToStartAndUnload(true)
            resuming = true

            -- Continue from the current position
            resumeX = currX
            resumeY = currY
            levelToReturnTo = resumeY
            resumeZ = currZ
            resumeOrient = currOrient

            writeMessage("Resuming with state of "..currMiningState, messageLevel.DEBUG)
            resumeMiningState = currMiningState
            emptiedInventory = true
          end

          -- If was emptying a chest when the program stopped, then move back
          -- to a point which the Quarry 
          if (resumeMiningState == miningState.EMPTYCHESTDOWN) then

            -- Set the current X, Y, Z and orientation to the true position that
            -- the turtle is at
            if (emptiedInventory == false) then
              currX = resumeX
              currY = resumeY
              currZ = resumeZ
              currOrient = resumeOrient
            end

            -- Set the mining state as layer, assume haven't been through zero
            -- zero and set the level to return to as the one below the current one
            currMiningState = miningState.LAYER
            levelToReturnTo = currY - 2
            haveBeenAtZeroZeroOnLayer = false

            -- Temporarily disable resuming (so that the new location is written to the file
            -- in case the program stops again)
            resuming = false
            turtleUp()
            resuming = true

            resumeY = currY
            resumeMiningState = miningState.LAYER
          end
        end
      end
    end

    if (returnVal == false) then
      writeMessage("Failed to resume", messageLevel.ERROR)
    end
  end

  return returnVal
end
 
-- ********************************************************************************** --
-- Main Function                                          
-- ********************************************************************************** --
-- Process the input arguments - storing them to global variables
local args = { ... }
local paramsOK = true

-- Detect whether this is a wireless turtle, and if so, open the modem
isWirelessTurtle = peripheral.isPresent("right")
if (isWirelessTurtle == true) then
  turtleId = os.getComputerLabel()
  rednet.open("right")
end

if (#args == 0) then
  -- Is this a resume? 
  if (isResume() == false) then
    paramsOK = false
  end
elseif (#args == 1) then
  quarryWidth = tonumber(args[1])
  local x, y, z = gps.locate(5)
  startHeight = y
  if (startHeight == nil) then
    writeMessage("Can't locate GPS", messageLevel.FATAL)
    paramsOK = false
  end
elseif (#args == 2) then
  if (args[2] == "/r") then
    quarryWidth = tonumber(args[1])
    supportResume = false
  else
    quarryWidth = tonumber(args[1])
    startHeight = tonumber(args[2])
  end
elseif (#args == 3) then
  quarryWidth = tonumber(args[1])
  startHeight = tonumber(args[2])
  if (args[3] == "/r") then
    supportResume = false
  else
    paramsOK = false
  end
end

if ((paramsOK == false) and (resuming == false)) then
  writeMessage("Usage: "..shell.getRunningProgram().." <diameter> [turtleY] [/r]", messageLevel.FATAL)
  paramsOK = false
end

if (paramsOK == true) then
  if ((startHeight < 6) or (startHeight > 128)) then
    writeMessage("turtleY must be between 6 and 128", messageLevel.FATAL)
    paramsOK = false
  end
 
  if ((quarryWidth < 2) or (quarryWidth > 64)) then
    writeMessage("diameter must be between 2 and 64", messageLevel.FATAL)
    paramsOK = false
  end
end
 
if (paramsOK == true) then
  writeMessage("---------------------------------", messageLevel.INFO)
  writeMessage("** Ore Quarry v0.7 by AustinKK **", messageLevel.INFO)
  writeMessage("---------------------------------", messageLevel.INFO)
  if (resuming == true) then
    writeMessage("Resuming...", messageLevel.INFO)
  end
 
  -- Set the turtle's starting position
  currX = 0
  currY = startHeight
  currZ = 0
  currOrient = direction.FORWARD
 
  -- Calculate which blocks in the inventory signify noise blocks
  if (resuming == false) then
    determineNoiseBlocksCountCount()
  end
 
  if ((noiseBlocksCount == 0) or (noiseBlocksCount > 13)) then
    writeMessage("No noise blocks have been been added. Please place blocks that the turtle should not mine (e.g. Stone, Dirt, Gravel etc.) in the first few slots of the turtle\'s inventory. The first empty slot signifies the end of the noise blocks.", messageLevel.FATAL)
  else
    -- If we are supporting resume (and are not currently in the process of resuming)
    -- then store startup parameters in appropriate files
    if ((supportResume == true) and (resuming == false)) then
      -- Write the startup parameters to  file
      local outputFile = io.open(startupParamsFile, "w")
      outputFile:write(quarryWidth)
      outputFile:write("\n")
      outputFile:write(startHeight)
      outputFile:write("\n")
      outputFile:write(noiseBlocksCount)
      outputFile:write("\n")
      outputFile:write(lastEmptySlot)
      outputFile:write("\n")
      outputFile:close()

      -- Setup the startup file

      -- Take a backup of the current startup file
      if (fs.exists("startup") == true) then
        fs.copy("startup", startupBackup)
      end
      
      -- Write a new startup file to resume the turtle
      outputFile = io.open("startup", "a")
      outputFile:write("\nshell.run(\"")
      outputFile:write(shell.getRunningProgram())
      outputFile:write("\")\n")
      outputFile:close()

    end

    -- Create a Quarry
    turtle.select(1)
    currentlySelectedSlot = 1
    createQuarry()

    -- Restore the file system to its original configuration
    if (supportResume == true) then
      fs.delete("startup")
      if (fs.exists(startupBackup) == true) then
        fs.move(startupBackup, "startup")
      end

      if (fs.exists(startupParamsFile) == true) then
        fs.delete(startupParamsFile)
      end

      if (fs.exists(oreQuarryLocation) == true) then
        fs.delete(oreQuarryLocation)
      end

      if (fs.exists(returnToStartFile) == true) then
        fs.delete(returnToStartFile)
      end
    end
  end
end
