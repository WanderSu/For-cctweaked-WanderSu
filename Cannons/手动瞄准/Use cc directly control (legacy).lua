-- Set Yaw and Pitch of all guns with cc
local remoteP = peripheral.wrap("bottom");

function initGuns(remoteP)
    local g = {}
    local guns = remoteP.getNamesRemote()
    local gunsNum = 0
    for i = 1, #guns do
        if string.find(guns[i], "cannon_mount") ~= nil then
            gunsNum = gunsNum + 1
            _, g[gunsNum] = pcall(peripheral.wrap, guns[i]);
            g[gunsNum].disassemble()
            sleep(0.5);
            g[gunsNum].assemble()
        end
    end
    print("Find " .. gunsNum .. " guns")
    return g, gunsNum
end

local g, gunsNum = initGuns(remoteP)

local counterl = 0
local counterr = 0
local counterb = 0
local counterf = 0
local tick_degree = 0.5
local max_degreee = 3
local selfYawAngle = g[1].getYaw();
local selfPitchAngle = g[1].getPitch();
while true do
    if counterl >= 8 then
        tick_degree = math.min(tick_degree + 0.5, max_degreee)
        counterl = 4
    end
    if counterr >= 8 then
        tick_degree = math.min(tick_degree + 0.5, max_degreee)
        counterr = 4
    end
    if counterb >= 8 then
        tick_degree = math.min(tick_degree + 0.5, max_degreee)
        counterb = 4
    end
    if counterf >= 8 then
        tick_degree = math.min(tick_degree + 0.5, max_degreee)
        counterf = 4
    end

    if redstone.getInput("left") then
        if counterl == 0 then
            tick_degree = 0.5
        end
        for i = 1, gunsNum do
            g[i].setYaw(selfYawAngle - tick_degree)
        end
        counterl = counterl + 1
        counterr = 0
        counterb = 0
        counterf = 0
    elseif redstone.getInput("right") then
        if counterr == 0 then
            tick_degree = 0.5
        end
        for i = 1, gunsNum do
            g[i].setYaw(selfYawAngle + tick_degree)
        end
        counterr = counterr + 1
        counterl = 0
        counterb = 0
        counterf = 0
    elseif redstone.getInput("back") then
        if counterb == 0 then
            tick_degree = 0.5
        end
        for i = 1, gunsNum do
            g[i].setPitch(selfPitchAngle - tick_degree)
        end
        counterb = counterb + 1
        counterr = 0
        counterl = 0
        counterf = 0
    elseif redstone.getInput("front") then
        if counterf == 0 then
            tick_degree = 0.5
        end
        for i = 1, gunsNum do
            g[i].setPitch(selfPitchAngle + tick_degree)
        end
        counterf = counterf + 1
        counterr = 0
        counterb = 0
        counterl = 0
    end

    if redstone.getInput("top") then
        for i = 1, gunsNum do
            g[i].fire()
        end
    end
    selfYawAngle = g[1].getYaw();
    selfPitchAngle = g[1].getPitch();
    sleep(0)
end