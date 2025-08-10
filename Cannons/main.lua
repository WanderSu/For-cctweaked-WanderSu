rednet.open("left")
local port = "888";
local remoteP = peripheral.wrap("back");
local n = 4;
local flatMain = "./disk/mainflattable.lua";
local dropMain = "./disk/maindroptable.lua";
local flatErr = "./disk/errorflattable.lua";
local dropErr = "./disk/errordroptable.lua";
local flatRange = "./disk/flatrangelimittable.lua";
local dropRange = "./disk/droprangelimittable.lua";
local DEBUG = true

local function debugPrint(msg)
    if DEBUG then print("[DEBUG] " .. tostring(msg)) end
end

function safePeripheralWrap(name)
    local ok, p = pcall(peripheral.wrap, name);
    if ok and p then return p end;
    error("Peripheral not found: " .. tostring(name));
end

function receiveNumberInput(promptMsg)
    rednet.broadcast(promptMsg, port);
    print("Waiting for " .. promptMsg .. "...");
    local _, value = rednet.receive(port);
    value = tonumber(value);
    if not value then
        print("输入无效，请重新输入数字。");
        return receiveNumberInput(promptMsg);
    end
    debugPrint(promptMsg .. " " .. tostring(value))
    return value;
end

function receiveTargetInput()
    local xtgt = receiveNumberInput("input xtgt!");
    local ztgt = receiveNumberInput("input ztgt!");
    local ytgt = receiveNumberInput("input ytgt!");
    local mode;
    repeat
        mode = receiveNumberInput("input the mode:\n 0 for flat,\n 1 for drop.");
    until mode == 0 or mode == 1;
    return xtgt, ztgt, ytgt, mode;
end

function getSelfPos()
    local selfPos = coord.getCoord();
    return selfPos.x, selfPos.y, selfPos.z;
end

function getCannonTable(filename, n)
    local C0raw = {};
    for line in io.lines(filename) do
        table.insert(C0raw, tonumber(line));
    end
    local C0 = {};
    for i = 1, 5 do
        C0[i] = C0raw[i + 5 * (n - 1)];
    end
    return C0;
end

function getRangeLimit(filename, n)
    local limit = {};
    for line in io.lines(filename) do
        table.insert(limit, tonumber(line));
    end
    local min = limit[2 * n - 1];
    local max = limit[2 * n];
    return min, max;
end

function CannonPoly(C0, C1, diff, w)
    return C0[1] * w ^ 4 + (C0[2] + diff * C1[2] / 5) * w ^ 3 + (C0[3] + diff * C1[3] / 5) * w ^ 2 +
        (C0[4] + diff * C1[4] / 5) * w + (C0[5] + diff * C1[5] / 5)
end

function calcYaw(posx, posz, xtgt, ztgt, vxtgt, vztgt, tShell)
    local yaw = math.atan2(-(xtgt - posx + (vxtgt) * tShell), (ztgt - posz + (vztgt) * tShell))
    yaw = yaw * 180 / math.pi
    if yaw < -180 then
        yaw = yaw + 360
    elseif yaw > 180 then
        yaw = yaw - 360
    end
    return yaw
end

function getFlatTarget(posx, posz, posy, xtgt, ztgt, ytgt, C0, C1, minf, maxf, selfVelocity, vxtgt, vztgt)
    local w = math.sqrt((posx - xtgt) ^ 2 + (posz - ztgt) ^ 2);
    local hdiff = ytgt - posy;
    local tShell = w ^ 1.15 / (n * 40);
    local yaw = calcYaw(posx, posz, xtgt, ztgt, vxtgt, vztgt, tShell)
    local pitch;
    if w <= minf then
        pitch = (w * CannonPoly(C0, C1, 0, minf) / minf) * (30 / (math.abs(hdiff) + 30)) +
            math.atan2(hdiff, w) * 180 / math.pi;
    elseif w > minf and w < maxf then
        pitch = CannonPoly(C0, C1, hdiff, w);
    elseif w >= maxf then
        pitch = CannonPoly(C0, C1, hdiff, maxf);
    end
    return pitch, yaw
end

function getDropTarget(posx, posz, posy, xtgt, ztgt, ytgt, C0d, C1d, C0f, C1f, minf, maxf, mind, maxd, selfVelocity,
                       vxtgt, vztgt)
    local w = math.sqrt((posx - xtgt) ^ 2 + (posz - ztgt) ^ 2);
    local hdiff = ytgt - posy;
    local tShell = w ^ 1.15 / (n * 40);
    local yaw = calcYaw(posx, posz, xtgt, ztgt, vxtgt, vztgt, tShell)
    local pitch;
    if w <= minf then
        pitch = w * CannonPoly(C0f, C1f, 0, minf) / minf + math.atan2(hdiff, w) * 180 / math.pi;
    elseif w > minf and w < mind then
        pitch = CannonPoly(C0f, C1f, hdiff, w);
    elseif w >= mind and w < maxd then
        pitch = CannonPoly(C0d, C1d, hdiff, w);
    elseif w >= maxd then
        pitch = CannonPoly(C0d, C1d, hdiff, maxd);
    end
    return pitch, yaw;
end

function calcAllAngle(posx, posz, posy, xtgt, ztgt, ytgt, C0f, C1f, C0d, C1d, minf, maxf, mind, maxd,
                      selfVelocity, vxtgt, vztgt, mode)
    local pitchAngle, yawAngle;
    if mode == 0 then
        pitchAngle, yawAngle = getFlatTarget(posx, posz, posy, xtgt, ztgt, ytgt, C0f, C1f,
            minf, maxf, selfVelocity, vxtgt, vztgt);
    elseif mode == 1 then
        pitchAngle, yawAngle = getDropTarget(posx, posz, posy, xtgt, ztgt, ytgt,
            C0d, C1d,
            C0f, C1f,
            minf, maxf,
            mind, maxd,
            selfVelocity,
            vxtgt,
            vztgt);
    end
    return pitchAngle, yawAngle;
end

function initGuns(remoteP)
    local g = {}
    local guns = remoteP.getNamesRemote()
    local gunsNum = 0
    for i = 1, #guns do
        if string.find(guns[i], "cannon_mount") ~= nil then
            gunsNum = gunsNum + 1
            g[gunsNum] = safePeripheralWrap(guns[i])
            g[gunsNum].disassemble()
            sleep(0.5);
            g[gunsNum].assemble()
        end
        local gunsID = string.format("guns ID: %s", string.sub(guns[i], -3))
        rednet.broadcast(gunsID, port)
        debugPrint("gun " .. gunsNum .. ": " .. guns[i])
    end
    rednet.broadcast(string.format("guns_number = %d", gunsNum), port)
    return g, gunsNum
end

local C0f = getCannonTable(flatMain, n)
local C1f = getCannonTable(flatErr, n)
local C0d = getCannonTable(dropMain, n)
local C1d = getCannonTable(dropErr, n)
local minf, maxf = getRangeLimit(flatRange, n);
local mind, maxd = getRangeLimit(dropRange, n);
local g, gunsNum = initGuns(remoteP)

local vxtgt, vztgt = 0, 0;
local selfVelocity = 0;

while true do
    local posx, posy, posz = getSelfPos();
    local selfYawAngle = ship.getYaw() * 180 / math.pi;
    local xtgt, ztgt, ytgt, mode = receiveTargetInput()
    local pitchAngle, yawAngle =
        calcAllAngle(posx, posz, posy+1 , xtgt, ztgt, ytgt,
            C0f, C1f, C0d, C1d,
            minf, maxf, mind, maxd,
            selfVelocity, vxtgt, vztgt, mode);
    debugPrint("pitchAngle: " .. tostring(pitchAngle) .. ", yawAngle: " .. tostring(yawAngle + selfYawAngle))
    for i = 1, gunsNum do
        g[i].setPitch(pitchAngle)
        g[i].setYaw(yawAngle + selfYawAngle)
    end
    sleep(0.5)
    for i = 1, gunsNum do
        g[i].fire()
    end
    rednet.broadcast("fired!", port)
    debugPrint("fired!")
    sleep(0.5)
    print("waiting for next command...")
    rednet.broadcast("---------------------", port)
end
