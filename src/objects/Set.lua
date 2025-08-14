
-- Need to make sure this is loaded; it may not be loaded yet
local Class = require(".Class")

--[[

Sparse-Set implementation.


Supports O(1) addition and removal.
Also supports iteration.

Order is not consistent, and will change quite dynamically.


]]
---Availability: Client and Server
---@class objects.Set<T>: objects.Class
local Set = Class("objects:Set")

if false then
    ---Availability: Client and Server
    ---@param initial any[]?
    ---@return objects.Set
    function Set(initial) end ---@diagnostic disable-line: cast-local-type, missing-return
end

function Set:init(initial)
    self.pointers = {}
    self.len     = 0
    if initial then
        for i=1, #initial do
            self:add(initial[i])
        end
    end
end

---Clears the Set completely.
---@return objects.Set
function Set:clear()
    local obj
    local ptrs = self.pointers
    for i=1, self.len do
        obj = self[i]
        ptrs[obj] = nil
        self[i] = nil    
    end

    self.len = 0
    return self
end

---Adds an object to the Set
---@param obj any
---@return objects.Set
function Set:add(obj)
   if self:has(obj) then
      return self
   end

   local sze = self.len + 1

   self[sze] = obj
   self.pointers[obj] = sze
   self.len          = sze

   return self
end

---@param other objects.Set
---@return objects.Set
function Set:intersection(other)
    local newSet = Set()
    for _, v in ipairs(self) do
        if other:has(v) then
            newSet:add(v)
        end
    end
    return newSet
end

---@param other objects.Set
---@return objects.Set
function Set:union(other)
    local newSet = Set()
    for _, v in ipairs(other) do
        newSet:add(v)
    end
    for _,v in ipairs(self) do
        newSet:add(v)
    end
    return newSet
end




local funcTc = typecheck.assert("table", "function")

---@param func fun(item:any):boolean
---@return objects.Set
function Set:filter(func)
    funcTc(self, func)
    local newSet = Set()
    for i=1, self.len do
        local item = self[i]
        if func(item) then
            newSet:add(item)
        end
    end
    return newSet
end




---Removes an object from the Set.
---If the object isn't in the Set, returns nil.
---@param obj any
---@return objects.Set?
function Set:remove(obj, index)
    if not obj then
        return nil
    end
    if not self.pointers[obj] then
        return nil
    end

    index = index or self.pointers[obj]
    local sze  = self.len

    if index == sze then
        self[sze] = nil
    else
        local other = self[sze]

        self[index]  = other
        self.pointers[other] = index

        self[sze] = nil
    end

    self.pointers[obj] = nil
    self.len = sze - 1

    return self
end

---@return integer
function Set:length()
    return self.len
end

Set.size = Set.length -- alias

---Returns true if the Set contains `obj`, false otherwise.
---@param obj any
---@return boolean
function Set:has(obj)
   return self.pointers[obj] and true
end

Set.contains = Set.has -- alias

return Set
