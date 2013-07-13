

local c=false
local x, y, z --starting pos
local face=2 --make sure that the turtle's pointing north
local autoupdate=false --make this true if you want to autoupdate everytime 
local version=1.31
local updateID=11 --ID of terminal sending updates/commands
local armingID=11 --ID of terminal arming the mine
local disarmingID=11 --ID of disarming terminal

function version()
  return version
end

function setMineID(arming, disarming)
  armingID=arming
  disarmingID=disarming
end

function setUpdateID(a)
  updateID=a
end

function savePos()
  if not fs.isDir("/pos") then fs.makeDir("/pos") end
  local f1=io.open("/pos/posx", "w")
  local f2=io.open("/pos/posy", "w")
  local f3=io.open("/pos/posz", "w")
  local f4=io.open("/pos/face", "w")
  f1:write(x)
  f2:write(y)
  f3:write(z)
  f4:write(face)
  f1:close()
  f2:close()
  f3:close()
  f4:close()
  return true
end

function getPosF()
  local f1=io.open("pos/posx", "r")
  local f2=io.open("pos/posy", "r")
  local f3=io.open("pos/posz", "r")
  local f4=io.open("pos/face", "r")
  x=f1:read()
  y=f2:read()
  z=f3:read()
  face=f4:read()
  f1:close()
  f2:close()
  f3:close()
  f4:close()
end

function getPos()
  return x,y,z
end

function setNorth()
  face=2
end

function setPos(a, b, c, ...)
  x=a
  y=b
  z=c
  if ...~=nil then face=... end
  savePos()
  return true
end

function faceAdd(a)
  if face+a>3 then face=face+a-4 else face=face+a end
end

function faceSub(a)
  if face-a<0 then face=4-face-a else face=face-a end
end

function faceSouth()
  while face~=0 do turnLeft() end
end

function faceEast()
  while face~=1 do turnLeft() end
end

function faceNorth()
  while face~=2 do turnLeft() end
end

function faceWest()
  while face~=3 do turnLeft() end
end

function faceSet(a)
  while face~=a do turnLeft() sleep(0.2) end
end

function turnLeft()
  turtle.turnLeft()
  faceAdd(1)
  return true
end

function turnRight()
  turtle.turnRight()
  faceSub(1)
end

function rotate(angle)
  if angle>0 then
    for i=1, angle, 1 do
      turnLeft()
    end
  else
    angle=math.abs(angle)
    for i=1, angle, 1 do
      turnRight()
    end
  end
end

function getPos()
  return x, y, z
end

function getFacing()
  return face
end

function checkFace()
  print("Checking Heading and Position.")
  faceNorth()
  print("I should be facing North Now!")
  return true
end

function checkPos()
  print("Make sure I have room to move around me")
  print("I am now at ",x,y,z)
  faceNorth()
  forward(1)
  print("I should have moved 1 space North")
  print("I am now at ",x,y,z)
  return true
end

function up()
  if y~=127 then
    local state=turtle.up()
    if state then y=y+1 end
    return state
  else return false
  end
end

function down()
  if y~=1 then
    local state=turtle.down()
    if state then y=y-1 end
    return state
  else return false
  end
end

function forward(a)
  local state=true
  if face==0 then for i=1, a, 1 do state=turtle.forward() if state then z=z+1 end end end
  if face==1 then for i=1, a, 1 do state=turtle.forward() if state then x=x+1 end end end
  if face==2 then for i=1, a, 1 do state=turtle.forward() if state then z=z-1 end end end
  if face==3 then for i=1, a, 1 do state=turtle.forward() if state then x=x-1 end end end
  return state
end

function back(a)
  local state=true
  if face==2 then for i=1, a, 1 do state=turtle.forward() if state then z=z-1 end end end
  if face==3 then for i=1, a, 1 do state=turtle.forward() if state then x=x-1 end end end
  if face==0 then for i=1, a, 1 do state=turtle.forward() if state then z=z+1 end end end
  if face==1 then for i=1, a, 1 do state=turtle.forward() if state then x=x+1 end end end
  return state
end

function goToPos(a, b, c, mode)
  faceEast()
  a=a-x
  b=b-y
  c=c-z
  if a>=0 then
    for i=1, a, 1 do
      while mode and turtle.detect() do turtle.dig() sleep(0.2) end
      forward(1)
    end
  else
    a=math.abs(a)
    rotate(2)
    for i=1, a, 1 do
      while mode and turtle.detect() do turtle.dig() sleep(0.2) end
      forward(1)
    end
  end
  if b>=0 then
    for i=1, b, 1 do
      while mode and turtle.detectUp() do turtle.digUp() sleep(0.2) end
      up()
    end
  else
    b=math.abs(b)
    for i=1, b, 1 do
      while mode and turtle.detectDown() do turtle.digDown() sleep(0.2) end
      down()
    end
  end
  faceSouth()
  if c>=0 then
    for i=1, c, 1 do
      while mode and turtle.detect() do turtle.dig() sleep(0.2) end
      forward(1)
    end
  else
    c=math.abs(c)
    rotate(2)
    for i=1, c, 1 do
      while mode and turtle.detect() do turtle.dig() sleep(0.2) end
      forward(1)
    end
  end
  return true
end

function tunnel(w, h, l)
  local xs, ys, zs=getPos()
  local faces=face
  for k=1, l, 1 do
    for j=1, h, 1 do
      turnLeft()
      for i=1, w, 1 do
        turtle.dig()
        forward(1)
      end
      for i=1, w, 1 do back(1) end
      turnRight()
      if j<h then turtle.digDown() down() end
    end
    for j=1, h, 1 do if j<h then up() end end
    turtle.dig() forward(1)
  end
  goToPos(xs, ys, zs, false)
  faceSet(faces)
  return true
end

function staircase(w, h, l)
  local xs, ys, zs=getPos()
  local faces=face
  for k=1, l, 1 do
    for j=1, h, 1 do
      turnLeft()
      for i=1, w, 1 do
        turtle.dig()
        forward(1)
      end
      for i=1, w, 1 do back(1) end
      turnRight()
      if j<h then turtle.digDown() down() end
    end
    for j=1, h, 1 do up() end
    turtle.dig() forward(1)
  end
  goToPos(xs, ys, zs, false)
  faceSet(faces)
  return true
end

function wread()
  local _, y=term.getCursorPos()
  local tmp=read()
  local x, _=term.getCursorPos()
  term.setCursorPos(x,y)
  return tmp
end

function build(blueprint)
  local l=#blueprint
  local h=#blueprint[1]
  local w=#blueprint[1][1]
  local xs, ys, zs=getPos()
  local faces=face
  for k=1, l, 1 do
    for j=1, h, 1 do
      turnLeft()
      for i=1, w, 1 do
        turtle.dig()
        forward(1)
      end
      for i=1, w, 1 do 
        local block=blueprint[k][j][i]
        print(block)
        if block~=0 then turtle.select(block) turtle.place() end
        back(1) 
      end
      turnRight()
      if j<h then turtle.digDown() down() end
    end
    for j=1, h, 1 do if j<h then up() end end
    turtle.dig() forward(1)
  end
  goToPos(xs, ys, zs, false)
  faceSet(faces)
  return true
end

function sketch()
  print("Blueprint maker")
  print("Use turtle's slot IDs for data")
  print("Enter dimensions")
  write(" Width: ") local w=wread()
  write(" Height: ") local h=wread()
  write(" Length: ") local l=wread()
  local t={}
  for i=1, l, 1 do
    print("Vertical Layer ",i)
    local tt={}
    for j=1, h, 1 do
      print("Horizontal Row ", j)
      local ttt={}
      for k=1, w, 1 do
        local tmp=tonumber(wread())
        table.insert(ttt, tmp)
        write(" ")
      end
      table.insert(tt, ttt)
    end
    table.insert(t, tt)
  end
  return t
end

function getUpdate(side)
  local a,b,c=os.pullEvent()
  while a~="rednet_message" or b~=updateID do a,b,c=os.pullEvent() end
  local tmp=loadstring(c)
  tmp()
  return true
end

function getUpdateP(side)
  if peripheral.getType(side)=="disk" and fs.exists("/"..disk.getMountPath(side).."/magicTurtleUpdate/update") then
    shell.run("/"..disk.getMountPath(side).."/magicTurtleUpdate/update")
    return true
  end
  return false
end

function event()
  local a,b,c=os.pullEvent()
  if a=="rednet_message" and b==updateID and c=="update" then getUpdate(b) return true end
  if a=="peripheral" then getUpdateP(b) return true end
  return false
end

function updateSeek()
  rednet.open("right")
  local result = false
  while not result do result = event() end
  return true
end

function lua()
  while true do
    write(">")
    local com=wread() print("")
    if com=="exit" then return true end
    if com=="menu" then menu() end
    if c then break end
    local exec=loadstring(com)
    exec()
  end
end

function autoUpdate()
  autoupdate=true
  while true do
    parallel.waitForAny(lua, updateSeek)
  end
  return true
end

function isSpace()
  for i=1, 9, 1 do
    if turtle.getItemCount(i)==0 then return true end
  end
  return false
end

function diamondMine(l,...)
  local xs,ys,zs=getPos()
  local a,b,c=getPos()
  while b~=12 do
    turtle.dgDown()
    down()
    turtle.dig()
    turtle.digDown()
    forward(1)
    a,b,c=getPos()
  end
  while isSpace() do
    if ...~=nil then digSlot(...) else turtle.dig() end
    forward(1) turtle.digDown() 
    turnLeft() for i=1, l, 1 do 
    if ...~=nil then digSlot(...) else turtle.dig() end
    forward(1) end
    back(l)
    rotate(2)
    for i=1, l, 1 do 
      if ...~=nil then digSlot(...) else turtle.dig() end
      forward(1)
    end
    back(l)
  end
  goToPos(xs,ys,zs, true)
  return true
end

function mine(mode, l,...)
  if mode=="diamond" then diamondMine(l,...) end
  if mode=="regular" then tunnel(l, l, l) end
  if mode=="quarry" then quarry(l, ...) end
  return true
end

function sendCommand(id, side, exec)
  rednet.open(side)
  rednet.send(id, "update")
  local state=rednet.send(id, exec)
  return state
end

function fcoord()
  if face==0 then z=z+1 end
  if face==1 then x=x+1 end
  if face==2 then z=z-1 end
  if face==3 then x=x-1 end
end

function lookAround()
  if not turtle.forward() and rs.getInput("front") then return false end
  fcoord()
  if not rs.getInput("bottom") then
    back(1)
    turnRight()
    forward(1)
    if not rs.getInput("bottom") then
      back(2)
      rotate(2)
      if not rs.getInput("bottom") then
        back(1)
        turnRight()
        return false
      else
        return true
      end
    else
      return true
    end
  else
    return true
  end
end

function road()
  while true do
    if not lookAround() then
      up()
      if not lookAround() then
        if not turtle.forward() and not rs.getInput("bottom") then turnLeft() write(1)
          if not turtle.forward() and not rs.getInput("bottom") then rotate(2) write(2)
            if not turtle.forward() and not rs.getInput("bottom") then break
            end
          end
        end
        write(13)
        fcoord()
        down()
        down()
        if not lookAround() then up() break end
      end
    end
  end
end

function obs()
  while true do
    if turtle.detect() then
      blow=true
      write(1)
      back(1)
      turtle.select(5)
      turtle.place()
      for i=1, 5, 1 do
        write(2)
        if not turtle.detectDown() then turtle.select(1) turtle.placeDown() end
        back(1)
      end
      forward(5)
      for i=1, 5, 1 do
        back(1)
        turtle.select(6)
        turtle.place()
      end
      rs.setOutput("front", true) back(1) rs.setOutput("front", false)
      back(3)
      sleep(2.5)
      forward(9)
      blow=false
    end
    sleep(0.2)
  end
end

function blowup()
  local tmp
  local blow=false
  while true do
    print(blow)
    if not blow then tmp=loadstring(read()) else tmp=loadstring("") end
    parallel.waitForAll(tmp, obs)
  end
  return true
end

function wander()
  while true do
    if (math.random(1,10))>5 then turnLeft()
    else turnRight() end
    for i=1, math.random(10, 30), 1 do if not turtle.detect() then forward(1) end end
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

function jack(sap)
  local xs,ys,zs=getPos()
  turtle.select(sap)
  turtle.place()
  up()
  while not turtle.detect() do sleep(0.2) end
  back(2) turnRight() back(2) up() up() up() up()
  tunnel(5,5,5)
  goToPos(xs,ys,zs, true)
end

function treefarm(sap)
  while true do jack(sap) end
end

function watchUp()
  while true do
    if turtle.detectUp() then rs.setOutput("bottom", true) end
    sleep(0.5)
  end
end

function disarm()
  while true do
    local a,b,c=os.pullEventRaw()
    if a=="rednet_message" and b==disarmingID and c=="disarm" then arm=false end
    sleep(0.5)
  end
end

function landmine(slot, net)
  local arm
  while not turtle.detectDown() do down() end
  turtle.digDown() down() turtle.digDown()
  turtle.select(slot)
  turtle.placeDown()
  while true do
    if net then
      local a,b,c=os.pullEventRaw()
      while a~="rednet_message" or b~=armingID or c~="arming" do a,b,c=os.pullEventRaw() end
    end
    arm=true
    while arm do
      if net then 
        parallel.waitForAny(watchUp, disarm)
      else
        watchUp()
      end
    end
  end
  turtle.digdown()
  up()
end

function patch(slot, l, w)
  for i=1, l, 1 do
    turnLeft()
    for j=1, w, 1 do
      forward(1)
      if (turtle.getItemCount(slot))==0 then return false end
      turtle.select(slot)
      while not turtle.detectDown() do turtle.placeDown() end
    end
    back(w) turnRight() forward(1)
  end
  back(l)
end

function guardArea(exec, w, h)
  local tmp=loadstring(exec)
  while true do
    for i=1, h, 1 do
      turnLeft()
      for j=1, w, 1 do
        forward(1)
        if not turtle.detectDown() then tmp() end
        if turtle.detect() then tmp() end
      end
      back(w) turnRight() forward(1)
    end
    back(h)
  end
end

function remoteArm(id)
  return rednet.send(id, "arming")
end

function remoteDisarm(id)
  return rednet.send(id, "disarming")
end

function remoteSleep(id, t)
  remoteDisarm(id)
  sleep(t)
  remoteArm(id)
end

function cDigDown()
  local it={}
  for i=1, 9, 1 do
    table.insert(it, turtle.getItemCount(i))
  end
  turtle.digDown()
  for i=1, 9, 1 do
    if it[i]<turtle.getItemCount(i) then return i end
  end
  return false
end

function cDig()
  local it={}
  for i=1, 9, 1 do
    table.insert(it, turtle.getItemCount(i))
  end
  turtle.dig()
  for i=1, 9, 1 do
    if it[i]<(turtle.getItemCount(i)) then return i end
  end
  return false
end

function camoMine(slot)
  local slot2=cDigDown()
  down() turtle.digDown()
  turtle.select(slot) turtle.placeDown() up()
  turtle.select(slot2) turtle.placeDown()
  return true
end

function mineGrid(slot)
  for i=1, 5, 1 do
    turnRight()
    for j=1, 5, 1 do
      camoMine(slot)
      forward(3)
    end
    back(15)
    turnLeft()
    forward(3)
  end
  back(9) turnRight() forward(6) turnLeft()
end

function playerDetect()
  if not turtle.forward() and not turtle.dig() then turtle.back() return true else return false end
end

function follow()
  while not playerDetect() do
    turnRight() sleep(0.1)
  end
  forward(1)
end

function follower()
  while true do
    follow()
    sleep(0.1)
  end
end

function detectLeft()
  turnLeft()
  local a=turtle.detect()
  turnRight()
  return a
end

function detectRight()
  turnRight()
  local a=turtle.detect()
  turnLeft()
  return a
end

function detectBack()
  rotate(2)
  local a=turtle.detect()
  rotate(2)
  return a
end

function detect(side)
  if side=="top" then return turtle.detectUp() end
  if side=="bottom" then return turtle.detectDown() end
  if side=="left" then return detectLeft() end
  if side=="right" then return detectRight() end
  if side=="back" then return detectBack() end
  if side=="front" then return turtle.detect() end
  return false
end

function detectDir(f)
  local tmp=getFacing()
  faceSet(f)
  local tmp2=turtle.detect()
  faceSet(tmp)
  return tmp2
end

function path(face)
  while true do
    while detectRight() and not turtle.detect() do
      forward(1)
    end
    if detectRight() and turtle.detect() then turnLeft() end
    if not detectRight() then if not forward(1) then turnRight() end elseif not turtle.detectUp() then up() else down() end
    if not detectDir(face) then break end
  end
end

function digSlot(slot)
  local s=cDig()
  if s and s~=slot then turtle.select(s) turtle.drop() turtle.select(slot) else return false end
  return true
end

function quarry(w, l)
  local run=true
  while run and isSpace() do
    for i=1, l, 1 do
      while turtle.detect() do turtle.dig() end
      turnRight()
      for j=1, w, 1 do
        local s1=turtle.digDown() forward(1)
      end
      back(w)
      turnLeft()
      local s2=down()
    end
    if not s1 and not s2 then run=false end
  end
  return true
end

function stf(a,b)
  local f=io.open(b,"w")
  for i=1, #a,1 do
    local ai=a[i]
    local tmp2=""
    for j=1, #ai, 1 do
      local tmp=""
      for k=1, #ai[j], 1 do tmp=tmp..ai[j][k] end
      tmp=tmp.." "
      tmp2=tmp2..tmp tmp=""
    end
    f:write(tmp2) f:write("\n")
  end
  f:close()
  return true
end

function ctl(a)
  local t={}
  local tt={}
  local ttt={}
  for k=1, #a, 1 do
    tmp2=a[k]
    for i=1, #tmp2, 1 do
      local tmp=tmp2[i]
      for j=1, string.len(tmp), 1 do table.insert(ttt, string.sub(tmp, j,j)) end
      table.insert(tt,ttt) ttt={}
    end
    table.insert(t,tt) tt={}
  end
  return t
end

function stt(a)
  local t={}
  local tmp=""
  for i=1, string.len(a), 1 do
    if string.sub(a,i,i)==" " then
      table.insert(t,tmp) tmp=""
    else
      tmp=tmp..string.sub(a,i,i)
    end
  end
  if tmp~="" then table.insert(t,tmp) end
  return t
end

function tff(name)
  local tmp=io.open(name,"r")
  local n={}
  for line in tmp:lines() do
    table.insert(n,stt(line))
  end
  return ctl(n)
end

function architect(w, h, l)
  local blueprint={}
  local xs, ys, zs=getPos()
  local faces=face
  local row={}
  local layer={}
  for k=1, l, 1 do
    for j=1, h, 1 do
      turnLeft()
      for i=1, w, 1 do
        local tmp=cDig()
        if not tmp then tmp=0 end
        table.insert(row, tmp)
        forward(1)
      end
      for i=1, w, 1 do back(1) end
      turnRight()
      table.insert(layer, row) row={}
      if j<h then 
        local tmp=cDigDown() 
        if not tmp then tmp=0 end
        table.insert(row, tmp)
        down() 
      end
    end
    for j=1, h, 1 do if j<h then up() end end
    local tmp=cDig()
    if not tmp then tmp=0 end
    table.insert(row, tmp) 
    forward(1)
    table.insert(blueprint, layer) layer={}
  end
  goToPos(xs, ys, zs, false)
  faceSet(faces)
  return blueprint
end
