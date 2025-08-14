
local Class = require(".Class")

---Availability: Client and Server
---@class objects.Array: objects.Class
local Array = Class("objects:Array")



-- Initializes array
function Array:init(initial)
    self.len = 0

    if initial then
        if (type(initial) ~= "table") then
            error("Bad argument #1 to Array().\nexpected table, got: " .. tostring(type(initial)))
        end

        for i=1, #initial do
            self:add(initial[i])
        end
    end
end

if false then
    ---Initializes array
    ---
    ---Availability: Client and Server
    ---@param initial any[]?
    ---@return objects.Array
    function Array(initial) end ---@diagnostic disable-line: cast-local-type, missing-return
end

---Adds item to array
---@param x any
function Array:add(x)
    assert(x ~= nil, "cannot add nil to array")
    self.len = self.len + 1
    self[self.len] = x
end

---Clears array
function Array:clear()
    for i=1, self.len do
        self[i] = nil
    end
    self.len = 0
end

---Reverses the array in-place
---@return objects.Array
function Array:reverse()
    local n = self:size()
    local mid = math.floor(n / 2)
    for i = 1, mid do
        self[i], self[n - i + 1] = self[n - i + 1], self[i]
    end
    return self
end

---Returns the size of the array
---@return integer
function Array:size()
    return self.len
end

Array.length = Array.size -- alias

---Removes item from array at index
---(if index is nil, pops from the end of array.)
---@param i integer?
---@return any
function Array:remove(i)
    i = i or self.len
    if i and (not (1 <= i and i <= self.len)) then
        error("Array index out of range: " .. tostring(i))
    end
    local obj = table.remove(self, i)
    self.len = self.len - 1
    return obj
end

-- alias
Array.pop = Array.remove

---Pops item from array by swapping it with the last item
---this operation is O(1)
---
---**WARNING**: This operation DOES NOT preserve array order!!!
---@param i integer
function Array:quickRemove(i)
    local obj = self[self.len]
    self[i], self[self.len] = obj, nil
    self.len = self.len - 1
end

Array.quickPop = Array.quickRemove

---@param obj any
---@return integer?
function Array:find(obj)
    -- WARNING: Linear search O(n)
    for i=1, self.len do
        if self[i] == obj then
            return i
        end
    end
    return nil
end

---@return objects.Array
function Array:clone()
    local newArray = Array()
    for i=1, self.len do
        local item = self[i]
        newArray:add(item)
    end
    return newArray
end


local funcTc = typecheck.assert("table", "function")

---@param func fun(item:any):boolean
---@return objects.Array
function Array:filter(func)
    funcTc(self, func)
    local newArray = Array()
    for i=1, self.len do
        local item = self[i]
        if func(item) then
            newArray:add(item)
        end
    end
    return newArray
end

---@param func fun(item:any):any
---@return objects.Array
function Array:map(func)
    funcTc(self, func)
    local newArray = Array()
    for i=1, self.len do
        local item = func(self[i])
        if item ~= nil then
            newArray:add(item)
        end
    end
    return newArray
end

---@param comparator? fun(a:any,b:any):boolean
---@return objects.Array
function Array:sortInPlace(comparator)
    table.sort(self, comparator)
    return self
end

return Array
