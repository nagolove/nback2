print("client thread start")

local chan = love.thread.getChannel("log")
--local crc32 = require "crc32lua".crc32
local inspect = require "inspect"
local serpent = require "serpent"
local socket = require "socket"

local host, port = chan:pop(), chan:pop()
print("host", host, "port", port)

local conn = socket.tcp()
conn:setoption("keepalive", true)
local ok, msg, tmsg
local finish = false

conn:settimeout(0.1)

local ok, errmsg

--local logfile = love.filesystem.newFile("tlog.txt", "w")
--love.filesystem.write("example2.txt", "stroka")
--print("stroka")
--local str = "hihi"
--love.filesystem.write("tlog_ex.txt", str, str:len())
--if logfile then
--logfile:write("log created.\n")
--end
local helloSend = false

while not ok do
  ok, errmsg = conn:connect(host, port)
end

repeat
  local r1, r2
  if not helloSend then
    r1, r2 = conn:send("$server:hello\n")
    helloSend = true
  end

  --[[
    [while data do
    [    data, status, err = conn:receive("*l")
    [    print("data", data, "st", status, "err", err)
    [end
    ]]
  --local data, status, err = conn:receive("*l")
  local data, status, err = conn:receive()
  print("data", data, "st", status, "err", err)

  local cmd, param
  if data then
    cmd, param = string.match(data, "$client:(%a+) (.+)")
    print("cmd", cmd, "param", param)
  end

  if cmd == "push_file" then
    local _, fileSize = string.match(data, "$client:(%a+) (%d+)")
    print("fileSize", fileSize)

    r1, r2 = conn:send("$server:start_send_file\n")
    print(r1, r2)

    local t = {}
    local msg, err = conn:receive(fileSize)
    print(msg, err)

    r1, r2 = conn:send("$server:ok\n")
    print(r1, r2)
  end

  --tmsg = chan:pop()
  --if tmsg then
  --if type(tmsg) == "string" and tmsg == "closethread" then
  --finish = true
  --end
  --local cmd = tmsg["cmd"]

  --[[
    [if cmd == "closethread" then
    [    finish = true
    [elseif cmd == "write" then
    [    local serialized = serpent.dump(tmsg.msg)
    [    print(string.format("try to send %d bytes %s", #serialized, 
    [    serialized))
    [    local bytessend, err = conn:send(serialized .. "\n")
    [    print("send", bytessend, "err", err)
    [end
    ]]

  --end
  socket.sleep(0.01)
until finish

conn:close()
logfile:close()
print("client thread finish")
