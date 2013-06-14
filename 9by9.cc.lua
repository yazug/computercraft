--
-- This script will create a Direwolf20 classic 9x9 room
--
-- If the turtle is a mining turtle it can clear the area as well
-- if not it will just place the walls,floor and ceiling as needed
-- but will get stuck if there are obsticles.
--
-- It will prompt you for what to place in which slots
--
-- Version 1.0
-- Author: yazug (jon.schlueter@gmail.com)
--
-- http://turtlescripts.com/project/gjdhcs-9by9
--

local tArgs = {...}
local wall_slot = 1
local floor_slot = 2
local ceiling_slot = 1
local skylight_slot = 3
local torch_slot = 4
local fuel_slot = 16
local junk_slot = 1
local forward_sleep_time = 4
local gravel_fall_time = 0.7
local isRunning=true

if tArgs[1] == "update" then
    local sCode, sFile, sPin = "gjdhjd", "9by9", ""
    local sPath = shell.resolve( sFile )
    write( "Connecting to TurtleScripts.com... " )
    local response = http.post("http://api.turtlescripts.com/getFileRaw/"..textutils.urlEncode( sCode ),"pin="..sPin)
    if response then
        local sResponse = response.readAll()
        response.close()
        local file = fs.open( sPath, "w" )
        file.write( sResponse )
        file.close()
        print( " " )
        print( "Remote: #"..sCode )
        print( "Local: "..sFile )
        print( "[===========================] 100%" )
        print(string.len(sResponse).." bytes")
        print( " " )
        print( "Update Complete." )
        print( " " )
    else
        print( "Failed to update." )
        print( " " )
    end
    isRunning = false
end

function printUsage()
    print(" Usage: ")
    print("   9by9 ")
    print("   9by9 help ")
    print("   9by9 update ")
    print(" ")
end

function doCorner(count, action)
    for i=1,count-1 do
        action()
    end
    turtle.turnRight()
    for i=1,count do
        action()
    end
end

function dig()
    turtle.select(junk_slot)
    turtle.digUp()
    turtle.dig()
    turtle.digDown()
    sleep(gravel_fall_time)
    while turtle.detectUp() do
        turtle.digUp()
        sleep(gravel_fall_time)
    end
    while turtle.detect() do
        turtle.dig()
        sleep(gravel_fall_time)
    end
    
end

function forward()
    
    while not turtle.forward() do
        while turtle.getFuelLevel() == 0 do
            turtle.select(fuel_slot)
            if not refuel() then
                print("Need Fuel to move... Please add fuel to slot " .. fuel_slot )
                sleep(5)
            end
        end
        turtle.select(junk_slot)
        turtle.dig()
        while turtle.detect() do
            turtle.dig()
            turtle.attack()
            sleep(forward_sleep_time)
            print("Blocked from going forward")
        end
    end
end

function doFloor()
    dig()
    placeDown(floor_slot)
    forward()
end

function doWall()
    dig()
    placeWall(wall_slot)
end

function doCeiling()
    dig()
    placeDown(ceiling_slot)
    forward()
end

function doSkylight()
    dig()
    placeDown(skylight_slot)
    forward()
end

function doAir()
    dig()
    forward()
end
    
function placeWall(slot)
    checkSupplies(slot,3)
    turtle.select(slot)
    turtle.placeDown()
    turtle.placeUp()
    forward()
    turtle.select(slot)
    turtle.turnRight()
    turtle.turnRight()
    turtle.place()
    turtle.turnRight()
    turtle.turnRight()
end

function checkSupplies(slot, quantity)
    if turtle.getItemSpace(slot) > 60 then
        --TODO: Don't steal from other named slots
        for i=5,16 do
            turtle.select(i)
            if turtle.compareTo(slot) then
                turtle.transferTo(slot)
            end
            if turtle.getItemSpace(slot) < 32 then
                break
            end
        end
    end
    while turtle.getItemCount(slot) < quantity do
        print("Need Items in " .. slot .. " quantity " .. quantity - turtle.getItemCount(slot))
        sleep(10)
    end 
end

function placeDown(slot)
    checkSupplies(slot,1)
    turtle.select(slot)
    turtle.placeDown()
end

function placeUp(slot)
    checkSupplies(slot,1)
    turtle.select(slot)
    turtle.placeUp()
end

function place(slot)
   checkSupplies(slot,1)
   turtle.select(slot)
   turtle.place()
end

function nextLoop()
    turtle.turnRight()
    forward()
    turtle.turnLeft()
end

function nextLoopTop()
    turtle.turnLeft()
    forward()
    turtle.turnRight()
end
function goUp(count)
    for i=1,count do
        while not turtle.up() do
            turtle.digUp()
            sleep(gravel_fall_time)
            if turtle.getFuelLevel() == 0 then
                turtle.select(fuel_slot)
                if not turtle.refuel(1) then
                    print("Need Fuel to move... Please add fuel to slot " .. fuel_slot )
                    sleep(5)
                end
            print("Turtle Movement blocked going up")
            end
        end
    end
end


-- From Excavate2
function refuel( ammount )
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then
		return true
	end
	
	local needed = ammount 
	if turtle.getFuelLevel() < needed then
		local fueled = false
		for n=1,16 do
			if turtle.getItemCount(n) > 0 then
				turtle.select(n)
				if turtle.refuel(1) then
					while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
						turtle.refuel(1)
					end
					if turtle.getFuelLevel() >= needed then
						turtle.select(1)
						return true
					end
				end
			end
		end
		turtle.select(1)
		return false
	end
	
	return true
end




-- Actual main function
if isRunning then

    print("Place 4 stacks of wall building materials into slot " .. wall_slot .. " and others")
    turtle.select(wall_slot)
    -- TODO: Actually count how many other blocks of same type are in inventory
    while turtle.getItemCount(wall_slot) < 64 do
        print("Waiting for more items for the wall")
        sleep(2)
    end
    print("Place 1 stack of Flooring materials into slot " .. floor_slot)
    turtle.select(floor_slot)
    while turtle.getItemCount(floor_slot) < 50 do
        print("Waiting for more items for the floor")
        sleep(2)
    end
    print("Place Skylight material into slot " .. skylight_slot)
    turtle.select(skylight_slot)
    while turtle.getItemCount(skylight_slot) < 16 do
        print("Waiting for more items for the skylights")
        sleep(2)
    end    
    print("Place torches into slot " .. torch_slot)
    turtle.select(torch_slot)
    while turtle.getItemCount(torch_slot) < 4 do
        print("Waiting for more torches")
        sleep(2)
    end
    print("Place fuel into slot " .. fuel_slot)
    turtle.select(fuel_slot)
    
    while turtle.getFuelLevel() < 200 do
       
        while turtle.getItemCount(fuel_slot) < 1 do
            print("Waiting for more fuel. have ["..turtle.getFuelLevel() .. "] of 200")
            sleep(2)
        end
       if not turtle.refuel(1) then
            print("Item in fuel slot is not burnable!")
            sleep(1)
        end
    end
	print("Fuel Level: ["..turtle.getFuelLevel() .. "] ")
    print("Starting Floor Pass")
	
-- Begin Floor	
    turtle.turnLeft()
    doFloor()
    doCorner(4,doWall)
    doWall()
    doCorner(4,doWall)
    doWall()
    doCorner(4,doWall)
    doWall()
    doCorner(4,doWall)

    nextLoop()

    doFloor()
    doCorner(3,doFloor)
    doFloor()
    doCorner(3,doFloor)
    doFloor()
    doCorner(3,doFloor)
    doFloor()
    doCorner(3,doFloor)

    nextLoop()

    doCorner(3,doFloor)
    doCorner(2,doFloor)
    doCorner(3,doFloor)
    doCorner(2,doFloor)

    nextLoop()

    doCorner(2,doFloor)
    doCorner(1,doFloor)
    doCorner(2,doFloor)
    doCorner(1,doFloor)

    nextLoop()

    dig()
    
    placeDown(floor_slot)
-- end floor


    
    goUp(1)
    turtle.select(torch_slot)
    turtle.placeDown()
    goUp(2)
    
    turtle.turnLeft()
    forward()
    forward()
    forward()
    forward()
    turtle.turnLeft()
    turtle.turnLeft()

	print("Fuel Level: ["..turtle.getFuelLevel() .. "] ")
    print("Starting Wall Pass")

-- begin Wall pass 1    
    turtle.turnLeft()
    doAir()
    doCorner(4,doWall)
    doWall()
    doCorner(4,doWall)
    doWall()
    doCorner(4,doWall)
    doWall()
    doCorner(4,doWall)
    turtle.turnRight()
    doWall()
    
    turtle.turnLeft()

    doAir()
    doCorner(3,doAir)
    doAir()
    doCorner(3,doAir)
    doAir()
    doCorner(3,doAir)
    doAir()
    doCorner(3,doAir)

    nextLoop()

    doCorner(3,doAir)
    doCorner(2,doAir)
    doCorner(3,doAir)
    doCorner(2,doAir)

    nextLoop()

    doCorner(2,doAir)
    doCorner(1,doAir)
    doCorner(2,doAir)
    doCorner(1,doAir)

    nextLoop()
    dig()
-- end wall pass 1

    
    goUp(3)

	print("Fuel Level: ["..turtle.getFuelLevel() .. "] ")
    print("Starting Ceiling pass")
-- Begin Ceiling    
    turtle.turnLeft()
    doCeiling()
    turtle.turnRight()
    
    doCeiling()
    doCorner(1,doSkylight)
    doCeiling()
    doCorner(1,doSkylight)
    doCeiling()
    doCorner(1,doSkylight)
    doCeiling()
    doCorner(1,doSkylight)

    nextLoopTop()

    doCeiling()
    doCorner(2,doSkylight)
    doCeiling()
    doCorner(2,doSkylight)
    doCeiling()
    doCorner(2,doSkylight)
    doCeiling()
    doCorner(2,doSkylight)

    nextLoopTop()

    doCeiling()
    doCorner(3,doCeiling)
    doCeiling()
    doCorner(3,doCeiling)
    doCeiling()
    doCorner(3,doCeiling)
    doCeiling()
    doCorner(3,doCeiling)    
    nextLoopTop()
    
    doCeiling()
    doCorner(4,doCeiling)
    doCeiling()
    doCorner(4,doCeiling)
    doCeiling()
    doCorner(4,doCeiling)
    doCeiling()
    doCorner(4,doCeiling)
-- end ceiling

-- return to original position    
    turtle.turnLeft()
    forward()
    turtle.turnRight()
    turtle.turnRight()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.forward()

	print("Fuel Level: ["..turtle.getFuelLevel() .. "] ")

end
