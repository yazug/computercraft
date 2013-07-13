local args = {...}
help = args[1]


function checkBlock(cmp, dig)
  local got = false
  for i=1,8 do
    turtle.select(i)
    if(cmp()) then
      if(dig) then
        got = dig()
      else
        got = true
    end
  end
  return got
end


if help == "help" then
  print("==== Obsidian Miner v1.3 ====")
  print("By Zach Dyer")
  print("Just relax let Obsidian Miner mine that pesky obsidian for you.")
  print(" ")
  print("USAGE: ")
  print("1. Place obsidian in the first slot.")
  print(" ")
  print("2. Set turtle by any corner of an obsidian vein and type 'obsidian'")
  
else
  
  local done = false
  local tries = 0

  if(checkBlock(turtle.compare, null))
  then
    done = true
    print("Please add desired block(s) to slots 1 to 8")
  end

  while done == false do 
    checkBlock(turtle.compareDown,turtle.digDown)
    checkBlock(turtle.compareUp, turtle.digUp)
    if(checkBlock(turtle.compare, turtle.dig)) then
      turtle.forward()
      turtle.turnRight()
      tries = 0
    else
      turtle.turnLeft()
      tries = tries + 1
      if tries == 5 then
        turtle.back()
      end
      if tries > 8 then 
        done = true
      end
      
    end
  
  end
  turtle.select(1)
end