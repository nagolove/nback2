local lt = love.thread
local serpent = require "serpent"

local client = {}
client.__index = client
local dummyClient = {}
dummyClient.__index = dummyClient

local modname = ...

function client.new(host, port)
    local self = {
        host = host,
        port = port,
        -- поток логирования выполняет только одну задачу - передает
        -- содержимое через метод write по сети на сервер для вывода.
        logThread = lt.newThread(modname .. "/logthread.lua"),
        -- командный поток - передает файлы через сеть, передает команды -
        -- показать список файлов, установить новый архив и тд.
        cmdThread = lt.newThread(modname .. "/cmdthread.lua"),
        logchan = lt.getChannel("log"),
        cmdchan = lt.getChannel("cmd"),
    }

    setmetatable(self, client)

    self.cmdchan:push(host) self.cmdchan:push(port)
    self.cmdThread:start()

    self.logchan:push(host) self.logchan:push(port + 1)
    self.logThread:start()

    return self
end

function client:print(...)
    local str = ""
    for i = 1, select("#", ...) do
        str = str .. tostring(select(i, ...))
    end
    print("client:print()", str)
    self.logchan:push(str .. "\n")
end

function client:quit()
    self.logchan:push("$closethread$")
    self.cmdchan:push("$closethread$")
end

---------------- dummy interface ------------------
function dummyClient:print(...)
end

function dummyClient:quit()
end

function dummyClient.new()
    return setmetatable({}, dummyClient)
end
---------------- dummy interface ------------------

return { 
    new = client.new,
    dummy = dummyClient.new,
}
