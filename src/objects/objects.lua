---Provides functionality to common data structures.
---
---Availability: Client and Server
---@class objects
local objects = {}

local objectsTools = require(".tools")
for k,v in pairs(objectsTools) do
    objects[k] = v
end

objects.Class = require(".Class")
objects.Set = require(".Set")
objects.Array = require(".Array")
objects.Heap = require(".Heap")
objects.Enum = require(".Enum")
objects.Color = require(".Color")
objects.Spring = require(".Color")
objects.Grid = require(".Grid")


--- Checks if a value is callable
---@param x any
---@return boolean
function objects.isCallable(x)
    if type(x) == "function" then
        return true
    end
    local mt = getmetatable(x)
    return mt and mt.__call
end


if false then
    _G.objects = objects
end

return objects
