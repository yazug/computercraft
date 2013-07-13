
local _version = 0.1
local junk_slot = 4

function version()
	return _version
end

function doUp(count=1)
	local trycount=20
	while movecount < count do
		while trycount > 0 and not turtle.up() do
			trycount = trycount - 1
			turtle.select(junk_slot)
			turtle.digDown()
		end
	end
	return movecount == count
end

function wander(wander_func = NULL)
	while true do
		rnum = (math.random(1,10))
		if rnum > 5 then 
			turtle.turnLeft()
		else if rnum < 5 then
			turtle.turnRight()
		end
		for i=1, math.random(10, 30), 1 do
			if not turtle.detect() then 
				turtle.forward()
			end
		end
		if ( wander_func) then
			wander_func()
		end
		sleep(1)
	end
end

function wanderer(exec)
  local wand=true
  while wand do
    local tmp=loadstring(exec)
    parallel.waitForAny(wander, tmp)
  end
end

