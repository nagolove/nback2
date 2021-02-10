local resume = coroutine.resume

global type CoroProcessor = record
    coros: {string:{thread}}
    messages: {string:{string}}

    new: function(): CoroProcessor
    sendMessage: function(queuename: string, message: string)
    push: function(queuename: string, func: function, ...: any)
    update: function()
end

local CoroProcessor_mt: metatable<CoroProcessor> = {
    __index = CoroProcessor
}

function CoroProcessor.new(): CoroProcessor
    local self = setmetatable({} as CoroProcessor, CoroProcessor_mt)
    self.coros = {}
    self.messages = {}
    return self
end

function CoroProcessor:sendMessage(queuename: string, message: string)
    local tbl = self.messages[queuename] 
    if tbl then
        table.insert(tbl, message)
    end
end

function CoroProcessor:push(queuename: string, func: function, ...: any)
    local q = self.coros[queuename]
    if not q then
        self.coros[queuename] = {}
        self.messages[queuename] = {}
        q = self.coros[queuename]
    end
    table.insert(q, coroutine.create(func))
    if select("#", ...) ~= 0 then
        resume(q[#q], ...)
    end
end

function CoroProcessor:update()
    for k, v in pairs(self.coros) do
        if #v >= 1 then
            local msgs = self.messages[k]
            local msg: string
            if #msgs >= 1 then
                msg = msgs[1]
                table.remove(msgs, 1)
            end
            local ret: any
            if msg then
                ret = resume(v[1], msg)
            else
                ret = resume(v[1])
            end
            if not ret then
                table.remove(v, 1)
                if v[1] then
                    resume(v[1])
                end
            end
        end
    end
end

return CoroProcessor

