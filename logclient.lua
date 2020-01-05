local lt = love.thread
local serpent = require "serpent"

local logclient = {}
local logclientDummy = {}
logclient.__index = logclient

function logclient.new(host, port)
    local threadcode = "threadcode.lua"
    local self = {
        host = host,
        port = port,
        clientThread = lt.newThread("logthread.lua"),
        chan = lt.getChannel("clientlog"),
    }
    setmetatable(self, logclient)
    self.chan:push(host) self.chan:push(port)
    self.clientThread:start()
    return self
end

function logclient.newDummy()
    logclient.__index = logclientDummy
    return setmetatable({}, logclient)
end

function logclient:write(msg)
    --print("logclient:write")
    --print("object type", type(obj))
    self.chan:push({cmd = "write", msg = msg})
end

function logclientDummy:write(obj)
end

function logclient:quit()
    self.chan:push({cmd = "closethread"})
end

return { new = logclient.new }
