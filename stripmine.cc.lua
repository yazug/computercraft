local tArgs = { ... }
if #tArgs ~= 2 and #tArgs ~= 3 then
	print( "Usage: stripmine <length> <lanes> [direction]" )
	return
end

local len = tonumber( tArgs[1] )
local lanes = tonumber( tArgs[2] )
local direction = 0

if #tArgs == 3 then
	direction = tonumber( tArgs[3] )
	if direction < 1 then
		direction = 0
	else
		direction = 1
	end
end

if len < 1 then
	print( "Strip mine length must be positive!" )
	return
end

if lanes < 1 then
	print( "Strip mine lanes must be positive!" )
	return
end
	
local depth = 0
local unloaded = 0
local collected = 0

local xPos,zPos = 0,0
local xDir,zDir = 0,1

local stripMine -- Filled in further down
local checkForVein

local function turnLeft()
	turtle.turnLeft()
	xDir, zDir = -zDir, xDir
end

local function turnRight()
	turtle.turnRight()
	xDir, zDir = zDir, -xDir
end

local function compareValuableFront()
	turtle.select(1)
	local bValuable1 = not turtle.compare()
	turtle.select(2)
	local bValuable2 = not turtle.compare()
	turtle.select(3)
	local bValuable3 = not turtle.compare()
	turtle.select(4)
	local bValuable4 = not turtle.compare()
	turtle.select(5)
	local bValuable5 = not turtle.compare()
	turtle.select(6)
	local bValuable6 = not turtle.compare()
	turtle.select(7)
	local bValuable7 = not turtle.compare()
	turtle.select(8)
	local bValuable8 = not turtle.compare()

	return bValuable1 and bValuable2 and bValuable3 and bValuable4 and bValuable5 and bValuable6 and bValuable7 and bValuable8
end

local function compareValuableTop()
	turtle.select(1)
	local bValuable1 = not turtle.compareUp()
	turtle.select(2)
	local bValuable2 = not turtle.compareUp()
	turtle.select(3)
	local bValuable3 = not turtle.compareUp()
	turtle.select(4)
	local bValuable4 = not turtle.compareUp()
	turtle.select(5)
	local bValuable5 = not turtle.compareUp()
	turtle.select(6)
	local bValuable6 = not turtle.compareUp()
	turtle.select(7)
	local bValuable7 = not turtle.compareUp()
	turtle.select(8)
	local bValuable8 = not turtle.compareUp()

	return bValuable1 and bValuable2 and bValuable3 and bValuable4 and bValuable5 and bValuable6 and bValuable7 and bValuable8
end

local function compareValuableBottom()
	turtle.select(1)
	local bValuable1 = not turtle.compareDown()
	turtle.select(2)
	local bValuable2 = not turtle.compareDown()
	turtle.select(3)
	local bValuable3 = not turtle.compareDown()
	turtle.select(4)
	local bValuable4 = not turtle.compareDown()
	turtle.select(5)
	local bValuable5 = not turtle.compareDown()
	turtle.select(6)
	local bValuable6 = not turtle.compareDown()
	turtle.select(7)
	local bValuable7 = not turtle.compareDown()
	turtle.select(8)
	local bValuable8 = not turtle.compareDown()

	return bValuable1 and bValuable2 and bValuable3 and bValuable4 and bValuable5 and bValuable6 and bValuable7 and bValuable8
end

local function checkForVein(mode)
	if mode ~= 4 then
		turnLeft()
		if	turtle.detect() then
			if compareValuableFront() then
				if turtle.dig() then
					while not turtle.forward() do
						turtle.dig()
					end
					checkForVein(1)
				end
			end
		end

		turnRight()
		if	turtle.detect() then
			if compareValuableFront() then
				if turtle.dig() then
					while not turtle.forward() do
						turtle.dig()
					end
					checkForVein(1)
				end
			end
		end
	end

	if	turtle.detectUp() then
		if compareValuableTop() then
			if turtle.digUp() then
				while not turtle.up() do
					turtle.digUp()
				end
				checkForVein(2)
			end
		end
	end

	if	turtle.detectDown() then
		if compareValuableBottom() then
			if turtle.digDown() then
				turtle.down()
				checkForVein(3)
			end
		end
	end

	if mode ~= 4 then
		turnRight()
		if	turtle.detect()	then
			if compareValuableFront() then
				if turtle.dig() then
					while not turtle.forward() do
						turtle.dig()
					end
					checkForVein(1)
				end
			end
		end

		turnLeft()

		if mode == 1 then
			turtle.back()
		elseif mode == 2 then
			turtle.down()
		elseif mode == 3 then
			while not turtle.up() do
				turtle.digUp()
			end
		end
	end
end

local function unloadItems()
	for i = 9, 16 do
		turtle.select(i)
		turtle.drop()
	end
end

local function returnToStart(curPos, direction)
	print ( "Returning to unload" )
	for n = 1, len do
		turtle.back()
	end

	if direction == 0 then
		turnLeft()
	else
		turnRight()
	end

	for n = 1, curPos do
			turtle.forward()
	end
	unloadItems()

	if direction == 0 then
		turnRight()
	else
		turnLeft()
	end
end

local function shiftStrip(curPos, direction)
	if curPos > 0 then

		if direction == 0 then
			turnRight()
		else
			turnLeft()
		end

		for n = 1, curPos do
			while not turtle.forward() do
				turtle.dig()
			end

			if n > curPos - 3 and n <= curPos then
				checkForVein(4)
			end
		end

		if direction == 0 then
			turnLeft()
		else
			turnRight()
		end
	end
end

local function stripMine(len, lanes, direction)
	local curPos = 0
	for i = 1, lanes do
		print(direction)
		shiftStrip(curPos, direction)

		for j = 1, len do
			while not turtle.forward() do
				turtle.dig()
			end
			checkForVein(0)
		end
		returnToStart(curPos, direction)
		curPos = curPos + 3
	end
	print( "Done mining." )
end

stripMine(len, lanes, direction)
