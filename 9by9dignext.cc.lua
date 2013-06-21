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
    while turtle.digUp() do end
    while turtle.dig() do end
    while turtle.digDown() do end
    while turtle.detectUp() or turtle.detect() do
        turtle.digUp()
	turtle.dig()
        sleep(gravel_fall_time)
    end
end

function forward()
    
    while not turtle.forward() do
        turtle.select(junk_slot)
	while turtle.dig() do end
        while turtle.getFuelLevel() == 0 do
            turtle.select(fuel_slot)
            if turtle.getItemCount() == 0 or not turtle.refuel(1) then
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
        for i=1,16 do
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
        while turtle.digUp() do end
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

function goDown(count)
  for i=1,count do
    while not turtle.down() do
      turtle.digDown()
      if turtle.getFuelLevel() == 0 then
        turtle.select(fuel_slot)
        if turtle.getItemCount() == 0 or not turtle.refuel(1) then
          print("Need Fuel to move... Please add fuel to slot " .. fuel_slot )
          sleep(5)
        end
      end
      print("Turtle Movement blocked going down")
    end
  end
end

function doArea2(size,center,corner, next)
  turtle.turnLeft()
  center()
  turtle.turnRight()
  for i=1,size do
    print(i)
    for j=1,4 do
      center()
      doCorner(i,corner)
    end
    if i < size then
      next()
    end
  end
end

function doArea(size,center,corner, next)
  for i=1,size do
    print(i)
    for j=1,4 do
      center()
      if size-i == 0 then
	return
      end
      doCorner(size-i,corner)
    end
    next()
  end
end

function digRoomInsideOut()
  goUp(1)
  for i=1,4 do
    forward()
  end
  turtle.turnLeft()
  doArea2(3,doAir,doAir,nextLoopTop)
  turtle.turnRight()
 
  for i=1,3 do
    forward()
  end

  goUp(2)
  turtle.turnLeft()
  doArea2(3,doAir,doAir,nextLoopTop)
  goDown(3)
  turtle.turnLeft()
  forward()
  turtle.turnLeft()
  turtle.turnLeft()
end

function digRoom()
  goUp(1)
  forward()
  turtle.turnLeft()
  turtle.turnLeft()
  forward()
  turtle.turnRight()
  doArea(4,doAir,doAir,nextLoop)
  turtle.back()
  goUp(2)
  turtle.turnLeft()
  for i=1,3 do
    forward()
  end
  turtle.turnLeft()
  turtle.turnLeft()
  print("NextFloor")
  turtle.turnLeft()
  doArea(4,doAir,doAir,nextLoop)
  turtle.back()
  turtle.turnLeft()
  goDown(3)
  for i=1,4 do
    forward()
  end
  turtle.turnLeft()
  turtle.turnLeft()
  turtle.back()
end

function digNext()
  goUp(1)
  dig()
  forward()
  dig()
  forward()
  dig()
  forward()
  dig()
  goDown(1)
end

if isRunning then

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
    print("Starting")

    digNext()

end
