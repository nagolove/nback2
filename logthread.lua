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

conn:settimeout(0.1)
local ok, errmsg = conn:connect(host, port)

--local logfile = love.filesystem.newFile("tlog.txt", "w")
--love.filesystem.write("example2.txt", "stroka")
--print("stroka")
--local str = "hihi"
--love.filesystem.write("tlog_ex.txt", str, str:len())
--if logfile then
    --logfile:write("log created.\n")
--end

if not ok then
    print("Connection error", errmsg)
    return
else
    print("connected")
end

repeat
    if not ok then
        print("recon")
        ok, errmsg = conn:connect(host, port)
        if not ok then
            print("Connection error", errmsg)
            return
        else
            print("connected")
        end
    end

    if ok then
        local data, status, err = conn:receive("*l")
        print("data", data, "st", status, "err", err)
        --[[
           [while data do
           [    data, status, err = conn:receive("*l")
           [    print("data", data, "st", status, "err", err)
           [end
           ]]
        if data == "push_file" then
            local r1, r2 = conn:send("$logserver:get_file_size")
            print(r2, r2)
            
            local msg, err = conn:receive("*l")
            print(msg, err)

            local fileSize = string.match(msg, " (%d+)")
            print("fileSize", fileSize)

            r1, r2 = conn:send("$logserver:start_send_file")
            print(r1, r2)

            local t = {}
            local msg, err = conn:receive(fileSize)
            print(msg, err)

            r1, r2 = conn:send("$logserver:ok")
            print(r1, r2)
        end
    end

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
