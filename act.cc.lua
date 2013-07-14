-- TODO
--   history
--   save
--   actor (rednet)
--   blueprints
--   relative coords/facing
--   return home
--   infinite loop
--   waypoints
-- mini language for making scripts smaller
-- and doing ad-hoc commands faster
--
-- look down in the handlers for all the commands
-- you can put a number afterwards to repeat a single command
-- you can put parenthesis around a list and a number after that to repeat several commands
-- detect and compare will break out of parethesis
--
-- examples:
--   Chop down tree to a max height of 48
--
--   Dff(?uDuu)48d48
--
--   Here is how the commands are interpreted
--
--   Df   - turtle.dig()
--   f    - turtle.forward()
--   (    - for i = 1, 48 do
--     ?u -   if not turtle.detectUp() then break end
--     Du -   turtle.digUp()
--     u  -   turtle.up()
--   ) 48 - end
--   d 48 - for i = 1, 48 do turtle.down() end
--
-- You can use the language in other scripts like so
--
-- os.loadAPI("act")
-- act.act("f5rrf5ll")

-- act internal functions

local forward = 0
local up = 1
local down = 2
local tMove = {[forward] = turtle.forward,
               [up] = turtle.up,
               [down] = turtle.down}
local tDetect = {[forward] = turtle.detect,
                 [up] = turtle.detectUp,
                 [down] = turtle.detectDown}
local tAttack = {[forward] = turtle.attack,
                 [up] = turtle.attackUp,
                 [down] = turtle.attackDown}
local tDig = {[forward] = turtle.dig,
              [up] = turtle.digUp,
              [down] = turtle.digDown}
local tPlace = {[forward] = turtle.place,
                [up] = turtle.placeUp,
                [down] = turtle.placeDown}

local function tryDir(dir)
  while not tMove[dir]() do
    if tDetect[dir]() then
      tDig[dir]()
    else
      tAttack[dir]()
    end
  end
  return true
end

-- act turtle functions

function try()
  return tryDir(forward)
end

function tryUp()
  return tryDir(up)
end

function tryDown()
  return tryDir(down)
end

local currentSlot = 1
function select(slot)
  currentSlot = slot
  turtle.select(slot)
  return true
end

local function findSimilar()
  for s = 1, 16 do
    if s ~= currentSlot then
      turtle.select(s)
      if turtle.compareTo(currentSlot) then
        turtle.select(currentSlot)
        return s
      end
    end
  end
  turtle.select(currentSlot)
  return nil
end

local function placeDir(dir)
  if turtle.getItemCount(currentSlot) == 1 then
    local resupplySlot = findSimilar()
    if resupplySlot then
      if tPlace[dir]() then
        turtle.select(resupplySlot)
        turtle.transferTo(currentSlot, turtle.getItemCount(resupplySlot))
        turtle.select(currentSlot)
        return true
      else
        return false
      end
    else
      return tPlace[dir]()
    end
  else
    return tPlace[dir]()
  end
end

function place()
  return placeDir(forward)
end

function placeUp()
  return placeDir(up)
end

function placeDown()
  return placeDir(down)
end

-- command handlers

local tHandlers = {
    -- move
  ["f"] = turtle.forward,
  ["b"] = turtle.back,
  ["u"] = turtle.up,
  ["d"] = turtle.down,
  ["l"] = turtle.turnLeft,
  ["r"] = turtle.turnRight,
  -- others
  ["s"] = select,
  ["t"] = turtle.transfer,
  ["R"] = turtle.refuel,
  -- dig
  ["Df"] = turtle.dig,
  ["Du"] = turtle.digUp,
  ["Dd"] = turtle.digDown,
  -- attach
  ["Af"] = turtle.attack,
  ["Au"] = turtle.attackUp,
  ["Ad"] = turtle.attackDown,
  -- place
  ["Pf"] = place,
  ["Pu"] = placeUp,
  ["Pd"] = placeDown,
  -- suck
  ["Sf"] = turtle.suck,
  ["Su"] = turtle.suckUp,
  ["Sd"] = turtle.suckDown,
  -- drop (E for eject)
  ["Ef"] = turtle.drop,
  ["Eu"] = turtle.dropUp,
  ["Ed"] = turtle.dropDown,
  -- try, dig routing with anti-gravel/sand and anti-mob logic
  ["Tf"] = try,
  ["Tu"] = tryUp,
  ["Td"] = tryDown,
  -- detect
  ["?f"] = turtle.detect,
  ["?u"] = turtle.detectUp,
  ["?d"] = turtle.detectDown,
  -- compare
  ["=f"] = turtle.compare,
  ["=u"] = turtle.compareUp,
  ["=d"] = turtle.compareDown,
  ["=="] = turtle.compareTo,

  ["z"] = sleep
}

function getNumber(s, pos, max, default)
  if tonumber(s:sub(pos + 1, pos + 1)) == nil then
    return default, pos
  else
    local n = 0
    while pos <= max and tonumber(s:sub(pos + 1, pos + 1)) ~= nil do
      pos = pos + 1
      n = n * 10 + tonumber(s:sub(pos, pos))
    end
    return n, pos
  end
end

function act(plan)
  local pos = 1
  local max = plan:len()
  while pos <= max do
    local c = plan:sub(pos, pos)
    if c == "(" then
      -- read until matching )
      local p = 1
      local sub_plan = ""
      while p > 0 do
        pos = pos + 1
        if plan:sub(pos, pos) == ")" then
          p = p - 1
        elseif plan:sub(pos, pos) == "(" then
          p = p + 1
        end
        if p > 0 then
          sub_plan = sub_plan .. plan:sub(pos, pos)
        end
      end
      -- get optional count
      local n = nil
      n, pos = getNumber(plan, pos, max, 1)
      -- call recursively
      for i = 1, n, 1 do
        if not act(sub_plan, n) then
          print("sub plan failure")
          return false
        end
      end
    else
      if c == "D"
        or c == "A"
        or c == "P"
        or c == "S"
        or c == "E"
        or c == "T"
        or c == "?"
        or c == "=" then
        pos = pos + 1
        c = c .. plan:sub(pos, pos)
      end
      -- call handler
      local fn = tHandlers[c]
      if fn then
        if c == "f" or c == "b" or c == "u" or c == "d" or c == "l" or c == "r" or c == "Tf" or c == "Td" or c == "Tu" then
          -- move handlers, number defines iterations
          -- get optional count
          local n = nil
          n, pos = getNumber(plan, pos, max, 1)
          for i = 1, n, 1 do
            if not fn() then
              if turtle.getFuelLevel() == 0 then
                print("Out of fuel")
                return false -- stop entire plan
              else
                print("Blocked: " .. plan:sub(1, pos) .. " / " .. plan:sub(pos + 1))
                return false -- stop entire plan
              end
            end
          end
        elseif c:sub(1,1) == "?" or c:sub(1,1) == "=" then
          -- detect and compare, failure will only skip out of the current block
          local result = nil
          if c == "==" then
            local n = nil
            n, pos = getNumber(plan, pos, max, 1)
            result = fn(n)
          else
            result = fn()
          end
          if not result then
            return true -- stop current plan
          end
        else
          -- all other handlers, number gets passed to function
          local n = nil
          n, pos = getNumber(plan, pos, max)
          if not fn(n) then
            print("Can't perform action: " .. c)
            -- return false
          end
        end
      else
        print("Unknown command: " .. c)
        return false
      end
    end
    pos = pos + 1
  end
  return true
end
