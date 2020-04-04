local resume = coroutine.resume

local CoroProcessor = {}
CoroProcessor.__index = CoroProcessor

function CoroProcessor.new()
    local self = setmetatable({}, CoroProcessor)
    self.coros = {}
    self.messages = {}
    return self
end

function CoroProcessor:sendMessage(queuename, message)
    local tbl = self.messages[queuename] 
    if tbl then
        table.insert(tbl, message)
    end
end

function CoroProcessor:push(queuename, func, ...)
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
            local msg
            if #msgs >= 1 then
                msg = msgs[1]
                table.remove(msgs, 1)
            end
            local ret
            if msg then
                ret = resume(v[1], msg)
            else
                ret = resume(v[1])
            end
            if not ret then
                table.remove(v, 1)
            end
        end
    end
end

return CoroProcessor
