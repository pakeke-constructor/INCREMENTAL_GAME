---@meta

--The reason this is in its own file because objects.Class is an abstraction.

---@class objects.Class
local Class = {}

function Class:init(...)
end

---This accepts **class object**, not instance.
---@param self objects.Class Class object variable
---@param other any Instance to check
---@return boolean
function Class:isInstance(other)
end

---This accepts **class object**, not instance.
---@generic T: objects.Class
---@param cls T
---@param otherClass objects.Class
---@return T
function Class.implement(cls, otherClass)
end

return Class
