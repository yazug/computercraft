--[[
		Basic Testing and dignostic tool
		by BigShinyToys
		OPEN SOURCE CODE (no rights reserved)
]]--

-- varibles
local BENCHver = 1.3
local bRunning = true
local tSideList = rs.getSides()
local iTerminalID = os.getComputerID()
local iPosq = 1
-- functions
local function menu(...) -- ver 0.1
	local sel = 1
	local list = {...}
	local offX,offY = term.getCursorPos()
	local curX,curY = term.getCursorPos()
	while true do
		if sel > #list then sel = 1 end
		if sel < 1 then sel = #list end
		for i = 1,#list do
			term.setCursorPos(offX,offY+i-1)
			if sel == i then
				print("["..list[i].."]")
			else
				print(" "..list[i].." ")
			end
		end
		while true do
			local e,e1,e2,e3,e4,e5 = os.pullEvent()
			if e == "key" then
				if e1 == 200 then -- up key
					sel = sel-1
					break
				end
				if e1 == 208 then -- down key
					sel = sel+1
					break
				end
				if e1 == 28 then
					term.setCursorPos(curX,curY)
					return list[sel],sel
				end
			end
		end
	end
end
local function openRednet()
	local listOfSides = rs.getSides()
	for i = 1,6 do
		if peripheral.isPresent(listOfSides[i]) and peripheral.getType(listOfSides[i]) == "modem" then
			rednet.open(listOfSides[i])
			return listOfSides[i]
		end
	end
end
-- apps
local function RedstoneControl()
	local e,e1,e2,e3,e4,e5
	local function expand(iInput)
		local tOutput = {}
		local check = 32768
		for i = 1,16 do
			if iInput >= check then
				tOutput[i] = 1
				iInput = iInput - check
			else
				tOutput[i] = 0
			end
			check = check/2
		end
		return tOutput
	end
	local function compact(tInput)
		local iOutput = 0
		local check = 1
		for i = 16,1,-1 do
			if tInput[i] == 1 then
				iOutput = iOutput + check
			end
			check = check*2
		end
		return iOutput
	end
	function test(sInput,offX,offY,curPos)
		term.setCursorPos(offX,offY)
		write(sInput)
		offX = offX + 7
		term.setCursorPos(offX,offY)
		local iStatusB = rs.getBundledInput(sInput)
		if peripheral.isPresent(sInput) then
			write("                     ")-- blank's out the space for the name
			term.setCursorPos(offX,offY)
			write(peripheral.getType(sInput))
		else
			local invar = expand(iStatusB)
			local text = ""
			for i = 1,#invar do
				text = text..invar[i]
			end
			write(text)
		end
		local iStatusA = rs.getBundledOutput(sInput)
		local invar = expand(iStatusA)
		term.setCursorPos(offX+17,offY)
		write(" "..tostring(rs.getInput(sInput)).." "..iStatusB.."        ")
		term.setCursorPos(offX+17,offY+1)
		write(" "..tostring(rs.getOutput(sInput)).." "..iStatusA.."        ")
		term.setCursorPos(offX,offY+1)
		
		text = ""
		for i = 1,#invar do
			text = text..invar[i]
		end
		write(text)
		term.setCursorPos(offX,offY+2)
		write("                     ")
		if curPos then
			if curPos > 16 then
				spacer = 4
			else
				spacer = 0
			end
			term.setCursorPos(offX+curPos-1+spacer,offY+2)
			write("^")
		end
	end

	local tSideList = rs.getSides()
	local curX,curY = 1,1
	local spacer = 0
	term.clear()
	term.setCursorPos(1,1)
	
	while true do
		if e == "key" then
			if e1 == 14 then -- Backspace
				return
			end
			if e1 == 200 then -- up key
				curY = curY -1
			end
			if e1 == 208 then -- down key
				curY = curY +1
			end
			if e1 == 203 then -- left key
				curX = curX -1
			end
			if e1 == 205 then -- right key
				curX = curX +1
			end
			if e1 == 28 then
				if curX == 17 then
					if rs.getOutput(tSideList[curY]) then
						rs.setOutput(tSideList[curY],false)
					else
						rs.setOutput(tSideList[curY],true)
					end
				else
					local total = expand(rs.getBundledOutput(tSideList[curY]))
					if total[curX] == 1 then
						total[curX] = 0
					else
						total[curX] = 1
					end
					rs.setBundledOutput(tSideList[curY],compact(total))
				end
			end
		end
		if curY > 6 then curY = 1 end
		if curY < 1 then curY = 6 end
		if curX > 17 then curX = 1 end
		if curX < 1 then curX = 17 end
		for o = 1,6 do
			if o == curY then
				test(tSideList[o],1,o*3-2,curX)
			else
				test(tSideList[o],1,o*3-2)
			end
		end
		e,e1,e2,e3,e4,e5 = os.pullEvent()
	end
end
local function Hardware()
	term.clear()
	term.setCursorPos(1,1)
	print("Under Construction\nPress any key to return to menu.")
	os.pullEvent("key")
	return
end
local function wifi()
	local bWiFiRun = true
	local message
	term.clear()
	term.setCursorPos(1,1)
	function readADV() -- slightly modified read function credit to dan200 for original
		term.setCursorBlink( true )

		local sLine = ""
		local nPos = 0

		local w, h = term.getSize()
		local sx, sy = term.getCursorPos()	
		local function redraw()
			local nScroll = 0
			if sx + nPos >= w then
				nScroll = (sx + nPos) - w
			end
				
			term.setCursorPos( sx, sy )
			term.write( string.rep(" ", w - sx + 1) )
			term.setCursorPos( sx, sy )
			term.write( string.sub( sLine, nScroll + 1 ) )
			term.setCursorPos( sx + nPos - nScroll, sy )
		end
		
		while true do
			local sEvent, param = os.pullEvent()
			if sEvent == "char" then
				sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
				nPos = nPos + 1
				redraw()
				
			elseif sEvent == "key" then
				if param == 28 then -- Enter
					break
					
				elseif param == 203 then -- Left
					if nPos > 0 then
						nPos = nPos - 1
						redraw()
					end
					
				elseif param == 205 then -- Right
					if nPos < string.len(sLine) then
						nPos = nPos + 1
						redraw()
					end
					
				elseif param == 14 then
					-- Backspace
					if nPos > 0 then
						sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
						nPos = nPos - 1					
						redraw()
					end
				end
			else
				redraw()
			end
		end
		term.setCursorBlink( false )
		term.setCursorPos( w + 1, sy )
		return sLine
	end

	local function writer()
		while true do
			coroutine.yield()
			writer2()
		end
	end

	function writer2()
		term.setCursorPos(1,1)
		term.clearLine()
		if stat == "to" then
			write("To  :")
		elseif stat == "mes" then
			write("Mes :")
		elseif stat == "fail" then
			write("No target specified press enter to continue.")
		end
	end

	local function send()
		while true do
			local sizX,sizY = term.getSize()
			term.setCursorPos(6,1)
			stat = "to"
			writer2()
			local id = readADV()
			if id == "exit" then
				bWiFiRun = false
				rednet.close(modemOn)
				return
			elseif id == "all" then
				id = nil
				term.setCursorPos(6,1)
				stat = "mes"
				writer2()
				message = readADV()
				rednet.send(id,message)
			elseif tonumber(id) then
				id = tonumber(id)
				term.setCursorPos(6,1)
				stat = "mes"
				writer2()
				message = readADV()
				rednet.send(id,message)
			else
				stat = "fail"
				writer2()
				os.pullEvent("key")
			end
		end
	end

	local function recive()
		local lastX,lastY = 1,2
		while true do
			term.setCursorBlink( true )
			local event = {coroutine.yield()}
			term.setCursorBlink( false )
			if event[1] == "rednet_message" then
				local sizX,sizY = term.getSize()
				term.setCursorPos(1,lastY)
				print("Frm: "..event[2].." Dist: "..event[4].."M Mes: "..event[3])
				lastX,lastY = term.getCursorPos()
			end
		end
	end

	-- moved openRednet from here
	modemOn = openRednet()
	if not modemOn then
		print("No WIFI Modem\nPress any key to return to menu.")
		os.pullEvent("key")
		return
	else
		print("Opened wifi on "..modemOn.." side")
	end

	term.clear()
	term.setCursorPos(1,1)
	local stat = nil

	local reciveHandel = coroutine.create(recive)
	local writerHandel = coroutine.create(writer)
	local sendHandel = coroutine.create(send)
	
	coroutine.resume(reciveHandel,e,e1,e2,e3,e4,e5)
	coroutine.resume(writerHandel)
	coroutine.resume(sendHandel,e,e1,e2,e3,e4,e5)
	
	while bWiFiRun do -- start a loop
		local e,e1,e2,e3,e4,e5 = os.pullEvent()
		coroutine.resume(reciveHandel,e,e1,e2,e3,e4,e5)
		coroutine.resume(writerHandel)
		coroutine.resume(sendHandel,e,e1,e2,e3,e4,e5)
	end
end
local function EventMonitor()
	term.clear()
	term.setCursorPos(1,1)
	print("press BACKSPACE key 14 to exit")
	print("Wating For Event...")
	local tEvents
	while true do
		tEvents = {os.pullEvent()}
		if tEvents[1] == "key" and tEvents[2] == 14 then
			return
		end
		for i = 1,#tEvents do
			write(tostring(tEvents[i]).." ")
		end
		write("\n")
	end
end
local function TurtleDriver()
	term.clear()
	term.setCursorPos(1,1)
	if not turtle then
		print("This is Not a Turtle \nPress any key to return")
		os.pullEvent("key")
		return
	end
	local compas = {"n","e","s","w"}
	local turX,turY,turZ = 0,0,0
	local gpsX,gpsY,gpsZ = nil , nil , nil
	local face = 1
	local slotSelX = 1
	local slotSelY = 1
	function move(ins,rep) -- low levle functions
		if not ins and not rep then
			return false,"error no move specified"
		elseif not rep then
			rep = 1
		end
		for i=1,rep do
			if ins == "U" then -- up move
				if turtle.up() then
					turZ = turZ+1
				else
					return false
				end
			end
			if ins == "D" then -- down move
				if turtle.down() then
					turZ = turZ-1
				else
					return false
				end
			end
			if ins == "L" then -- left turn
				if turtle.turnLeft() then
					face = face - 1
					if face < 1 then
						face = 4	
					end
				else
					return false
				end
			end
			if ins == "R" then -- right turn
				if turtle.turnRight() then
					face = face + 1
					if face > 4 then
						face = 1	
					end
				else
					return false
				end
			end
			if ins == "F" then -- forward move
				if turtle.forward() then
					if face == 1 then
						turY = turY+1
					end
					if face == 2 then
						turX = turX+1
					end
					if face == 3 then
						turY = turY-1
					end
					if face == 4 then
						turX = turX-1
					end
				else
					return false
				end
			end
			if ins == "B" then -- back move
				if turtle.back() then
					if face == 1 then
						turY = turY-1
					end
					if face == 2 then
						turX = turX-1
					end
					if face == 3 then
						turY = turY+1
					end
					if face == 4 then
						turX = turX+1
					end
				else
					return false
				end
			end
		end
		return true
	end
	local function reDraw()
		term.clear()
		term.setCursorPos(1,1)
		print("Compus : "..compas[face].."  Loc : X "..turX.." Y "..turY.." Z "..turZ)
		if gpsX then
			print("last GPS ping   : X "..gpsX.." Y "..gpsY.." Z "..gpsZ)
		else
			print("GPS position unknown")
		end
		term.setCursorPos(1,3)
		print("Remaning Fuel : "..turtle.getFuelLevel())
		term.setCursorPos(1,5)
		print([[Use "up down left right" keys to select slot then press "r" to refuel from slot.
Press "g" locate GPS position.
Press "b" to set Loc as GPS.
Press "h" to ajust Heading]])
	end
	reDraw()
	while true do
		local e,e1,e2,e3,e4,e5 = os.pullEvent()
		-- print(tostring(e).."-"..tostring(e1))
		if e == "key" then
			if e1 == 17 then
				move("F")
			elseif e1 == 31 then
				move("B")
			elseif e1 == 30 then
				move("L")
			elseif e1 == 32 then
				move("R")
			elseif e1 == 16 then
				move("U")
			elseif e1 == 18 then
				move("D")
			elseif e1 == 14 then -- backspace
				return
			elseif e1 == 19 then -- r
				turtle.refuel(1)
			elseif e1 == 34 then -- g
				local rednetSide = openRednet()
				if rednetSide then
					gpsX,gpsY,gpsZ = gps.locate( 2, false)
					rednet.close(rednetSide)
				else
					print("no WIFI modem connected")
				end
			elseif e1 == 35 then -- h
				face = face +1
				if face > 4 then
					face = 1	
				end
			elseif e1 == 200 then -- up turtle.select(e1-1) 	local slotSelX = 1  local slotSelY = 1
				slotSelY = slotSelY -1
				if slotSelY < 1 then
					slotSelY = 4
				end
			elseif e1 == 208 then -- down
				slotSelY = slotSelY +1
				if slotSelY > 4 then
					slotSelY = 1
				end
			elseif e1 == 203 then -- left
				slotSelX = slotSelX -1
				if slotSelX < 1 then
					slotSelX = 4
				end
			elseif e1 == 205 then -- right
				slotSelX = slotSelX +1
				if slotSelX > 4 then
					slotSelX = 1
				end
			elseif e1 == 48 then -- b
				if gpsX then
					turX,turY,turZ = gpsX,gpsY,gpsZ
				end
			end
			turtle.select(slotSelX+(slotSelY*4)-4)
		end
		reDraw()
	end
end
local function help() -- 203 left 205 right
local tHelp = {
[[This program is designed for use while testing other programs or redstone systems.

It allows you the user to change hardware settings quickly and read input from Redstone, Bundled Cable and WiFi.

Event Monitor will show what events happen. This is usefull for finding the number of a pressed key for example BackSpace is key 14.

OPEN SOURCE CODE (no rights reserved) 2012
By Big Shiny Toys ver ]]..BENCHver.."\n\nPress Backspace to return to menu.",
"section 2",
"section 3",
}
	local iPage = 1
	while true do
	term.clear()
	term.setCursorPos(1,1)
	print(tHelp[iPage])
	term.setCursorPos(10,18)
	write("- Page "..iPage.." of "..#tHelp.." -")
	local e,e1,e2 = os.pullEvent("key")
		if e == "key" then
			if e1 == 203 then -- left
				iPage = iPage - 1
			elseif e1 == 205 then -- right
				iPage = iPage + 1
			elseif e1 == 14 then -- Backspace
				return
			end
		end
		if iPage < 1 then iPage = 1 end
		if iPage > #tHelp then iPage = #tHelp end
	end
end
-- Top Loop
while bRunning do
	term.clear()
	term.setCursorPos(1,1)
	print("Welcome to BENCH ver "..BENCHver.." terminal "..iTerminalID.."\nBy Big Shiny Toys")
	term.setCursorPos(2,4)
	term.setCursorBlink(false)
	local selection = menu("Redstone","Hardware","WiFi","Event Monitor","Turtle Driver","Infomation/Help","Exit")
	if selection == "Redstone" then
		RedstoneControl()
	elseif selection == "Hardware" then
		Hardware()
	elseif selection == "WiFi" then
		wifi()
	elseif selection == "Event Monitor" then
		EventMonitor()
	elseif selection == "Turtle Driver" then
		TurtleDriver()
	elseif selection == "Infomation/Help" then
		help()
	elseif selection == "Exit" then
		bRunning = false
	end
end
term.clear()
term.setCursorPos(1,1)