-- Pitch Controller
local remoteP = peripheral.wrap("front");
local gear = peripheral.find("Create_RotationSpeedController")

gear.setTargetSpeed(0)

function InitGuns(remoteP)
    local g = {}
    local guns = remoteP.getNamesRemote()
    local gunsNum = 0
    for i = 1, #guns do
        if string.find(guns[i], "cannon_mount") ~= nil then
            gunsNum = gunsNum + 1
            _, g[gunsNum] = pcall(peripheral.wrap, guns[i]);
            g[gunsNum].disassemble()
            sleep(0.3);
            g[gunsNum].assemble()
        end
    end
    print("Find " .. gunsNum .. " guns")
    return g, gunsNum
end

local g, gunsNum = InitGuns(remoteP)

while true do
    if redstone.getInput("right") then
        gear.setTargetSpeed(20)
    elseif redstone.getInput("left") then
        gear.setTargetSpeed(-20)
    else
        gear.setTargetSpeed(0)
    end
    if redstone.getInput("back") then
        for i = 1, gunsNum do
            g[i].fire()
        end
    end
    sleep(0)
end
