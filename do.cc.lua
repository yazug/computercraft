-- command line interfact to act api
-- you will need the act script
local tArgs = { ... }
if #tArgs ~= 1 then
    print( "Usage: do <list of commands>" )
	return
end
os.loadAPI("act")
local plan = tArgs[1]
act.act(plan)