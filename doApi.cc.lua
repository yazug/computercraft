
local _version = 0.1
local junk_slot = 4

function version()
	return _version
end

function doUp()
	local trycount=20
	while trycount > 0 and not turtle.up() do
		trycount = trycount - 1
		turtle.select(junk_slot)
		turtle.digDown()
	end
end


