local port1 = "888"
rednet.open("back")

function send()
    while true do
        local a = io.read()
        rednet.broadcast(a, port1)
    end
end

function receive()
    while true do
        local id, msg, prot = rednet.receive()
        print("[" .. tostring(prot) .. "] " .. tostring(msg))
    end
end

parallel.waitForAny(send, receive)
