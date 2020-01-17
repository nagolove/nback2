print("client thread start")

local chan = love.thread.getChannel("log")
local inspect = require "inspect"
local serpent = require "serpent"
local socket = require "socket"

local host, port = chan:pop(), chan:pop()
print("log host", host, "port", port)

local conn = socket.tcp()
--conn:setoption("keepalive", true)
local ok, msg, tmsg
local finish = false

conn:settimeout(0.1)

local ok, errmsg
local helloSend = false

ok, errmsg = conn:connect(host, port)

repeat
  tmsg = chan:pop()
  --print("tmsg", tmsg, type(tmsg))
  if tmsg and type(tmsg) == "string" then
      if tmsg == "$closethread$" then break end
      local size, err, last = conn:send(tmsg)
      --print("send", size, err, last)
  end
  socket.sleep(0.01)
until finish

conn:close()
logfile:close()
print("client thread finish")
