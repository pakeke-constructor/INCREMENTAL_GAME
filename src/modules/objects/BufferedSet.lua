-- Need to make sure this is loaded; it may not be loaded yet
local Class = require(".Class")
local Set = require(".Set") -- Assuming the original Set class is in this file

--[[

Buffered Sparse-Set implementation.

Supports O(1) buffered addition and removal.
Operations are queued until flush() is called.
Also supports iteration of the current state.

Order is not consistent, and will change quite dynamically.

]]
---Availability: Client and Server
---@class objects.BufferedSet<T>: objects.Class
---@field private addBuffer table<any, true>
---@field private remBuffer table<any, true>
local BufferedSet = Class("objects:BufferedSet")

if false then
    ---Availability: Client and Server
    ---@param initial any[]?
    ---@return objects.BufferedSet
    function BufferedSet(initial) end ---@diagnostic disable-line: cast-local-type, missing-return
end


function BufferedSet:init(initial)
    self.pointers = {}
    self.len = 0

    self.addBuffer = {} -- { [obj] -> true }
    self.remBuffer = {} -- { [obj] -> true }

    if initial then
        for i = 1, #initial do
            self:add(initial[i])
        end
    end
end



---Clears the BufferedSet completely, including all buffers.
---@return objects.BufferedSet
function BufferedSet:clear()
    local obj
    local ptrs = self.pointers
    for i = 1, self.len do
        obj = self[i]
        ptrs[obj] = nil
        self[i] = nil
    end

    self.len = 0

    -- Clear all buffers
    self.addBuffer = {}
    self.remBuffer = {}

    return self
end


---Immediately adds an object to the Set (not buffered)
---@param obj any
---@return objects.BufferedSet
function BufferedSet:add(obj)
    if self:has(obj) then
        return self
    end

    local sze = self.len + 1

    self[sze] = obj
    self.pointers[obj] = sze
    self.len = sze

    return self
end


---Adds an object to the add buffer
---@param obj any
---@return objects.BufferedSet
function BufferedSet:addBuffered(obj)
    if obj == nil then
        return self
    end
    self.remBuffer[obj] = nil
    if self:has(obj) then
        return self
    end
    self.addBuffer[obj] = true
    return self
end


---Adds an object to the remove buffer
---@param obj any
---@return objects.BufferedSet
function BufferedSet:removeBuffered(obj)
    if obj == nil then
        return self
    end
    self.addBuffer[obj] = nil
    if not self:has(obj) then
        return self
    end
    self.remBuffer[obj] = true
    return self
end



---Immediately removes an object from the Set (not buffered)
---If the object isn't in the Set, returns nil.
---@param obj any
---@return objects.BufferedSet?
function BufferedSet:remove(obj, index)
    if not obj then
        return nil
    end
    if not self.pointers[obj] then
        return nil
    end

    index = index or self.pointers[obj]
    local sze = self.len

    if index == sze then
        self[sze] = nil
    else
        local other = self[sze]

        self[index] = other
        self.pointers[other] = index

        self[sze] = nil
    end

    self.pointers[obj] = nil
    self.len = sze - 1

    return self
end



---Flushes all buffered operations
---@return objects.BufferedSet
function BufferedSet:flush()
    -- Process removals first
    for obj, _ in pairs(self.remBuffer) do
        if self:has(obj) then
            self:remove(obj)
        end
    end
    self.remBuffer = {}

    for obj, _ in pairs(self.addBuffer) do
        if not self:has(obj) then
            self:add(obj)
        end
    end
    self.addBuffer = {}

    return self
end



---@param other objects.BufferedSet
---@return objects.BufferedSet
function BufferedSet:intersection(other)
    local newSet = BufferedSet()
    for _, v in ipairs(self) do
        if other:has(v) then
            newSet:add(v)
        end
    end
    return newSet
end


---@param other objects.BufferedSet
---@return objects.BufferedSet
function BufferedSet:union(other)
    local newSet = BufferedSet()
    for _, v in ipairs(other) do
        newSet:add(v)
    end
    for _, v in ipairs(self) do
        newSet:add(v)
    end
    return newSet
end



local funcTc = typecheck.assert("table", "function")

---@param func fun(item:any):boolean
---@return objects.BufferedSet
function BufferedSet:filter(func)
    funcTc(self, func)
    local newSet = BufferedSet()
    for i = 1, self.len do
        local item = self[i]
        if func(item) then
            newSet:add(item)
        end
    end
    return newSet
end



---@return integer
function BufferedSet:length()
    return self.len
end


BufferedSet.size = BufferedSet.length -- alias


---Returns true if the BufferedSet contains `obj` in the main set, false otherwise.
---Does not check buffers.
---@param obj any
---@return boolean
function BufferedSet:has(obj)
    return self.pointers[obj] and true
end


BufferedSet.contains = BufferedSet.has -- alias




return BufferedSet
