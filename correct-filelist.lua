#!/usr/bin/env luajit

local fileName = arg[1]
print(fileName)
local fileHndlr = io.open(fileName, "r")
local content = fileHndlr:read("*a")
print(type(content))
local modified = string.gsub(content, "%./", ""):gsub("/", "\\")
fileHndlr:close()
print("---------")
local modFileName = string.gsub(fileName, "%.", "_.")
fileHndlr = io.open(modFileName, "w")
fileHndlr:write(modified)
print(modified)
