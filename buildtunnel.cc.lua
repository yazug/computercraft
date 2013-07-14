-- This is buildtunnel
-- It will build a tunnel centered on the turtle going forward
-- it uses 2 building material slots
-- build_slot (1) takes what you want for the floor and solid parts of the tunnel
-- window_slot (2) takes what you want for wall and ceiling window slots (glass)
-- it will build tunnel_len long tunnel at a time.
--
-- Jon.schlueter@gmail.com
-- version 1.0 2013-07-13

local tunnel_len = 8
local build_slot = 1
local window_slot = 3
local junk_slot = 4
local fuel_slot = 16
function checkRefuel()
   while turtle.getFuelLevel() == 0 do
       turtle.select(fuel_slot)
       turtle.refuel(1)
   end
end
function goUp()
    while not turtle.up() do
        turtle.digUp()
        checkRefuel()
        sleep(1)
    end
end

function goDown()
    while not turtle.down() do
        turtle.digDown()
        checkRefuel()
        sleep(1)
    end
end

function goBack()
    if not turtle.back() then
        turtle.turnRight()
        turtle.turnRight()
        goForward()
        turtle.turnRight()
        turtle.turnRight()
    end
end

function goForward()
    while not turtle.forward() do
        turtle.dig()
        checkRefuel()
        sleep(1)
    end
end

function place(slot)
    turtle.select(slot)
    turtle.place()
end

function placeDown(slot)
        turtle.select(slot)
        turtle.placeDown()
end
function placeUp(slot)
        turtle.select(slot)
        turtle.placeUp()
end

function buildonev2()
    turtle.turnLeft()
    placeDown(build_slot)
    goForward()
    placeDown(build_slot)
    goForward()
    placeDown(build_slot)
    goBack()
    place(build_slot)
    goUp()
    place(window_slot)
    goUp()
    place(build_slot)
    goUp()
    place(build_slot)
    goBack()
    place(build_slot)
    goBack()
    place(window_slot)
    turtle.turnRight()
    turtle.turnRight()
    place(build_slot)
    goDown()
    placeUp(build_slot)
    place(build_slot)
    goDown()
    place(window_slot)
    goDown()
    placeDown(build_slot)
    goForward()
    placeDown(build_slot)
    goBack()
    place(build_slot)
    goBack()
    placeDown(build_slot)
    turtle.turnLeft()
end
 
function resupply(slot,count)
    if turtle.getItemCount(slot) < count then
        for check_slot = 1,16 do
            turtle.select(check_slot)
            if check_slot ~= build_slot and
                check_slot ~= window_slot
            then
                if turtle.compareTo(slot)
                then
                    turtle.transferTo(slot)
                end
            end
        end
    end
    print(turtle.getItemCount(slot).." "..count)
    return turtle.getItemCount(slot) >= count
end
 
print("Solid in slot "..build_slot)
print("Window stuff in slot "..window_slot)
print("Fuel in slot "..fuel_slot)

for len = 1,tunnel_len do
    while not resupply(build_slot,14) do
        print("Need Building materials in slot ".. build_slot)
        sleep(5)
    end
    while not resupply(window_slot,4) do
        print("Need Window material in slot "..window_slot)
        sleep(5)
    end
    goForward()
    buildonev2()
end
