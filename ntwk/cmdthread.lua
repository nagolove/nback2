local lf = love.filesystem
function getArchivesList()
    local savedir = lf.getSaveDirectory()
    print("savedir", savedir)
    local files = lf.getDirectoryItems(savedir)
    return table.concat(files, " ")
end

print("cmd thread start")

local chan = love.thread.getChannel("cmd")
local inspect = require "inspect"
local serpent = require "serpent"
local socket = require "socket"

local host, port = chan:pop(), chan:pop()
print("cmd host", host, "port", port)

local conn = socket.tcp()
--conn:setoption("keepalive", true)
local ok, msg, tmsg
local finish = false

--conn:settimeout(0.1)
--conn:settimeout(0)

local ok, errmsg

function connect()
    ok, errmsg = conn:connect(host, port)
    print("ok", ok, "errmsg", errmsg)
end

connect()

repeat
    local msg = chan:pop()
    if msg == "$closethread$" then break end

    if ok then
        local data, err, partial = conn:receive("*l")
        print("data", data, "err", err, "partial", partial)
        if err == "closed" then
            --conn:close()
            --connect()
        end
        if data == "archiveslist" then
            local listStr = getArchivesList()
            local send, err, last = conn:send(listStr)
        end
    else
        conn:close()
        connect()
        socket.sleep(0.1)
    end

until finish

conn:close()

print("cmd thread finish")

