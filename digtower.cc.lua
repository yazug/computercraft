--
-- This was created to dig/build a tower up in the nether including
-- It will dig/build a 3by3 inside tower with full replacement of the
-- outside of the tower with building material provided
--
-- It places a spiral of stair_material up the center with a center core
-- of support material.
--
-- It will also attempt to maintain a lava safe environment at all time
-- during the build
--
-- author: jon.schlueter@gmail.com (yazug)
-- 2013-07-14
--
-- version 1.1
--
-- Reworked total logic for digging/building tower and placing steps
--
-- TODO: Still has problems with gravel falling through when digging out the ceiling
--
-- to get from the market (turtlescripts.com)
-- market get gjdhko digtower y

local wall_slot = 1
local stair_slot = 2
local support_slot = 3
local junk_slot = 3
local build_height = 8

function refill(slot)
  if turtle.getItemCount(slot) > 0
  then
    for i=1,16 do
      turtle.select(i)
      if
        i ~= wall_slot and
        i ~= stair_slot and
        i ~= support_slot and
        turtle.compareTo(slot)
      then
        turtle.transferTo(slot)
      end
    end
  end
end

function resupply()
  local need_wall = turtle.getItemCount(wall_slot) < 24
  local need_stair = turtle.getItemCount(stair_slot) < build_height + 1
  local need_support = turtle.getItemCount(support_slot) < 25
  if need_wall and turtle.getItemCount(wall_slot) > 0 then
    print("Attempting refill of Wall")
    refill(wall_slot)
  end
  if need_stair and turtle.getItemCount(stair_slot) > 0 then
    print("Attempting refill of Stairs")
    refill(stair_slot)
  end
  if need_support and turtle.getItemCount(support_slot) > 0 then
    print("Attempting refill of Support")
    refill(support_slot)
  end

  while
    (turtle.getItemCount(wall_slot) == 0 ) or
    (turtle.getItemCount(stair_slot) == 0 ) or
    (turtle.getItemCount(support_slot) == 0 )
  do
    term.clear()
    term.setCursorPos(1,1)
    print("Turtle needs supplies")

    if need_wall then
      turtle.select(wall_slot)
      print("Wall Material in Slot "..wall_slot)
    end
    if need_stair then
      turtle.select(stair_slot)
      print("Stairs Material in Slot "..stair_slot)
    end
    if need_support then
      turtle.select(support_slot)
      print("Support Material in Slot "..support_slot)
    end
    sleep(5)

    need_wall = turtle.getItemCount(wall_slot) < 24
    need_stair = turtle.getItemCount(stair_slot) < build_height + 1
    need_support = turtle.getItemCount(support_slot) < 25
    if need_wall and turtle.getItemCount(wall_slot) > 0 then
      refill(wall_slot)
    end
    if need_stair and turtle.getItemCount(stair_slot) > 0 then
      refill(stair_slot)
    end
    if support_slot and turtle.getItemCount(support_slot) > 0 then
      refill(support_slot)
    end
  end
end

function doPlace(slot)
  turtle.select(slot)
  return turtle.place(slot)
end

function doPlaceUp(slot)
  turtle.select(slot)
  return turtle.placeUp(slot)
end
function doPlaceDown(slot)
  turtle.select(slot)
  return turtle.placeDown()
end
function safePlaceUp(slot)
  turtle.select(slot)
  while not turtle.compareUp() and not turtle.placeUp(slot) do
    turtle.select(junk_slot)
    turtle.digUp()
    turtle.select(slot)
  end
end
function goForward()
  while not turtle.forward() do
    turtle.select(junk_slot)
    turtle.dig()
  end
end
function goForwardSafe()
  safePlaceUp(support_slot)
  goForward()
  safePlaceUp(support_slot)
end

function goUpSafe()
  while not turtle.up() do
    turtle.select(junk_slot)
    turtle.digUp()
  end
  doPlaceUp(support_slot)
  for i=1,4 do
    doPlace(support_slot)
    turtle.turnLeft()
  end
end

function doPlaceWall(slot)
  turtle.select(slot)
  while not turtle.compare() and not turtle.place() do
    turtle.select(junk_slot)
    turtle.dig()
    turtle.select(slot)
  end
end

function doPlaceCorner(slot)
  turtle.turnRight()
  goForwardSafe()
  turtle.turnLeft()
  doPlaceWall(slot)
  turtle.turnRight()
  turtle.back()
  doPlaceWall(slot)
  turtle.turnLeft()
  doPlaceWall(slot)
end

function newFloor(floor_place)
  goForwardSafe()
  doPlaceWall(wall_slot)
  turtle.turnLeft()
  if floor_place%8 == 0 then doPlaceDown(stair_slot) end
  goForwardSafe()
  doPlaceCorner(wall_slot)
  turtle.turnLeft()
  if floor_place%8 == 7 then doPlaceDown(stair_slot) end
  goForwardSafe()
  turtle.turnRight()
  doPlaceWall(wall_slot)
  turtle.turnLeft()
  if floor_place % 8 == 6 then doPlaceDown(stair_slot) end
  goForwardSafe()
  doPlaceCorner(wall_slot)
  turtle.turnLeft()
  if floor_place % 8 == 5 then doPlaceDown(stair_slot) end
  goForwardSafe()
  turtle.turnRight()
  doPlaceWall(wall_slot)
  turtle.turnLeft()
  if floor_place % 8 == 4 then doPlaceDown(stair_slot) end
  goForwardSafe()
  doPlaceCorner(wall_slot)
  turtle.turnLeft()
  if floor_place % 8 == 3 then doPlaceDown(stair_slot) end
  goForwardSafe()
  turtle.turnRight()
  doPlaceWall(wall_slot)
  turtle.turnLeft()
  if floor_place % 8 == 2 then doPlaceDown(stair_slot) end
  goForwardSafe()
  doPlaceCorner(wall_slot)
  turtle.turnLeft()
  if floor_place % 8 == 1 then doPlaceDown(stair_slot) end
  goForwardSafe()
  turtle.turnLeft()
  goForwardSafe()
  turtle.turnLeft()
  turtle.turnLeft()
end

resupply()
newFloor(0)
for i=1,build_height do
  resupply()
  goUpSafe()
  doPlaceDown(support_slot)
  newFloor(i)
end

-- vim: set filetype=lua et sts=2 sw=2 ts=2 sr sta
