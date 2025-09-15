-- Ship controllers And Rotation
while true do
    m = ship.getMass()
    if redstone.getInput("left") then
        ship.applyRotDependentTorque(0, -200 * m, 0)
    end
    if redstone.getInput("right") then
        ship.applyRotDependentTorque(0, 200 * m, 0)
    end
    if redstone.getInput("back") then
        ship.applyRotDependentForce(0, 0, 2 * 5 * m)
    end
    if redstone.getInput("front") then
        ship.applyRotDependentForce(0, 0, -2 * 5 * m)
    end
    if redstone.getInput("top") then
        ship.applyRotDependentForce(0, 3 * 5 * m, 0)
    end
    sleep(0)
end
