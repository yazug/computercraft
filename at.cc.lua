print " "
print "aTunneler 1.0.4 (at)" -- short for "Andre's Tunneler"
print " "
--
-- Written by Andre L Noel
-- Creative Commons Attribution 3.0 Unported License.
-- http://creativecommons.org/licenses/by/3.0/deed.en_US
-- You may use/distribute/copy/modify/create new works with this as long as credit is given where it is due.
-- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
local tArgs = { ... }

local howfar = tonumber(tArgs[1])
if howfar == nil then 
  print "Usage: "
  print "at <forward> [<height>] [<torches-every>]"
  print "*negative height disables ceiling fill"
  print "Place cobble or filler in slot 1"
  print "Place torches in slot 16"
  print "Place fuel in any other slot"
  error(" ",0)
end

local howtall = tonumber(tArgs[2])
if ( howtall == nil ) then howtall=3 end
if ( howtall < 0 ) then -- negative for no ceiling fill
  howtall = howtall * -1
  filltop = false
else
  filltop = true
end
if ( howtall < 2 ) then howtall=3 end

local torchevery = tonumber(tArgs[3])
if ( torchevery == nil ) then torchevery=8 end
if ( torchevery < 1 ) then torchevery=8 end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function invenCheck()
  -- check torches
  turtle.select(16)
  while ( turtle.getItemCount(16) < 1 ) do
    print " "
    print "More torches are needed."
    print "Please add torches to slot 16"
    print "Press Enter when done."
    x = read();
  end
  -- check filler
  turtle.select(1)
  while turtle.getItemCount(1) < 1 do
    print " "
    print "Cobblestone or other filler blocks are needed."
    print "Please add them to slot 1"
    print "Press Enter when done."
    x = read()
  end
  -- check inventory space
  freespaces = false
  while not freespaces do
    for i=2,15 do
        turtle.select(i)
      if turtle.getItemCount(i) < 1 then
        freespaces = true
        break
      end
    end
    if not freespaces then
      print " "
      print "Turtle inventory has no free slots."
      print "Please remove items except for"
      print "filler blocks in slot 1 and"
      print "torches in slot 16 and"
      print "any needed fuel such as coal."
      turtle.select(2)
      print "Press Enter when done."
      x = read()
    end
    turtle.select(1)
  end
end -- invenCheck

function fuelup()
  result = true
  while turtle.getFuelLevel() < 1 do
    result = false
    for i=2,15 do
      turtle.select(i)
      if turtle.refuel(1) then
        result = true
        break
      end
    end
    if not result then
      print " "
      print "Please add fuel such as coal."
      print "Press Enter when done."
      x = read()
    end
  end
end

function digf() -- dig forward
  invenCheck()
  while turtle.dig() do
    turtle.suck()
    turtle.suckUp()
    turtle.suckDown()
    sleep(0.3)
  end
end

function digu() -- dig up
  invenCheck()
  while turtle.digUp() do
    turtle.suckUp()
    turtle.suck()
    turtle.suckDown()
    sleep(0.3)
  end
end

function digd() -- dig down
  invenCheck()
  while turtle.digDown() do
    turtle.suckDown()
    turtle.suck()
    turtle.suckUp()
    sleep(0.3)
  end
end

function tab() -- turn around backwards
  turtle.turnLeft(); turtle.turnLeft();
end

function tfw() -- turtle move forwards
  fuelup()
  while not turtle.forward() do 
    digf()
    turtle.attack()
    turtle.attack()
  end
end

function tbw() -- turtle move backwards
  fuelup()
  while not turtle.back() do
    tab()
    digf()
    turtle.attack()
    turtle.attack()
    tab()
  end
end

function tup() -- turtle move up
  fuelup()
  while not turtle.up() do 
    digu()
    turtle.attackUp()
    turtle.attackUp()
  end
end

function tdn() -- turtle move down
  fuelup()
  while not turtle.down() do 
    digd()
    turtle.attackDown()
    turtle.attackDown()
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
print " "
print("Tunnel size : 3 wide, " .. howtall .. " tall, " .. howfar .. " long")
print("Torches every " .. torchevery)
print " "
if filltop then
  print("Estimated fuel need : " .. ((howfar*(5+howtall-1))+howfar+2) )
else
  print("Estimated fuel need : " .. ((howfar*(1+howtall-1))+howfar+2) )
end

torchspaces = torchevery -- from here to the last torch placed
print "Now working on : "
for fwsteps=1,howfar do -- main loop
  print( fwsteps .. " of " .. howfar .. " ...")
  torchspaces = torchspaces + 1
  if torchspaces > (torchevery - 1) then
    tab()
    turtle.select(16) 
    turtle.place()
    torchspaces = 0
    tab()
  end
  tfw()
  turtle.select(1) -- cobble or filler block
  turtle.placeDown()

  for tall=2,howtall do
    tup()
  end

  if filltop then
    turtle.placeUp() 
    turtle.turnLeft()
    tfw()
    turtle.placeUp() 
    tbw()
    tab()
    tfw()
    turtle.placeUp() 
    tbw() -- facing right
  else
    turtle.turnLeft()
    turtle.place() -- anti lava and water
    digf()
    tab()
    turtle.place() -- anti lava and water
    digf() -- facing right
  end  

  for tall=2,howtall do
    tdn()
    turtle.place() -- anti lava and water
    digf()
    tab()
    turtle.place() -- anti lava and water
    digf()
    tab() -- facing right
  end

  -- redundant check for gravel and dug out floor
  digf()
  tab()
  digf()
  turtle.turnRight() -- facing forward again
  digu()
  turtle.placeDown()
end -- main loop
print "Turtle done!            "

print "Going back."
tup()
for bwsteps=1,howfar do
  tbw() 
end
tdn()
print "Im back!"
