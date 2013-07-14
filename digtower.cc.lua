-- digtower
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
-- version 1.0
--

local spiral = 0
local wall_slot = 1
local stair_slot = 2
local support_slot = 3
local junk_slot = 3

function refill(slot)
	for i=1,16 do
		turtle.select(i)
		if i ~= wall_slot and i ~= stair_slot and i ~= support_slot then
			if turtle.compareTo(slot) then
				turtle.transferTo(slot)
			end
		end
	end
end

function resupply()
	local need_wall = turtle.getItemCount(wall_slot) < 32
	local need_stair = turtle.getItemCount(stair_slot) < 32
	local need_support = turtle.getItemCount(support_slot) < 32
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


		need_wall = turtle.getItemCount(wall_slot) < 32
		need_stair = turtle.getItemCount(stair_slot) < 32
		need_support = turtle.getItemCount(support_slot) < 32
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

for h=1,16 do

	turtle.select(junk_slot)
	turtle.dig()
	turtle.forward()
	turtle.turnLeft()
	turtle.dig()
	turtle.select(support_slot)
	turtle.place()
	turtle.turnRight()
	turtle.turnRight()
	turtle.place()
	turtle.turnLeft()
	turtle.placeUp()
	turtle.back()
	turtle.select(wall_slot)
	for k=1,4 do
		for i=1,3 do
			resupply()
			turtle.select(junk_slot)
			turtle.digUp()
			turtle.select(support_slot)
			turtle.placeUp()
			if k == 1 and i == 1 then
				turtle.turnLeft()
				turtle.turnLeft()
				turtle.select(support_slot)
				turtle.place()
				turtle.turnRight()
				turtle.turnRight()
			end

			if False then
				print("check stairs "..k.." "..i.." "..spiral.." ["..(k-1)*3+(i-1).."]")
			end
			if ((k-1)*3)+(i-1) == spiral%12 then
				turtle.select(stair_slot)
				turtle.placeDown()

				if spiral%3 == 1 then
					spiral = spiral-1;
					print("Skipping corner")
				end
				if spiral > 0 then
					spiral = spiral-1;
				else
					spiral = 11
				end
				print("Placed stair next at ".. spiral)
			end

			turtle.turnRight()
			turtle.select(junk_slot)
			turtle.dig()
			turtle.select(wall_slot)
			turtle.place()
			turtle.turnLeft()
			turtle.select(junk_slot)
			turtle.dig()
			turtle.forward()
		end
		turtle.turnRight()
		turtle.select(junk_slot)
		turtle.dig()
		turtle.select(wall_slot)
		turtle.place()
		turtle.turnLeft()
		turtle.back()
		turtle.select(wall_slot)
		turtle.place()
		turtle.turnLeft()
	end

	turtle.select(junk_slot)
	turtle.digUp()
	turtle.up()
end
turtle.down()
turtle.select(support_slot)
turtle.placeUp()
turtle.select(wall_slot)

