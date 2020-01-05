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

local logfile = love.filesystem.newFile("tlog.txt", "w")

local str = "hihi"
love.filesystem.write("tlog_ex.txt", str, str:len())

if logfile then
    logfile:write("log created.\n")
end

repeat
    tmsg = chan:pop()
    if tmsg then
        if type(tmsg) == "string" and tmsg == "closethread" then
            finish = true
        end
        local cmd = tmsg["cmd"]

        if cmd == "closethread" then
            finish = true
        elseif cmd == "write" then
            local serialized = serpent.dump(tmsg.msg)
            print(string.format("try to send %d bytes %s", #serialized, 
            serialized))
            local bytessend, err = conn:send(serialized .. "\n")
            print("send", bytessend, "err", err)
        end

        local recv, err = conn:receive("*l")
        print(recv, err)

        if recv == "getfile" then
        end

        socket.sleep(0.02)
    end
until finish

conn:close()
logfile:close()
print("client thread finish")
