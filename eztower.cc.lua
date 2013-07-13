aArgs = {...}
local width = tonumber(aArgs[1])
local length = tonumber(aArgs[2])
local height = tonumber(aArgs[3])

local slot = 1
turtle.select(slot)

local function slotChecker()
    if turtle.getItemCount(slot) == 0 then
        slot = slot + 1
        turtle.select(slot)
        print("Switching to " .. slot)
    end
end
local function placeRow(dir)
    local distance = 0
    if dir == "length" then
        distance = length
    elseif dir == "width" then
        distance = width
    end
    for i = 1, distance, 1 do
        slotChecker()
        turtle.placeDown()
        if i < width then
            turtle.forward()
        else
            turtle.turnRight()
        end
    end
end

for j = 1, height, 1 do
    turtle.up()
    placeRow("length")
    placeRow("width")
    placeRow("length")
    placeRow("width")
end

turtle.turnLeft()
turtle.forward()

for j = 1, height, 1 do
    turtle.down()
end