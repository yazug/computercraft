
local tArgs = { ... }
if #tArgs ~= 1 then
  print( "Usage: digbranch <length>" )
  return
end

local limit = tonumber( tArgs[1] )
if limit < 1 then
  print( "Tunnel length must be positive." )
  return
end

if turtle.getItemCount(2) < ( limit / 6 ) then
  print( "Add "..( turtle.getItemCount(2) - (limit / 6) ).." more torches into slot 2." )
  return
end

local collected = 0
local function collect()
  collected = collected + 1
  if math.fmod(collected, 25) == 0 then
    print( "Mined "..collected.." blocks." )
  end
end

local function tryDig()
  while turtle.detect() do
    if turtle.dig() then
      collect()
      sleep(0.5)
    else
      return false
    end
  end
  return true
end

local function tryDigUp()
  while turtle.detectUp() do
    if turtle.digUp() then
      collect()
      sleep(0.5)
    else
      return false
    end
  end
  return true
end

local function tryRefuel()
  for n=1,16 do
    if turtle.getItemCount(n) > 0 then
      turtle.select(n)
      if turtle.refuel(1) then
	turtle.select(1)
	return true
      end
    end
  end
  turtle.select(1)
  return false
end

local function refuel()
  local fuelLevel = turtle.getFuelLevel()
  if fuelLevel == "unlimited" or fuelLevel > 15 then
    return
  end
  if not tryRefuel() then
    print( "Low energy. Add more fuel to continue." )
    while not tryRefuel() do
	sleep(1)
    end
  end
  print( "Refueling." )
end

local function tryUp()
  refuel()
  while not turtle.up() do
    if turtle.detectUp() then
      if not tryDigUp() then
        return false
      end
    elseif turtle.attackUp() then
    collect()
    else
      sleep( 0.5 )
    end
  end
  return true
end

local function tryForward()
  refuel()
  while not turtle.forward() do
    if turtle.detect() then
      if not tryDig() then
        return false
      end
    elseif turtle.attack() then
      collect()
    else
      sleep( 0.5 )
    end
  end
  return true
end

local function digFailed()
  print( "Encountered an unbreakable block. Aborting Tunnel." )
end

print( "Digging a tunnel 4 blocks high, and "..limit.." blocks long. Turtle will dig and light up the bottom half first, and dig the top half on the way back to this location." )


for v=1,limit,1 do
  if not tryDig() then
    digFailed()
    break
  end
  if not tryForward() then
    digFailed()
    break
  end
  if not tryDigUp() then
    digFailed()
    break
  end
  if math.fmod(v,6) == 0 then  
    turtle.select(2)
    turtle.back()
    turtle.placeUp()
    turtle.forward()
    turtle.select(1)
  end
end
if not tryUp() then
  digFailed()
  return
end
if not tryDigUp() then
  digFailed()
  return
end
if not tryUp() then
  digFailed()
  return
end
if not tryDigUp() then
  digFailed()
  return
end
turtle.turnLeft()
turtle.turnLeft()
for v=1,limit do
  if not tryDig() then
    digFailed()
    break
  end
  if not tryForward() then
    digFailed()
    break
  end
  if not tryDigUp() then
    digFailed()
    break
  end
end
turtle.down()
turtle.down()
print( "Finished digging. Mined "..collected.." blocks." )