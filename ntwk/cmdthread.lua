local lf = love.filesystem
print("cmd thread start")

local chan = love.thread.getChannel("cmd")
local inspect = require "inspect"
local serpent = require "serpent"
local socket = require "socket"

function processArchiveList(conn)
    local files = lf.getDirectoryItems("archives")
    print("files", inspect(files))
    local listStr = string.format("\"%s\"", table.concat(files, " ")) .. "\n"
    print("listStr", listStr)
    local send, err, last = conn:send(listStr)
    print("send", send, "err", err, "last", last)
end

function processPushFile(conn)
    print("processPushFile")
    local data, err, partial = conn:receive("*l")
    local fname, filesizeStr = string.match(data, "(.+) (.+)")
    print("fname", fname, "filesizeStr", filesizeStr)
    print("filesize", filesizeStr, "err", err, "partial", partial)
    local filesize = tonumber(filesizeStr)
    if not filesize then 
        error("filesize is nil. Something gone wrong.")
    end
    print(filesize)
    local send, err, last = conn:send("ready\n")
    local data, err, partial = conn:receive(filesize)
    if not data then
        error(string.format("Nothing to write %s", err))
    end
    if #data ~= filesize then
        print(string.format("strange things #data = %d, filesize = %d", #data,
            filesize))
    end
    local succ = lf.createDirectory("archives")
    local succ, msg = lf.write("archives/" .. fname, data, #data)
    if not succ then
        print(string.format("write file error %s", msg))
    end
end

function processSetArchive(conn)
    print("processSetArchive")
    local archivename, err, partial = conn:receive("*l")
    print("archivename", archivename)
    chan:push({ "mount_please", archivename })
end

local actions = { 
    list = processArchiveList,
    push = processPushFile,
    set = processSetArchive,
}

local host, port = chan:pop(), chan:pop()
print("cmd host", host, "port", port)

local conn = socket.tcp()
--conn:setoption("keepalive", true)
local ok, msg, tmsg
local finish = false

--conn:settimeout(0.1)
--conn:settimeout(10)

local ok, errmsg

function connect()
    --if conn then conn:close() end
    conn = nil
    conn = socket.tcp()
    repeat
        ok, errmsg = conn:connect(host, port)
        socket.sleep(0.1)
    until ok
    print("ok", ok, "errmsg", errmsg)
end

repeat
    if not ok then
        connect()
    end

    local msg = chan:peek()
    if type(msg) == "string" and msg == "$closethread$" then 
        chan:pop()
        break 
        --return
    else
        print("msg", msg)
    end

    if ok then
        local data, err, partial = conn:receive("*l")
        print("data", data, "err", err, "partial", partial)
        if err == "closed" then
            print("err", err)
            ok = nil
            --conn:close()
            --connect()
        end
        local procedure = actions[data]
        if procedure then
            procedure(conn)
        --else
            --error(string.format("Unknown command %s", action))
        end
    end
until false

conn:close()

print("cmd thread finish")

