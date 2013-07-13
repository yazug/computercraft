-- AndyLogger a Computercraft Turtle Program by Andrakon
-- Version 1.72
-- Get the startup script with "pastebin get nDgxjQas startup"


-- Section: Variables -----------------------------------------------------------------------------
-- these are defaults loaded when the turtle runs for the first time
local whatsMyName = "Andy Logger" 
local logSlot = 2   			
local fuelSlot1 = 13
local fuelSlot2 = 14
local saplingSlot1 = 9
local saplingSlot2 = 10
local dirtSlot = 1
local minFuel = 100 		-- the turtle will refuel itself if the fuel level dips below this
local firstRun = true 		-- do I need to place down the dirt for the first time
local saplingGap = 2 		-- blocks between saplings
local wallGap = 2 		-- blocks between turtle's starting position and the first tree
local sleepTime = 600 		-- automatically adjusted by program
local baseTime = 600 		-- used for making the sleepTime calculation and is not saved in logger.cfg
local useFurnace = true 	-- do you want the turtle to make its own charcoal? Put a furnace above it to use.
local poweredFurnace = false 	-- set to true if your furnace is powered by something else
local charcoalNumber = 2 	-- number of charcoal to make each logging run, in multiples of 8
local dumpStuff = true 		-- if true the turtle will drop off extra stuff in a chest on its right
local getSaplings = true 	-- if true the turtle will get saplings from a chest on its left, put only saplings in there
local treeTotal = 0 		-- keeps track of how many trees it has cut down
local charcoalMade = 0		-- keeps track of how many charcoal it has made
local saplingsPlanted = 0 	-- keeps track of how many saplings it has planted
local fuelOn = true		-- setting for if the server has fuel disabled for turtles
local rowOffset = 0 		-- scoot the first row left (+) or right (-) with a positive or negative number
local needsBroken = false	-- if the turtle can't find its way back home you will need to break it before it runs again
local omgDirt = 0
-- variables for saving the turtle's cordinates, saved in loggercords.dat
local cordsx = 0
local cordsy = 0
local cordsz = 0
local facing = 1

-- SECTION: Settings Saving and Loading -----------------------------------------------------------
function saveSettings() -- write the settings to logger.cfg
	term.setCursorPos (3, 2)
	write ("Commiting to memory")
	local file = fs.open ("logger.cfg", "w")
	file.writeLine (whatsMyName)
	file.writeLine (logSlot)
	file.writeLine (fuelSlot1)
	file.writeLine (fuelSlot2)
	file.writeLine (saplingSlot1)
	file.writeLine (saplingSlot2)
	file.writeLine (dirtSlot)
	file.writeLine (minFuel)
	file.writeLine (firstRun)
	file.writeLine (saplingGap)
	file.writeLine (wallGap)
	file.writeLine (sleepTime)
	file.writeLine (long)
	file.writeLine (wide)
	file.writeLine (useFurnace)
	file.writeLine (poweredFurnace)
	file.writeLine (charcoalNumber)
	file.writeLine (dumpStuff)
	file.writeLine (getSaplings)
	file.writeLine (treeTotal)
	file.writeLine (charcoalMade)
	file.writeLine (saplingsPlanted)
	file.writeLine (fuelOn)
	file.writeLine (rowOffset)
	file.writeLine (needsBroken)
	file.close ( )
	sleep (0.3)
	term.setCursorPos (3, 2)
	write ("                   ")
end

function loadSettings() -- load values from logger.cfg
	term.setCursorPos (3, 2)
	write (" Trying to Remember...")
	local file = fs.open ("logger.cfg", "r")
	whatsMyName = file.readLine ( )
	logSlot = tonumber (file.readLine ( )) 
	fuelSlot1 = tonumber (file.readLine ( ))
	fuelSlot2 = tonumber (file.readLine ( ))
	saplingSlot1 = tonumber (file.readLine ( ))
	saplingSlot2 = tonumber (file.readLine ( ))
	dirtSlot = tonumber (file.readLine ( ))
	minFuel = tonumber (file.readLine ( ))
	firstRun = file.readLine ( ) == "true"
	saplingGap = tonumber (file.readLine ( )) 
	wallGap = tonumber (file.readLine ( )) 
	sleepTime = tonumber (file.readLine ( ))
	long = tonumber (file.readLine ( ))
	wide = tonumber (file.readLine ( ))
	useFurnace = file.readLine ( ) == "true"
	poweredFurnace = file.readLine ( ) == "true"
	charcoalNumber = tonumber (file.readLine ( ))
	dumpStuff = file.readLine ( ) == "true"
	getSaplings = file.readLine ( ) == "true"
	treeTotal = tonumber (file.readLine ( )) 
	charcoalMade = tonumber (file.readLine ( )) 
	saplingsPlanted = tonumber (file.readLine ( ))
	fuelOn = file.readLine ( ) == "true"
	liltest = (file.readLine ( ))
	if type( tonumber (liltest) ) == "number" then
		-- rowOffset = tonumber (file.readLine ( ))
		rowOffset = tonumber (liltest)
	else
		rowOffset = 0
		rowOffset = tonumber (rowOffset)
	end
	needsBroken = file.readLine ( ) == "true"
	file.close ( )
end


-- SECTION: Cordinate Handling
-- cords notes: x is forward and backward, z is left and right
-- faceing is as follows: 1 is x+, 2 is z+, 3 is x-, 4 is z- or
-- Forward, Right, Backward, Left from inital placement 
-- all cords and facings are relative to turtles initial placement, not minecraft cords

function saveCords() -- write cordinates to loggercords.dat
	local file = fs.open ("loggercords.dat", "w")
	file.writeLine (cordsx)
	file.writeLine (cordsy)
	file.writeLine (cordsz)
	file.writeLine (facing)
	file.close ( )
end

function loadCords() -- read cordinates from loggercords.dat
	local file = fs.open ("loggercords.dat", "r")
	cordsx = tonumber (file.readLine ( )) 
	cordsy = tonumber (file.readLine ( ))
	cordsz = tonumber (file.readLine ( ))
	facing = tonumber (file.readLine ( ))
	file.close ( )
end
	
function homeCheck() -- see if turtle is at home after booting up
	-- checks to see if turtle was broken, most likely the player will not refill logslot
	if turtle.getItemCount(logSlot) == 0 then 
		cordsx = 0
		cordsy = 0
		cordsz = 0
		facing = 1
		saveCords()
		loadCords()
		return true
	end
	-- check cords and returns true if at home position and facing
	if cordsx == 0 then
		if cordsy == 0 then
			if cordsz == 0 then
				if facing == 1 then
					return true
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end	
	
function goHome() -- turtle was out in the field when restarted, lets get it home
	-- finish cutting down tree first
	if cordsx == 0 then -- Dodge the furnace! 
		if cordsz == 0 then
			if cordsy == 2 then
				while facing ~= 1 do
					turn ("left")
				end
				forward(1)
				down(2)
				turn("back")
				forward(1)
				turn("back")
				return
			end
		end
	end
	turtle.select(logSlot)
	if cordsy ~= 0 then
		height = 0
		up(1)
		height = height + 1
		while turtle.compareUp() do
			turtle.digUp ()
			up (1)
			height = height + 1
		end
		down(height)
	end
	-- get to the right height
	term.setCursorPos (1, 2)
	clearLine()
	write ("| Im heading home! :D")
	while cordsy > 0 do
		down (1)
		sleep (0.2)
	end
	if cordsy < 0 then 
		up (1)
	end
	-- face the correct z direction to go home
	if cordsz < 0 then
		while facing ~= 2 do
			turn ("right")
		end
	elseif cordsz > 0 then
		while facing ~= 4 do
			turn ("left")
		end
	end
	-- get to z = 0
	while cordsz ~= 0 do
		forward (1)
		sleep (0.3)
	end
	-- face towards home
	while facing ~= 3 do
		turn ("left")
	end
	-- go home
	while cordsx ~= 0 do
		forward (1)
		sleep (0.2)
	end
	turn ("back") -- should now be home facing the right direction
	if useFurnace == true then -- lets make sure the turtle made it home, assuming a chest or furnace is nearby
		if furnaceCheck() == false then
			needsBroken = true
			saveSettings()
			term.clear()
			term.setCursorPos (1, 1)
			print ("Logger may not have made it home so the program was closed. Break the turtle and replace it to continue.")
			running = false
			return
		end
	elseif dumpStuff == true then -- if useFurnace is off, check for a dump chest
		turn ("right")
		if turtle.detect() == false then
			needsBroken = true
			saveSettings()
			turn ("left")
			term.clear()
			term.setCursorPos (1, 1)
			print ("Logger may not have made it home so the program was closed. Break the turtle and replace it to continue.")
			running = false
			return
		end
	elseif getSaplings == true then -- if dumpchest is off, check for a sapling chest
		turn ("left")
		if turtle.detect() == false then
			needsBroken = true
			saveSettings()
			turn ("right")
			term.clear()
			term.setCursorPos (1, 1)
			print ("Logger may not have made it home so the program was closed. Break the turtle and replace it to continue.")
			running = false
			return
		end
	end -- if somehow the tests pass, or all chests and furnace are turned off, and the turtle isn't in the right spot, then too bad.
end
	
-- SECTION: Settings Menus, used for changing variables -------------------------------------------
	
function settings() -- main settings menu
	-- display settings menu
	-- allow for selection of different setting categories
	-- some settings categories goes to their own page, some toggles
	-- menus:
	-- Turtle Name, change slots, Farm layout, Sleep Time, 
	-- Furnace (toggle), Sapling chest (toggle), Output chest (toggle)
	-- Powered Furnace (toggle), Quit Program
	if running == false then return end
	term.clear()
	box()
	term.setCursorPos (15, 1)
	write ("Settings Menu")
	term.setCursorPos (1, 13)
	write ("O---a=back, d=select, w=up, s=down ---O")
	keypress = 0
	selection = 1
	while gotosettings == true do 		-- menus start here
		if selection == 1 then 			-- Turtle Name	
			term.setCursorPos (14, 3)
			write ("*Turtle Name  ")
			if keypress == 32 then 
				changeName()
				return
			end
		else
			term.setCursorPos (14, 3)
			write (" Turtle Name ")
		end
		if selection == 2 then
			term.setCursorPos (14, 4)
			write ("*Change Slots")
			if keypress == 32 then 
				changeSlots()
				return
			end
		else
			term.setCursorPos (14, 4)
			write (" Change Slots ")
		end
		if selection == 3 then			-- Farm Layout
			term.setCursorPos (14, 5)
			write ("*Farm Layout")
			if keypress == 32 then 
				farmLayout()
				return
			end
		else
			term.setCursorPos (14, 5)
			write (" Farm Layout ")
		end
		if selection == 4 then			-- Sleep Time
			term.setCursorPos (14, 6)
			write ("*Sleep Time")
			if keypress == 32 then 
				changeSleepTime()
				return
			end
		else
			term.setCursorPos (14, 6)
			write (" Sleep Time ")
		end
		if selection == 5 then			-- Furnace (toggle)
			term.setCursorPos (14, 7)
			write ("*Furnace ("..tostring(useFurnace)..") ")
			if keypress == 32 then 
				if useFurnace == false then
					useFurnace = true
				else
					useFurnace = false
				end
				term.setCursorPos (14, 7)
				write ("*Furnace ("..tostring(useFurnace)..") ")
			end
		else
			term.setCursorPos (14, 7)
			write (" Furnace ("..tostring(useFurnace)..")  ")
		end
		if selection == 6 then			-- Powered Furnace (toggle)
			term.setCursorPos (14, 8)
			write ("*Powered Furnace ("..tostring(poweredFurnace)..") ")
			if keypress == 32 then 
				if poweredFurnace == false then
					poweredFurnace = true
				else
					poweredFurnace = false
				end
				term.setCursorPos (14, 8)
				write ("*Powered Furnace ("..tostring(poweredFurnace)..") ")
			end
		else
			term.setCursorPos (14, 8)
			write (" Powered Furnace ("..tostring(poweredFurnace)..") ")
		end		
		if selection == 7 then			-- Sapling Chest (toggle)
			term.setCursorPos (14, 9)
			write ("*Sapling Chest ("..tostring(getSaplings)..") ")
			if keypress == 32 then 
				if getSaplings == false then
					getSaplings = true
				else
					getSaplings = false
				end
				term.setCursorPos (14, 9)
				write ("*Sapling Chest ("..tostring(getSaplings)..") ")
			end
		else
			term.setCursorPos (14, 9)
			write (" Sapling Chest ("..tostring(getSaplings)..")  ")
		end
		if selection == 8 then			-- Output Chest (toggle)
			term.setCursorPos (14, 10)
			write ("*Output Chest ("..tostring(dumpStuff)..") ")
			if keypress == 32 then 
				if dumpStuff == false then
					dumpStuff = true
				else
					dumpStuff = false
				end
				term.setCursorPos (14, 10)
				write ("*Output Chest ("..tostring(dumpStuff)..") ")
			end
		else
			term.setCursorPos (14, 10)
			write (" Output Chest ("..tostring(dumpStuff)..")  ")
		end
		if selection == 9 then			-- Quit Program
			term.setCursorPos (14, 11)
			write ("*Quit Program ")
			if keypress == 32 then 
				gotosettings = false
				term.clear()
				saveSettings()
				term.clear()
				running = false
				term.clear()
				term.setCursorPos (1, 1)
				return
			end
		else
			term.setCursorPos (14, 11)
			write (" Quit Program ")
		end
		--------------------controls-----------------------
		keypress = 0
		sleep (0.2)
		event, keypress = os.pullEvent("key")
		if keypress == 17 then 			-- w key or UP on the menu
			selection = selection - 1
			if selection < 1 then
				selection = 9
			end
		elseif keypress == 31 then		-- s key or DOWN on the menu
			selection = selection + 1
			if selection > 9 then
				selection = 1
			end
		elseif keypress == 30 then		-- a key or Back on the menu
			gotosettings = false
			term.clear()
			graphics() 
			saveSettings()
			loadSettings()
			sleep(1)
			return
		end	
	end
end

function changeName() -- Change the turtles name (whatsMyName)
	term.clear()
	box()
	term.setCursorPos (15, 1)
	write ("Turtle Name")
	term.setCursorPos (5, 3)
	write ("My name is "..os.getComputerLabel())
	term.setCursorPos (5, 5)
	write ("Would you like to change it? y/n")
	sleep(0.3)
	while true do
		keypress = 0
		event, keypress = os.pullEvent("key")
		if keypress == 49 then
			settings()
			break
		elseif keypress == 21 then
			term.setCursorPos (5, 5)
			write ("What is my new name?            ")
			term.setCursorPos (5, 6)
			sleep(0.3)
			whatsMyName = read ()
			os.setComputerLabel(whatsMyName)
			sleep(1.5)
			settings()
			break
		elseif keypress == 30 then
			settings()
			break
		end
	end
end
	
function changeSlots() -- Slots for dirt, log, sapling 1 and 2, fuel 1 and 2
	term.clear()
	box()
	term.setCursorPos (15, 1)
	write ("Change Slots")
	term.setCursorPos (1, 13)
	write ("O---a=back, d=select, w=up, s=down ---O")
	selection = 1
	keypress = 0
	while true do
		term.setCursorPos (15, 3)
		
		if selection == 1 then					-- dirtSlot
			write ("*Dirt: "..dirtSlot)
			turtle.select(dirtSlot)
			if keypress == 32 then
				term.setCursorPos (10, 9)
				write ("Type new Dirt slot: ")
				sleep(0.1)
				newlong = read ()
				liltest = tonumber ( newlong )
				if type( liltest ) ~= "number" then
					term.setCursorPos (10, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (10, 10)
					write ("                        ")
				else
					dirtSlot = tonumber(newlong)
					changeSlots()
					return
				end
				term.setCursorPos (10, 9)
				write ("                        ")
			end
		else
			write (" Dirt: "..dirtSlot)
		end
		term.setCursorPos (15, 4)
		
		if selection == 2 then					-- logSlot
			write ("*Log: "..logSlot)
			turtle.select(logSlot)
			if keypress == 32 then
				term.setCursorPos (10, 9)
				write ("Type new Log Slot: ")
				sleep(0.1)
				newwide = read ()
				liltest = tonumber ( newwide )
				if type( liltest ) ~= "number" then
					term.setCursorPos (10, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (10, 10)
					write ("                        ")
				else
					logSlot = tonumber(newwide)
					changeSlots()
					return
				end
				term.setCursorPos (10, 9)
				write ("                        ")
			end
		else
			write (" Log: "..logSlot)
		end
		term.setCursorPos (15, 5)
		
		if selection == 3 then					-- saplingSlot1
			write ("*Sapling 1: "..saplingSlot1)
			turtle.select(saplingSlot1)
			if keypress == 32 then
				term.setCursorPos (10, 9)
				write ("Type new Sapling 1 slot: ")
				sleep(0.1)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (10, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (10, 10)
					write ("                        ")
				else
					saplingSlot1 = tonumber(newgap)
					changeSlots()
					return
				end
			term.setCursorPos (10, 9)
			write ("                        ")
			end
		else
			write (" Sapling 1: "..saplingSlot1)
		end
		term.setCursorPos (15, 6)
		
		if selection == 4 then					-- saplingSlot2
			write ("*Sapling 2: "..saplingSlot2)
			turtle.select(saplingSlot2)
			if keypress == 32 then
				term.setCursorPos (10, 9)
				write ("Type new Sapling 2 slot: ")
				sleep(0.1)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (10, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (10, 10)
					write ("                        ")
				else
					saplingSlot2 = tonumber(newgap)
					changeSlots()
					return
				end
			term.setCursorPos (10, 9)
			write ("                        ")
			end
		else
			write (" Sapling 2: "..saplingSlot2)
		end
		term.setCursorPos (15, 7)
		
		if selection == 5 then					-- fuelSlot1
			write ("*Fuel 1: "..fuelSlot1)
			turtle.select(fuelSlot1)
			if keypress == 32 then
				term.setCursorPos (10, 9)
				write ("Type new Fuel 1 slot: ")
				sleep(0.1)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (10, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (10, 10)
					write ("                        ")
				else
					fuelSlot1 = tonumber(newgap)
					changeSlots()
					return
				end
			term.setCursorPos (10, 9)
			write ("                        ")
			end
		else
			write (" Fuel 1: "..fuelSlot1)
		end
		term.setCursorPos (15, 8)
		
		if selection == 6 then					---- fuelSlot2
			write ("*Fuel 2: "..fuelSlot2)
			turtle.select(fuelSlot2)
			if keypress == 32 then
				term.setCursorPos (10, 9)
				write ("Type new Sapling 2 slot: ")
				sleep(0.1)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (10, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (10, 10)
					write ("                        ")
				else
					fuelSlot2 = tonumber(newgap)
					changeSlots()
					return
				end
			term.setCursorPos (10, 9)
			write ("                        ")
			end
		else
			write (" Fuel 2: "..fuelSlot2)
		end
		
		-- listen for keyboard input
		sleep(0.3)
		keypress = 0
		event, keypress = os.pullEvent("key")
		if keypress == 17 then 
			selection = selection - 1
			if selection < 1 then
				selection = 6
			end
		elseif keypress == 31 then
			selection = selection + 1
			if selection > 6 then
				selection = 1
			end
		elseif keypress == 30 then
			settings()
			return
		end	
		term.setCursorPos (15, 8)
		write ("                      ")
	end
end
		
function changeSleepTime() -- Change how long the turtle waits (sleepTime)
	term.clear()
	box()
	term.setCursorPos (15, 1)
	write ("Sleep Time")
	term.setCursorPos (3, 3)
	write ("I will currently sleep "..sleepTime.." seconds.")
	term.setCursorPos (3, 5)
	write ("Would you like to change that? y/n")
	sleep(0.3)
	while true do
		keypress = 0
		event, keypress = os.pullEvent("key")
		if keypress == 49 then
			settings()
			break
		elseif keypress == 21 then
			term.setCursorPos (3, 5)
			write ("How long should I sleep?          ")
			term.setCursorPos (3, 6)
			sleep(0.3)
			newTime = read ()
			liltest = tonumber ( newTime )
			if type( liltest ) ~= "number" then
				term.setCursorPos (15, 10)
				write ("I was expecting a number")
				sleep(1.5)
				term.setCursorPos (15, 10)
				write ("                        ")
				changeSleepTime()
				return
			else
				sleepTime = tonumber(newTime)
			end
			sleep(1.5)
			settings()
			break
		elseif keypress == 30 then
			settings()
			break
		end
	end
end

function farmLayout() -- Change the layout for the farm
	-- graphical setup
	term.clear()
	box()
	line(13)
	selection = 1
	keypress = 0
	-- show demonstration
	term.setCursorPos (15, 1)
	write ("Farm Layout")
	term.setCursorPos (1, 13)
	write ("O---a=back, d=select, w=up, s=down ---O")
	term.setCursorPos (4, 3)	
	write ("Width")
	term.setCursorPos (3, 4)
	write ("T  T  T")
	term.setCursorPos (3, 5)	
	write ("T  T  T") -- last char is on 10, 4
	term.setCursorPos (3, 6)	
	write ("T  T  T")
	term.setCursorPos (3, 7)	
	write ("T  T  T")
	term.setCursorPos (3, 8)	
	write ("T  T  T")
	term.setCursorPos (3, 9)	
	write ("@")
	term.setCursorPos (3, 10)	
	write ("^ Turtle") 
	term.setCursorPos (3, 11)	
	write ("| facing") 
	term.setCursorPos (3, 12)	
	write ("| Up") 
	-- write the word length vertically
	term.setCursorPos (11, 3)
	write ("L")
	term.setCursorPos (11, 4)
	write ("e")
	term.setCursorPos (11, 5)
	write ("n")
	term.setCursorPos (11, 6)
	write ("g")
	term.setCursorPos (11, 7)
	write ("t")
	term.setCursorPos (11, 8)
	write ("h")

	while true do
		term.setCursorPos (15, 3)
		
		if selection == 1 then					-- long	
			write ("*Length: "..long)
			term.setCursorPos (15, 8)
			write ("Number of trees long")
			if keypress == 32 then
				term.setCursorPos (15, 9)
				write ("Type new Length: ")
				sleep(0.4)
				newlong = read ()
				liltest = tonumber ( newlong )
				if type( liltest ) ~= "number" then
					term.setCursorPos (15, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (15, 10)
					write ("                        ")
				elseif liltest > 0 then
					long = tonumber(newlong)
					firstRun = true
					farmLayout()
					return
				elseif liltest == 0 then
					term.setCursorPos (15, 10)
					write ("Must be more than Zero")
					sleep(1.5)
					farmLayout()
					return
				end
				term.setCursorPos (15, 10)
				write ("                        ")
			end
		else
			write (" Length: "..long)
		end

		term.setCursorPos (15, 4)
		
		if selection == 2 then					-- wide
			write ("*Width: "..wide)
			term.setCursorPos (15, 8)
			write ("Number of trees wide")
			if keypress == 32 then
				term.setCursorPos (15, 9)
				write ("Type new Width: ")
				sleep(0.4)
				newwide = read ()
				liltest = tonumber ( newwide )
				if type( liltest ) ~= "number" then
					term.setCursorPos (15, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (15, 10)
					write ("                        ")
				elseif liltest > 0 then
					wide = tonumber(newwide)
					firstRun = true
					farmLayout()
					return
				elseif liltest == 0 then
					term.setCursorPos (15, 10)
					write ("Must be more than Zero")
					sleep(1.5)
					farmLayout()
					return
				end
				term.setCursorPos (15, 9)
				write ("                        ")
			end
		else
			write (" Width: "..wide)
		end

		term.setCursorPos (15, 5)
		
		if selection == 3 then					-- saplingGap/Tree Gap
			write ("*Tree Gap: "..saplingGap)
			term.setCursorPos (15, 8)
			write ("Blocks between Trees")
			if keypress == 32 then
				term.setCursorPos (15, 9)
				write ("Type new Gap size: ")
				sleep(0.4)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (15, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (15, 10)
					write ("                        ")
				else
					saplingGap = tonumber(newgap)
					farmLayout()
					return
				end
			term.setCursorPos (15, 9)
			write ("                        ")
			end
		else
			write (" Tree Gap: "..saplingGap)
		end
		term.setCursorPos (15, 6)
		
		if selection == 4 then					-- wallGap/ Turtle Gap
			write ("*Turtle Gap: "..wallGap)
			term.setCursorPos (15, 8)
			write ("Distance to First tree")
			if keypress == 32 then
				term.setCursorPos (15, 9)
				write ("Type new Gap size: ")
				sleep(0.1)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (15, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (15, 10)
					write ("                        ")
				elseif liltest > 0 then
					wallGap = tonumber(newgap)
					farmLayout()
					return
				elseif liltest == 0 then
					term.setCursorPos (15, 10)
					write ("Must be more than Zero")
					sleep(1.5)
					farmLayout()
					return
				end
			term.setCursorPos (15, 9)
			write ("                        ")
			end
		else
			write (" Turtle Gap: "..wallGap)
		end
		-- rowOffset
		term.setCursorPos (15, 7)
		
		if selection == 5 then					-- rowOffset
			write ("*Row Offset: "..rowOffset)
			term.setCursorPos (15, 8)
			write ("Move first row")
			term.setCursorPos (15, 9)
			write ("left with positive num")
			term.setCursorPos (15, 10)
			write ("right with negative num")
			if keypress == 32 then
				term.setCursorPos (15, 11)
				write ("Type new Row Offset: ")
				sleep(0.1)
				newgap = read ()
				liltest = tonumber ( newgap )
				if type( liltest ) ~= "number" then
					term.setCursorPos (15, 10)
					write ("I was expecting a number")
					sleep(1.5)
					term.setCursorPos (15, 10)
					write ("                        ")
				else
					rowOffset = tonumber(newgap)
					farmLayout()
					return
				end
			term.setCursorPos (15, 11)
			write ("                        ")
			end
		else
			write (" Row Offset: "..rowOffset)
		end
		
		-- listen for keyboard input
		sleep(0.4)
		keypress = 0
		event, keypress = os.pullEvent("key")
		if keypress == 17 then 
			selection = selection - 1
			if selection < 1 then
				selection = 5
			end
		elseif keypress == 31 then
			selection = selection + 1
			if selection > 5 then
				selection = 1
			end
		elseif keypress == 30 then
			sleepTime = baseTime - ((long * wide) * 5)
			if sleepTime < 60 then
				sleepTime = 60
			end
			settings()
			return
		end	
		term.setCursorPos (15, 8)
		write ("                      ")
		term.setCursorPos (15, 9)
		write ("                      ")
		term.setCursorPos (15, 10)
		write ("                      ")
	end
end

function startup() -- Get inital lengh and width on first startup
	term.clear()
	term.setCursorPos (1, 1)
	print ("")
	print ("W I D E")
	print ("T  T  T  L")
	print ("T  T  T  O")
	print ("T  T  T  N")
	print ("T  T  T  G")
	print ("@  <-- Turtle facing Up")
	print ("")
	print ("How many trees Long?")
	long = read ()
	liltesta = tonumber ( long )
	if type( liltesta ) ~= "number" then
		print ("I was expecting a number...")
		print ("Lets try that again.")
		sleep(2)
		startup()
		return
	end
	print ("How many trees Wide?")
	wide = read ()
	liltestb = tonumber ( wide )
	if type( liltestb ) ~= "number" then
		print ("I was expecting a number...")
		print ("Lets try that again.")
		sleep(2)
		startup()
		return
	end
	sleep (1)
	if liltesta == 0 then long = 1 end
	if liltestb == 0 then wide = 1 end
	while ((wide + long) * saplingGap) > minFuel do
		minFuel = minFuel + 50
	end
	sleepTime = baseTime - ((long * wide) * 5)
	if sleepTime < 60 then
		sleepTime = 60
	end
end

-- SECTION: Graphics ------------------------------------------------------------------------------

function box() -- 39x12 box used in some menus
	term.setCursorPos (1, 1)
	write ("O-------------------------------------O")
	for i = 2, 12 do
		term.setCursorPos (1, i)
		clearLine()
	end
	term.setCursorPos (1, 13)
	write ("O-------------------------------------O")
end

function line(char) -- 12 long vertical line used in some menus
	for i = 2, 12 do
		term.setCursorPos (char, i)
		write ("|")
	end
end

function totals() -- updates the totals on main GUI
	term.setCursorPos (3, 6) 
	write ("Tree Total: "..treeTotal)
	term.setCursorPos (24, 6)
	write ("Fuel "..turtle.getFuelLevel().."/" ..minFuel.." ")
	term.setCursorPos (5, 7)
	write ("Charcoal: "..charcoalMade)
	term.setCursorPos (5, 8)
	write ("Saplings: "..saplingsPlanted)
	term.setCursorPos (24, 8)
	write ("Farm: "..long.."x"..wide)
end

function graphics() -- displays graphics for main GUI, not run often
	term.setCursorPos (1, 1)
	write ("O----(^u^)----------------------------O")
	mylable = os.getComputerLabel()
	term.setCursorPos (15, 1)
	write (mylable)
	term.setCursorPos (1, 2)
	write ("|")
	term.setCursorPos (39, 2)
	write ("|")
	term.setCursorPos (1, 3)
	write ("|")
	term.setCursorPos (39, 3)
	write ("|")
	term.setCursorPos (1, 4)
	write ("|")
	term.setCursorPos (39, 4)
	write ("|")
	term.setCursorPos (1, 5)
	write ("O--------------------O----------------O")
	term.setCursorPos (1, 6)
	write ("|")
	term.setCursorPos (22, 6)
	write ("|")
	term.setCursorPos (39, 6)
	write ("|")
	term.setCursorPos (1, 7)
	write ("|")
	term.setCursorPos (22, 7)
	write ("O----------------O")
	term.setCursorPos (1, 8)
	write ("|")
	term.setCursorPos (22, 8)
	write ("|")
	term.setCursorPos (39, 8)
	write ("|")
	term.setCursorPos (1, 9)
	write ("O--------------------O----------------O")
	if useFurnace == true then
		term.setCursorPos (12, 11)
		write ("Furnace Above Me")
	end
	if getSaplings == true then
		term.setCursorPos (3, 12)
		write ("<--Sapling Chest") 
	end
	if dumpStuff == true then
		term.setCursorPos (22, 12)
		write ("Dropoff Chest-->")
	end
	if useFurnace == true or getSaplings == true or dumpStuff == true then
		term.setCursorPos (14, 10)
		write ("Configuration")
		term.setCursorPos (17, 13)
		write ("My Back")
	end
	totals()
end

function clearLine() -- used to clear a line at the previously set cursor postion
	local x, y = term.getCursorPos()
	write ("|                                     |")
	term.setCursorPos (1, y)
end

-- SECTION: Movement ------------------------------------------------------------------------------

function forward(value) -- moves a quantity of blocks forward even with obstructions
	for i = 1, value do
		if turtle.detect() == true then
			turtle.dig()
		end
		if facing == 1 then -- Cordinates code for movement x, z
			cordsx = cordsx + 1
		elseif facing == 2 then
			cordsz = cordsz + 1
		elseif facing == 3 then
			cordsx = cordsx - 1
		elseif facing == 4 then
			cordsz = cordsz - 1
		end
		saveCords()
		local movement = false
		while not movement do
			movement = turtle.forward ()
			if not movement and turtle.detect () then
				turtle.dig ()
			end
		end
	end
end

function up(value) -- moves up 
	for i = 1, value do
		cordsy = cordsy + 1 -- cords code for y up
		saveCords()
		local movement = false
		while not movement do
			movement = turtle.up ()
			if not movement and turtle.detectUp () then
				turtle.digUp ()
			end
		end
	end
end

function down (value) -- moves down
	for i = 1, value do
		cordsy = cordsy - 1
		saveCords()
		movement = false
		while not movement do
			movement = turtle.down ()
			if not movement and turtle.detectDown () then
				turtle.digDown ()
			end
		end
	end
end

function turn(way) -- easier turning
	if way == "left" then  				-- faces left
		facing = facing - 1
		if facing < 1 then
			facing = 4
		end
		saveCords()
		turtle.turnLeft()
	elseif way == "right" then  		-- faces right
		facing = facing + 1
		if facing > 4 then
			facing = 1
		end
		saveCords()
		turtle.turnRight()
	elseif way == "back" then   		-- turnes around
		facing = facing + 1
		if facing > 4 then
			facing = 1
		end
		saveCords()
		turtle.turnRight()
		facing = facing + 1
		if facing > 4 then
			facing = 1
		end
		saveCords()
		turtle.turnRight() 
		end	
end

-- SECTION: Resource Checking ---------------------------------------------------------------------

local function saplingTotal() -- returns curent total of saplings
	if running == false then return end
	if saplingSlot1 ~= saplingSlot2 then
		sTotal1 = turtle.getItemCount(saplingSlot1)
		sTotal2 = turtle.getItemCount(saplingSlot2)
		return sTotal1 + sTotal2
	else
		return turtle.getItemCount(saplingSlot1) + 1
	end
end

function saplings()	-- ensures the turtle has enough saplings for a logging run + 1
	if running == false then return end
	imdone = false
	term.setCursorPos (1, 4)
	clearLine()
	term.setCursorPos (1, 3)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	sapNeed = saplingTotal()
	while sapNeed-1 < (long * wide) do
		turtle.select(saplingSlot1)
		term.setCursorPos(1, 2)
		write ("| Put saplings in slot "..saplingSlot1..". Extras ")
		term.setCursorPos (1, 3)
		write ("| go into the Left chest and slot "..saplingSlot2..".")
		term.setCursorPos (1, 4)
		write ("| "..(1+(long*wide)-sapNeed).." more saplings needed...")
		sleep (0.5)
		sapNeed = saplingTotal()
	end
	imdone = true
end

function dirt() -- ensure the turtle has enough dirt
	if running == false then return end
	imdone = false
	term.setCursorPos (1, 4)
	clearLine()
	term.setCursorPos (1, 3)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	if firstRun == true then 
		if (long * wide) + 1 < 64 then
			while turtle.getItemCount(dirtSlot) < (long * wide) + 1 do
				term.setCursorPos(1, 2)
				turtle.select(dirtSlot)
				write ("| Please put dirt in slot "..dirtSlot)
				dirtplox = (long*wide) - turtle.getItemCount(dirtSlot) + 1
				term.setCursorPos(1, 3)
				write ("| "..dirtplox.." dirt needed...")
				term.setCursorPos (1, 4)
				write ("| Press any key to change settings.")
				sleep (0.5)
			end
		else
			while turtle.getItemCount(dirtSlot) < 64 do
				omgDirt = 1 +(long * wide) - 63
				term.setCursorPos(1, 2)
				turtle.select(dirtSlot)
				write ("| Please put 64 dirt in slot "..dirtSlot)
				dirtplox = (long*wide) - turtle.getItemCount(dirtSlot) + 1
				term.setCursorPos(1, 3)
				write ("| "..omgDirt.." dirt will be needed next run")
				term.setCursorPos (1, 4)
				write ("| Press any key to change settings.")
				sleep (0.5)
			end
		end
	else
		if (long * wide) + 1 < 64 then
			while turtle.getItemCount(dirtSlot) < 1 do
				term.setCursorPos(1, 2)
				turtle.select(dirtSlot)
				write ("| Please put dirt in slot "..dirtSlot)
				term.setCursorPos(1, 3)
				write ("| 1 dirt needed...")
				term.setCursorPos (1, 4)
				write ("| Press any key to change settings.")
				sleep (0.5)
			end
		else
			if omgDirt == 0 then
				while turtle.getItemCount(dirtSlot) < 1 do
					term.setCursorPos(1, 2)
					turtle.select(dirtSlot)
					write ("| Please put dirt in slot "..dirtSlot)
					term.setCursorPos(1, 3)
					write ("| 1 dirt needed...")
					term.setCursorPos (1, 4)
					write ("| Press any key to change settings.")
					sleep (0.5)
				end
			elseif omgDirt > 0 then
				if omgDirt > 64 then
					while turtle.getItemCount(dirtSlot) < 64 do -- 64 +
						omgDirt = omgDirt - 63
						term.setCursorPos(1, 2)
						turtle.select(dirtSlot)
						write ("| Please put 64 dirt in slot "..dirtSlot)
						dirtplox = (long*wide) - turtle.getItemCount(dirtSlot) + 1
						term.setCursorPos(1, 3)
						write ("| "..omgDirt.." dirt will be needed next run")
						term.setCursorPos (1, 4)
						write ("| Press any key to change settings.")
						sleep (0.5)
					end
				else
					while turtle.getItemCount(dirtSlot) < omgDirt do -- 64 or less
						term.setCursorPos(1, 2)
						turtle.select(dirtSlot)
						write ("| Please put "..omgDirt.." dirt in slot "..dirtSlot)
						dirtplox = (long*wide) - turtle.getItemCount(dirtSlot) + 1
						term.setCursorPos(1, 3)
						write ("| No more dirt will be needed next run")
						term.setCursorPos (1, 4)
						write ("| Press any key to change settings.")
						sleep (0.5)
					end
					omgDirt = 0
				end
			end
		end
	end
	imdone = true
end

function someFuel() -- ensure the turtle has fuel before leaving home
	if running == false then return end
	imdone = false
	if fuelOn == true then
		treeNumbers = ((wide * long) / 5) + 1
		fuelCheck = turtle.getItemCount(fuelSlot1) + turtle.getItemCount(fuelSlot2)
		while fuelCheck < (treeNumbers + charcoalNumber) do
			term.setCursorPos (1, 4)
			clearLine()
			term.setCursorPos (1, 3)
			clearLine()
			term.setCursorPos (1, 2)
			clearLine()
			write ("| Please put more fuel in slot "..fuelSlot1.." or "..fuelSlot2)
			term.setCursorPos (1, 3)
			write ("| I need at least "..(treeNumbers + charcoalNumber).." fuel before")
			term.setCursorPos (1, 4)
			write ("| I can go logging!")
			turtle.select(fuelSlot1)
			sleep(1)
			fuelCheck = turtle.getItemCount(fuelSlot1) + turtle.getItemCount(fuelSlot2)
		end
	end
	imdone = true
end

function refillSaplings() -- get saplings from sapling chest
	if running == false then return end
	if getSaplings == true then
		term.setCursorPos (1, 4)
		clearLine()
		term.setCursorPos (1, 3)
		clearLine()
		term.setCursorPos (1, 2)
		clearLine()
		write ("| Refilling Saplings")
		turn("left")
		checkfuelSlot2 = turtle.getItemCount(fuelSlot2)
		turtle.select(saplingSlot1)
		turtle.suck()
		turtle.select(saplingSlot2)
		turtle.suck()
		if not turtle.compareTo(saplingSlot1) then
			for cnt = 1, 16 do 
				if cnt ~= logSlot then
					if cnt ~= fuelSlot1 then
						if cnt ~= fuelSlot2 then
							if cnt ~= saplingSlot1 then
								if cnt ~= saplingSlot2 then
									if cnt ~= dirtSlot then
										turtle.transferTo(cnt, 64)
									end
								end	
							end
						end
					end
				end
			end
		end
		for cnt=1, 16 do -- picked up too many? put them back!
			if cnt ~= saplingSlot1 then
				if cnt ~= saplingSlot2 then
					if turtle.getItemCount(cnt) > 0 then
						turtle.select(cnt)
						if turtle.compareTo(saplingSlot1) then	
							turtle.drop()	
						end
					end
				end
			end
		end
		if checkfuelSlot2 < turtle.getItemCount(fuelSlot2) then
			turtle.select(fuelSlot2)
			for cnt = 1, 16 do 
				if cnt ~= logSlot then
					if cnt ~= fuelSlot1 then
						if cnt ~= fuelSlot2 then
							if cnt ~= saplingSlot1 then
								if cnt ~= saplingSlot2 then
									if cnt ~= dirtSlot then
										turtle.transferTo(cnt, 64)
									end
								end	
							end
						end
					end
				end
			end
		end
		turn("right")
	end
end	

-- SECTION: Fueling and Charcoal Making -----------------------------------------------------------
	
function fuel() -- refuels the turtle and ensures it has fuel 
	if running == false then return end
	imdone = false
	if fuelOn == true then
		term.setCursorPos (1, 4)
		clearLine()
		term.setCursorPos (1, 3)
		clearLine()
		term.setCursorPos (1, 2)
		clearLine()
		write ("| I'm checking my fuel")
		while turtle.getFuelLevel() < minFuel do 			-- compare current fuel level to the minimum 
			if turtle.getItemCount(fuelSlot1) > 1 then 		-- refuels from slot 1 if there is more than 1 fuel
				turtle.select(fuelSlot1)
				turtle.refuel(1)
			elseif turtle.getItemCount(fuelSlot2) ~= 0 then -- if slot 1 is empty, tries to fuel from slot 2
				turtle.select(fuelSlot2)
				turtle.refuel(1)
			else 											-- if there is not enough fuel, ask the player for some
				term.setCursorPos (1, 2)
				turtle.select(fuelSlot1)
				if useFurnace == false then
					write ("| Please put more fuel in slot "..fuelSlot1.." or "..fuelSlot2)
					term.setCursorPos (1, 4)
					write ("| Press any key to change settings.")
					sleep (1)
				else
					write ("| Please put more fuel in slot "..fuelSlot1)
					term.setCursorPos (1, 3)
					write ("| Reserve slot "..fuelSlot2.." for charcoal")
					term.setCursorPos (1, 4)
					write ("| Press any key to change settings.")
					sleep (1)
				end
			end	
		end
		term.setCursorPos (24, 6)
		write ("Fuel "..turtle.getFuelLevel().."/" ..minFuel.." ")
	end
	imdone = true
end

function furnaceCheck() -- checks to see if it has a furnace, but only if fuelOn is enabled and poweredFurnace is disabled
	if running == false then return end
	if fuelOn == true then
		if poweredFurnace == false then
			term.setCursorPos (1, 4)
			clearLine()
			term.setCursorPos (1, 3)
			clearLine()
			term.setCursorPos (1, 2)
			clearLine()
			write ("| Do I have a furnace?")
			if turtle.detectUp() then -- check for a furnace
				if turtle.getItemCount(fuelSlot1) > 2 then
					turtle.select(fuelSlot1)
					rememberNumber = turtle.getItemCount(fuelSlot1)
					turtle.dropUp(2)
					sleep(0.5)
					turtle.suckUp()
					if rememberNumber == turtle.getItemCount(fuelSlot1) then
						return true
					elseif rememberNumber == turtle.getItemCount(fuelSlot1)+1 then
						turtle.suckDown()
						return true
					elseif rememberNumber < turtle.getItemCount(fuelSlot1) then 
						return true
					end
				elseif turtle.getItemCount(fuelSlot2) > 2 then
					turtle.select(fuelSlot2)
					rememberNumber = turtle.getItemCount(fuelSlot2)
					turtle.dropUp(2)
					sleep(0.5)
					turtle.suckUp()
					if rememberNumber == turtle.getItemCount(fuelSlot2) then
						return true
					elseif rememberNumber == turtle.getItemCount(fuelSlot2)+1 then
						turtle.suckDown()
						return true
					elseif rememberNumber < turtle.getItemCount(fuelSlot2) then 
						return true
					end
				else
					turtle.suckDown()
					return false
				end
			end
		else return true
		end
	end
end

function makeCharcoal(anumber) -- makes specified number of charcoal in multiples of 8
	if fuelOn == true then
		if useFurnace == true then
			if furnaceCheck() == true then
				quickcheck = turtle.getItemSpace(fuelSlot1) + turtle.getItemSpace(fuelSlot2) -- adds empty space in both slots
				if quickcheck > 8 * charcoalNumber then -- if there is enough room for more fuel then make some charcoal
					term.setCursorPos (1, 4)
					clearLine()
					term.setCursorPos (1, 3)
					clearLine()
					term.setCursorPos (1, 2)
					clearLine()
					write ("| I'm making Charcoal")
					hadfuel = "false"
					if poweredFurnace == false then
						if turtle.getItemCount(fuelSlot1) > 1 + anumber then -- checks for fuel and logs, puts fuel in furnace
							if turtle.getItemCount(logSlot) > 8 * anumber then
								turtle.select(fuelSlot1)
								turtle.suckUp()
								turtle.dropUp(1 * anumber)
								turtle.suckDown() -- incase of overflow
								hadfuel = "true"
							end
						elseif turtle.getItemCount(fuelSlot2) > 1 + anumber then -- not enough in fuelSlot1, then try fuelSlot2
							if turtle.getItemCount(logSlot) > 8 * anumber then
								turtle.select(fuelSlot2)
								turtle.suckUp()
								turtle.dropUp(1 * anumber)
								turtle.suckDown() -- incase of overflow
								hadfuel = "true"
							end
						end
					end
					if poweredFurnace == true then -- assume the furnace has fuel and don't put any in
						hadfuel = "true"
					end
				forward(1)
				up(2)
				turn("back")
				forward(1)
				if turtle.getItemCount(logSlot) > 8 * anumber  and hadfuel == "true" then -- if there are enough logs and the furnace has been fueled, put in some logs
					turtle.select(logSlot)
					turtle.dropDown(8 * anumber)
					charcoalMade = charcoalMade + (8 * anumber)
					term.setCursorPos (5, 7)
					write ("Charcoal: "..charcoalMade)
				end
				turn("back") -- go back home, grabbing fuel along the way
				forward(1)
				down(1)
				turn("back")
				turtle.select(fuelSlot1) 
				turtle.suck()
				turtle.select(fuelSlot2)
				turtle.suck()
				down(1)
				forward(1)
				turn("back")
				else 
					return
				end
			end
		end
	end
end

-- SECTION: Docking and Undocking -----------------------------------------------------------------		

function undock() -- moves from docking station to first tree
	if running == false then return end
	parallel.waitForAny(dirt, wakeUp)
	if gotosettings == true then -- goes to settings first if another function wanted it to happen
		settings()
	end
	if imdone == false then -- if settings wasn't done and somehow got back here, return to the beginning of undocking
		undock()
		return
	end
	refillSaplings() -- don't leave without saplings
	parallel.waitForAny(saplings, wakeUp) 
	if gotosettings == true then 
		settings()
	end
	if imdone == false then
		undock()
		return
	end
	parallel.waitForAny(fuel, wakeUp) -- don't leave without fuel
	if gotosettings == true then
		settings()
	end
	if imdone == false then
		undock()
		return
	end
	parallel.waitForAny(someFuel, wakeUp) -- make sure you have enough too!
	if gotosettings == true then
		settings()
	end
	if imdone == false then
		undock()
		return
	end
	dropOff() -- drop off all extra inventory items
	if dumpStuff == false then -- check that there is inventry room for another run
		emptySpace = 0
		for cnt=1, 16 do
			if cnt ~= logSlot then
				if cnt ~= fuelSlot1 then
					if cnt ~= fuelSlot2 then
						if cnt ~= saplingSlot1 then
							if cnt ~= saplingSlot2 then
								if cnt ~= dirtSlot then
									turtle.select(cnt)
									emptySpace = emptySpace + turtle.getItemSpace(cnt)
								end
							end	
						end
					end
				end
			end
		end
	end
	dropFail() -- if there was not enough inventory the program will quit, happens if the output chest is full
	if running == false then return end -- something quit the program, cancel everything! 
	term.setCursorPos (1, 4)
	clearLine()
	term.setCursorPos (1, 3)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	sleep(1)
	write ("| Let's get going!")	-- start getting into position
	turtle.select(saplingSlot2)
	forward(wallGap)
	up(1)
	if rowOffset > 0 then -- move first row to the left
	turn ("left")
	forward (rowOffset)
	turn ("right")
	end
	if rowOffset < 0 then -- or move first row to the right
	adjOffset = rowOffset - (rowOffset + rowOffset)
	turn ("right")
	forward (adjOffset)
	turn ("left")
	end
	turtle.select(logSlot)
end

function redock() -- logging is done so lets get back home
	fuel()
	term.setCursorPos (1, 4)
	clearLine()
	term.setCursorPos (1, 3)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	write ("| Going Home")
	if wide % 2 == 1 then -- check to see if we are far from home or close by
		turn ("right")
		forward (1)
		turn ("right")
		forward ((long - 1) * (saplingGap + 1) + 1)
		turn ("right")
		forward (1 )
	else
		forward (1)
		turn ("right")
	end
	if ((wide - 1) * (saplingGap + 1)) >= rowOffset then -- if we are far away, move closer
	forward ((wide - 1) * (saplingGap + 1) - rowOffset)
	down(1)
	turn("left")
	else -- move to being in front of home 
	turn("back")
	forward(rowOffset)
	down(1)
	turn("right")
	end -- move the wallGap distance to home
	forward(wallGap)
	turn("back")
	fuel()
end

-- SECTION: Drop off stuff ------------------------------------------------------------------------

function dropOff() -- put stuff in the output chest
	if dumpStuff == true then
		term.setCursorPos (1, 4)
		clearLine()
		term.setCursorPos (1, 3)
		clearLine()
		term.setCursorPos (1, 2)
		clearLine()
		write ("| Dropping Off Inventory")
		turn("right")
		emptySpace = 0
		for cnt=1, 16 do -- check all slots except the designated resource slots for stuff we want to keep
			if cnt ~= logSlot then
				if cnt ~= fuelSlot1 then
					if cnt ~= fuelSlot2 then
						if cnt ~= saplingSlot1 then
							if cnt ~= saplingSlot2 then
								if cnt ~= dirtSlot then
									emptySpace = emptySpace + turtle.getItemSpace(cnt)
									if turtle.getItemCount(cnt) > 0 then
										turtle.select(cnt)
										turtle.drop()
									end
								end
							end	
						end
					end
				end
			end
		end
		turn("left")
	end
end

function dropFail() -- if inventory is full quit program
	if emptySpace < 64 then
		term.setCursorPos (1, 4)
		clearLine()
		term.setCursorPos (1, 3)
		clearLine()
		term.setCursorPos (1, 2)
		clearLine()
		write ("| Oh Noes! The dropoff chest is full!")
		sleep(2)
		running = false
		term.clear()
		term.setCursorPos (1, 2)
		write (whatsMyName.." Stopped logging")
		write ("\nbecause the output chest is Full.")
		write ("\nPlease make room in the chest")
		write ("\nand restart the program")
		term.setCursorPos (1, 6)
		return
	end
end

-- SECTION: Farming Functions ---------------------------------------------------------------------

function checkPlant() -- ensure there is a sapling and dirt where a tree is to be grown
	term.setCursorPos (1, 4)
	clearLine()
	term.setCursorPos (1, 3)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	write ("| Checking for Sapling and Dirt")
	forward(1)
	if treeCheckDown() == true then
		turtle.digDown()
	end
	turtle.select(dirtSlot)
	if turtle.compareDown() == true then
		turtle.digDown()
	end
	if turtle.detectDown() == false then
		down(1)
		if turtle.compareDown() == false then
			turtle.digDown() 
			turtle.placeDown()
		end
		up(1)
		turtle.select(saplingSlot1)
		if turtle.getItemCount(saplingSlot1) > 1 then
			turtle.placeDown()
			saplingsPlanted = saplingsPlanted + 1
			term.setCursorPos (5, 8)
			write ("Saplings: "..saplingsPlanted)
		elseif turtle.getItemCount(saplingSlot2) > 1 then
			if turtle.compareTo(saplingSlot1) then
				turtle.select(saplingSlot2)
				turtle.placeDown()
				saplingsPlanted = saplingsPlanted + 1
				term.setCursorPos (5, 8)
				write ("Saplings: "..saplingsPlanted)
			end
		end
	end
	turtle.select(logSlot)
	checkup = treeCheckUp()
	if checkup == true then
		term.setCursorPos (1, 2)
		clearLine()
		write ("| Chopping Tree")
		height = 0
		while turtle.compareUp() do
			turtle.digUp ()
			up (1)
			height = height + 1
		end
		down(height)
		treeTotal = treeTotal +1
		term.setCursorPos (3, 6)
		write ("Tree Total: "..treeTotal)
	end
end

function treeCheckUp() -- return true if turtle faces a tree
	logCount = turtle.getItemCount(logSlot)
	if logCount > 0 then
		turtle.select(logSlot)
		ret = turtle.compareUp()
		return ret
	else
		return false
	end
end

-- function treeCheck() -- return true if turtle faces a tree (NOT IN USE)
	-- logCount = turtle.getItemCount(logSlot)
	-- if logCount > 0 then
		-- turtle.select(logSlot)
		-- ret = turtle.compare()
		-- return ret
	-- else
		-- return true
	-- end
-- end

function treeCheckDown() -- return true if turtle faces a tree
	logCount = turtle.getItemCount(logSlot)
	if logCount > 0 then
		turtle.select(logSlot)
		ret = turtle.compareDown()
		return ret
	else
		return false
	end
end

-- function fellTree() -- cut down a tree
	-- term.setCursorPos (1, 4)
	-- clearLine()
	-- term.setCursorPos (1, 3)
	-- clearLine()
	-- term.setCursorPos (1, 2)
	-- clearLine()
	-- write ("| Chopping Tree")
	-- turtle.select(logSlot)
	-- turtle.dig()
	-- forward(1)
	-- turtle.digDown ()
	-- down(1)
	-- turtle.select(dirtSlot)
	-- if not turtle.compareDown() then 
		-- turtle.digDown() 
		-- turtle.placeDown()
	-- end
	-- up (1)
	-- turtle.select(saplingSlot1)
	-- if turtle.getItemCount(saplingSlot1) > 1 then
		-- turtle.placeDown()
		-- saplingsPlanted = saplingsPlanted + 1
		-- term.setCursorPos (5, 8)
		-- write ("Saplings: "..saplingsPlanted)
	-- elseif turtle.getItemCount(saplingSlot2) > 1 then
		-- if turtle.compareTo(saplingSlot1) then
			-- turtle.select(saplingSlot2)
			-- turtle.placeDown()
			-- saplingsPlanted = saplingsPlanted + 1
			-- term.setCursorPos (5, 8)
			-- write ("Saplings: "..saplingsPlanted)
		-- end
	-- end	
	-- turtle.select(logSlot)
	-- height = 0
	-- while turtle.compareUp() do
		-- turtle.digUp ()
		-- up (1)
		-- height = height + 1
	-- end
	-- down(height)
	-- treeTotal = treeTotal +1
	-- term.setCursorPos (3, 6)
	-- write ("Tree Total: "..treeTotal)
-- end

function logging() -- MAIN FARMING FUNCTION, calls checkPlant(), treeCheck(), fellTree(), and moves tree to tree
	undock()
	if running == false then return end
	turnleftnow = 0
	for countWide=1, wide do
		for countLong=1, long do -- loop for each tree
			fuel()
			turtle.select(logSlot)
			-- treeTest = treeCheck()
			-- if treeTest == true then
				-- fellTree()
			-- else
				checkPlant()
			-- end
			if countLong ~= long then
				turtle.select(saplingSlot1)
				forward(saplingGap)
				term.setCursorPos (1, 4)
				clearLine()
				term.setCursorPos (1, 3)
				clearLine()
				term.setCursorPos (1, 2)
				clearLine()
				write ("| Moving to next tree")
			end
		end
		term.setCursorPos (1, 4)
		clearLine()
		term.setCursorPos (1, 3)
		clearLine()
		term.setCursorPos (1, 2)
		clearLine()
		write ("| Moving to next row") 
		if countWide < wide then -- loop for moving to next row of trees
			forward(1)
			if turnleftnow == 1 then
				turn("left")
				forward(saplingGap + 1)
				turn("left")
				turnleftnow = 0
			else
				turn("right")
				forward(saplingGap + 1)
				turn("right")
				turnleftnow = 1
			end
		end
	end
	redock()
end

-- SECTION: Sleeping between logging runs ---------------------------------------------------------

goodNight = function() -- Waiting between runs
	imdone = false
	term.setCursorPos (1, 4)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	term.setCursorPos (1, 3)
	clearLine()
	write ("| Press any key to change settings.")
	if sleepTime > 0 then
		while resetsleep < sleepTime do
			if running == false then break end
			term.setCursorPos (1, 2)
			write ("| Sleeping for "..sleepTime-resetsleep.." seconds...")
			sleep(1)
			resetsleep = resetsleep + 1
		end
	end
	term.setCursorPos (1, 3)
	clearLine()
	term.setCursorPos (1, 2)
	clearLine()
	resetsleep = 1
	imdone = true
end

wakeUp = function() -- inturrption by keyboard input, goes to settings menu
	sleep(1)
	os.pullEvent("char")
	gotosettings = true
end

function nowISleep() -- sets up for sleeping and inturrupting the sleep for the settings menu
	parallel.waitForAny(goodNight, wakeUp)
	if running == false then term.clear() return end
	if gotosettings == true then
		sleep(0.4)
		settings()
	end
	if imdone == false then
	nowISleep()
	end
end

-- SECTION: Misc. ---------------------------------------------------------------------------------

function fuelSettingCheck() -- checks to see if the server has fuel use disabled
	if turtle.getFuelLevel() ~= "unlimited" then
		fuelOn = true
	else
		fuelOn = false
	end
end

function breakTest() -- if the turtle coulden't find its way home it will need broken before restarting itself
	if turtle.getItemCount(logSlot) == 0 then
		needsBroken = false
		saveSettings()
	end
	if needsBroken == true then
		term.clear()
		term.setCursorPos (1, 1)
		print ("Logger may not have made it home so the program was closed. Break the turtle and replace it to continue.")
		running = false
	end
end

-------------------- PROGRAM START ----------------------------------------------------------------

-- Make sure files exist
while not fs.exists ("logger.cfg") do
	os.setComputerLabel(whatsMyName)
	startup()
	saveSettings()
	saveCords()
end

while not fs.exists ("loggercords.dat") do
	saveCords()
end

-- Load settings and start initial graphical setup
term.clear()
gotosettings = false
imdone = true
loadSettings()
graphics() -- renders the GUI
fuelSettingCheck() -- checks for unlimeted fuel setting 
running = true

-- Checks cordinates and goes back to starting position if out in the field
loadCords()
if homeCheck() == false then
	goHome()
end
breakTest()

-- Start main loop
while running == true do 
	logging()
	if running == false then break end
	firstRun = false
	makeCharcoal(charcoalNumber)
	saveSettings()
	resetsleep = 1
	nowISleep()
	if running == false then break end
end
