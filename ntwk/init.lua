local lt = love.thread
local inspect = require "inspect"
local serpent = require "serpent"

local client = {}
client.__index = client
local dummyClient = {}
dummyClient.__index = dummyClient

local modname = ...

function client.new(host, port, logonly)
    local self = {
        -- поток логирования выполняет только одну задачу - передает
        -- содержимое через метод write по сети на сервер для вывода.
        logThread = lt.newThread(modname .. "/logthread.lua"),
        logchan = lt.getChannel("log"),
    }
    if not logonly then
        -- командный поток - передает файлы через сеть, передает команды -
        -- показать список файлов, установить новый архив и тд.
        self.cmdThread = lt.newThread(modname .. "/cmdthread.lua")
        self.cmdchan = lt.getChannel("cmd")
        self.cmdchan:push(host) self.cmdchan:push(port)
        self.cmdThread:start()
    end

    setmetatable(self, client)

    print("client.new()", host, port)
    self.logchan:push("isworking?")

    self.logchan:push(host) self.logchan:push(port + 1)
    self.logThread:start()

    return self
end

function client:print(...)
    local str = ""
    local n = select("#", ...)
    for i = 1, n do
        str = str .. tostring(select(i, ...))
        if i < n then
            str = str .. " "
        end
    end
    print("client:print()", str)
    self.logchan:push(str .. "\n")
end

function client:close()
    local logchan = lt.getChannel("log")
    local cmdchan = lt.getChannel("cmd")
    if logchan then logchan:push("$closethread$") end
    if cmdchan then cmdchan:push("$closethread$") end
end

function client:mountAndRun(archivename)
    local path = "archives/" .. archivename
    print("path", path)
    local succ = love.filesystem.mount(path, "/", false)
    print("succ", succ)
    if succ then
        --print("package.loaded", inspect(package.loaded.main))
        package.loaded.main = nil
        package.loaded.conf = nil
        require "main"
        local updfunc = love.update
        local quitfunc = love.quit
        love.init()
        love.update = function(dt)
            if client then
                client:update()
            end
            if updafunc then updfunc(dt) end
        end
        love.quit = function()
            if client then
                client:close()
            end
            if quitfunc then
                quitfunc()
            end
        end
        if love.load then
            love.load(arg)
        end
    end
end

-- вызывается в основном цикле love.update(). При получении команды setarchive
-- устанавливает новый исполнямый архив.
function client:update()
    local cmdchan = lt.getChannel("cmd")
    local msg = cmdchan:peek()
    if type(msg) == "table" and msg[1] == "mount_please" then
        cmdchan:pop()
        self:mountAndRun(msg[2])
    end
end
---------------- dummy interface ------------------
function dummyClient:update() end
function dummyClient:print(...) end
function dummyClient:quit() end

function dummyClient.new()
    return setmetatable({}, dummyClient)
end
---------------- dummy interface ------------------

return { 
    new = client.new,
    dummy = dummyClient.new,
}
