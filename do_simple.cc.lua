local tArgs = { ... }
if #tArgs < 1 then
    print( "Usage: do <command> [repeat]" )
	return
end

function digladder()
  turtle.digDown()
  turtle.down()
end

local tHandlers = {
	["fd"] = turtle.forward,
	["forward"] = turtle.foreward,
	["forwards"] = turtle.foreward,
	["bk"] = turtle.back,
	["back"] = turtle.back,
	["up"] = turtle.up,
	["dn"] = turtle.down,
	["down"] = turtle.down,
	["lt"] = turtle.turnLeft,
	["left"] = turtle.turnLeft,
	["rt"] = turtle.turnRight,
	["right"] = turtle.turnRight,
	["dg"] = turtle.dig,
	["dig"] = turtle.dig,
	["dgd"] = turtle.digDown,
	["digdown"] = turtle.digDown,
	["dgu"] = turtle.digUp,
	["digup"] = turtle.digUp,
	["pl"] = turtle.place,
	["place"] = turtle.place,
	["pld"] = turtle.placeDown,
	["placedown"] = turtle.placeDown,
	["plu"] = turtle.placeUp,
	["placeup"] = turtle.placeUp,
	["sel"] = turtle.select,
	["select"] = turtle.select,
	["sk"] = turtle.suck,
	["suck"] = turtle.suck,
	["skd"] = turtle.suckDown,
	["suckdown"] = turtle.suckDown,
	["sku"] = turtle.suckUp,
	["suckup"] = turtle.suckUp,
	["dp"] = turtle.drop,
	["drop"] = turtle.drop,
	["dpd"] = turtle.dropDown,
	["dropdown"] = turtle.dropDown,
	["dpu"] = turtle.dropUp,
	["dropup"] = turtle.dropUp,
 ["rf"] = turtle.refuel,
	["refuel"] = turtle.refuel,
 ["dd"] = digladder
}

-- if Ben's "t" location tracking API is installed, use those movement commands instead.
if t and t.initLoc then
	tHandlers["fd"] = t.fd
	tHandlers["forward"] = t.fd
	tHandlers["forwards"] = t.fd
	tHandlers["bk"] = t.bk
	tHandlers["back"] = t.bk
	tHandlers["up"] = t.up
	tHandlers["dn"] = t.dn
	tHandlers["down"] = t.dn
	tHandlers["lt"] = t.lt
	tHandlers["left"] = t.lt
	tHandlers["rt"] = t.rt
	tHandlers["right"] = t.rt
end

local nArg = 1
while nArg <= #tArgs do
	local sDirection = tArgs[nArg]
	local nDistance = 1
	if nArg < #tArgs then
		local num = tonumber( tArgs[nArg + 1] )
		if num then
			nDistance = num
			nArg = nArg + 1
		end
	end
	nArg = nArg + 1

	local fnHandler = tHandlers[string.lower(sDirection)]
	if fnHandler then
		if fnHandler == turtle.select then
			if nDistance < 1 or nDistance > 16 then
				print("Invalid slot selection")
				return
			end
			fnHandler(nDistance)
		else
			while nDistance > 0 do
				if fnHandler() then
					nDistance = nDistance - 1
				elseif turtle.getFuelLevel() == 0 then
					print( "Out of fuel" )
					return
				else
					sleep(0.5)
				end
			end
		end
	else
		print( "No such direction: "..sDirection )
		print( "Try: forward, back, up, down" )
		return
	end

end
