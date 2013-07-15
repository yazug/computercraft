-- This is buildtunnel
-- It will build a tunnel centered on the turtle going forward
-- it uses 2 building material slots
-- build_slot (1) takes what you want for the floor and solid parts of the tunnel
-- window_slot (2) takes what you want for wall and ceiling window slots (glass)
-- it will build tunnel_len long tunnel at a time.
--
-- Jon.schlueter@gmail.com
-- version 1.1 2013-07-14
--
-- buildtunnel posted on turtlescripts.com
-- market get gjdhl6 buildtunnel y

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

function goUp()
  while not turtle.up() do
    turtle.select(junk_slot)
    turtle.digUp()
    checkRefuel()
    sleep(1)
  end
end

function goDown()
  while not turtle.down() do
    turtle.select(junk_slot)
    turtle.digDown()
    checkRefuel()
    sleep(1)
  end
end

function digUp()
  turtle.select(junk_slot)
  turtle.digUp()
end

function digDown()
  turtle.select(junk_slot)
  turtle.digDown()
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
    turtle.select(junk_slot)
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

function doPlaceWall(slot)
  turtle.select(slot)
  while not turtle.compare() and not turtle.place() do
    turtle.select(junk_slot)
    turtle.dig()
    turtle.select(slot)
  end
end

function buildone()
  turtle.turnLeft()
  -- grab the bottom center block
  digUp()
  placeDown(build_slot)
  goForward()
  placeDown(build_slot)
  goForward()
  placeDown(build_slot)
  goBack()
  doPlaceWall(build_slot)
  goUp()
  doPlaceWall(window_slot)
  goUp()
  doPlaceWall(build_slot)
  goUp()
  doPlaceWall(build_slot)
  goBack()
  doPlaceWall(build_slot)
  -- grab the top center block
  digDown()
  goBack()
  doPlaceWall(window_slot)
  turtle.turnRight()
  turtle.turnRight()
  doPlaceWall(build_slot)
  goDown()
  placeUp(build_slot)
  doPlaceWall(build_slot)
  goDown()
  doPlaceWall(window_slot)
  goDown()
  placeDown(build_slot)
  goForward()
  placeDown(build_slot)
  goBack()
  doPlaceWall(build_slot)
  goBack()
  placeDown(build_slot)
  turtle.turnLeft()
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
  buildone()
end

-- vim: set filetype=lua et sts=2 sw=2 ts=2 sr sta
