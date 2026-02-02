
--[[

Basic class object.

Usage:

local MyClass = Class("class_name_foo") 
-- class_name_foo is used for serialization purposes.


function MyClass:init(a,b,c)
    print("obj instantiated with args: ", a,b,c)
end


function MyClass:method(arg)
    print("Hello, I am a method.")
    print(self, arg)
end



]]

local name_to_class = {
--[[
    [class_name] = class
]]
}


local function newObj(class, ...)
    local obj = {}
    setmetatable(obj, class)
    if type(obj.init) == "function" then
        obj:init(...)
    end
    if type(obj.__gc) == "function" and rawget(_G, "newproxy") then
        local proxy = newproxy(true)
        getmetatable(proxy).__gc = function() return obj:__gc() end
        obj.__gcobj = proxy -- to keep it in memory.
    end
    return obj
end


local default_class_mt = {__call = newObj}



local function assertStaticCall(self, class)
    if self~=class then
        error("Cannot be called on instances!", 2)
    end
end


---Create new class object.
---
---Call the class object to create new class instance.
---
---Availability: Client and Server
---@param name string
---@return objects.Class
local function Class(name)
    if type(name) ~= "string" then
        error("class(name) expects a string as first argument")
    end
    if name_to_class[name] then
        error("duplicate class name: " .. name)
    end

    local class = {}
    class.__index = class
    class.__name = name
    class.___implementors = {}

    local function isAncestor(base, derived)
        for k in pairs(base.___implementors) do
            if k == derived or isAncestor(k, derived) then
                return true
            end
        end

        return false
    end

    function class:isInstance(x)
        assertStaticCall(self, class)
        if type(x) ~= "table" then
            return false
        end
        local cls = getmetatable(x)
        if cls == class then
            return true
        end

        return isAncestor(class, cls)
    end

    function class:implement(base)
        assertStaticCall(self, class)
        if base.___implementors then
            base.___implementors[self] = true
        end
        for k,v in pairs(base) do
            if not self[k] then
                self[k] = v
            end
        end
        return self
    end

    function class:extendAs(newName)
        local cl = Class(newName)
        cl:implement(class)
        return cl
    end

    setmetatable(class, default_class_mt)

    return class
end



return Class

