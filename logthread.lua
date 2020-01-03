print("client thread start")

local chan = love.thread.getChannel("clientlog")
--local crc32 = require "crc32lua".crc32
local inspect = require "inspect"
local serpent = require "serpent"
local socket = require "socket"

local host, port = chan:pop(), chan:pop()
print("host", host, "port", port)

local conn = socket.tcp()
local ok, msg, tmsg
local finish = false

ok, errmsg = conn:connect(host, port)

if not ok then
    print("Connection error", errmsg)
    return
else
    print("connected")
end

repeat
    tmsg = chan:pop()
    if tmsg then
        --if type(tmsg) == "string" and tmsg == "closethread" then
        --finish = true
        --end

        local serialized = serpent.dump(tmsg)
        print(string.format("try to send %d bytes %s", #serialized, 
        serialized))
        local bytessend, err = conn:send(serialized .. "\n")
        print("send", bytessend, "err", err)
        --socket.sleep(0.02)
    end
until finish

conn:close()

print("client thread finish")
