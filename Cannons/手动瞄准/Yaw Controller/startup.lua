-- Yaw Controller
local gear = peripheral.find("Create_RotationSpeedController")

gear.setTargetSpeed(0)
while true do
    if redstone.getInput("left") then
        gear.setTargetSpeed(-12)
    elseif redstone.getInput("right") then
        gear.setTargetSpeed(12)
    else
        gear.setTargetSpeed(0)
    end
    sleep(0)
end
