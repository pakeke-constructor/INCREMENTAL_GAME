
local Class = require(".Class")

---A fixed-size ring buffer. Slots are initialized to `false` (never nil).
---@class objects.RingBuffer: objects.Class
local RingBuffer = Class("objects:RingBuffer")


---Initializes ringbuffer with given capacity
---@param capacity integer
function RingBuffer:init(capacity)
    assert(type(capacity) == "number" and capacity > 0, "capacity must be a positive integer")
    self.cap = capacity
    self.head = 1 -- index of oldest item
    self.len = 0
    for i=1, capacity do
        self[i] = false
    end
end


if false then
    ---@param capacity integer
    ---@return objects.RingBuffer
    function RingBuffer(capacity) end ---@diagnostic disable-line: cast-local-type, missing-return
end


---Returns current number of items
---@return integer
function RingBuffer:size()
    return self.len
end


---Returns max capacity
---@return integer
function RingBuffer:capacity()
    return self.cap
end


---Returns true if buffer is at capacity
---@return boolean
function RingBuffer:isFull()
    return self.len >= self.cap
end


---Pushes a value. If full, overwrites oldest.
---@param x any
function RingBuffer:push(x)
    assert(x ~= nil, "cannot push nil to RingBuffer")
    if self.len < self.cap then
        local i = ((self.head - 1 + self.len) % self.cap) + 1
        self[i] = x
        self.len = self.len + 1
    else
        self[self.head] = x
        self.head = (self.head % self.cap) + 1
    end
end


---Pops and returns the oldest item, or nil if empty
---@return any
function RingBuffer:pop()
    if self.len == 0 then
        return nil
    end
    local x = self[self.head]
    self[self.head] = false
    self.head = (self.head % self.cap) + 1
    self.len = self.len - 1
    return x
end


---Expands capacity. New slots are filled with `false`.
---@param newCapacity integer
function RingBuffer:expand(newCapacity)
    assert(newCapacity >= self.cap, "new capacity must be >= current capacity")
    if newCapacity == self.cap then
        return
    end
    -- unroll into a fresh contiguous array starting at index 1
    local new = {}
    for i=1, self.len do
        local idx = ((self.head - 1 + i - 1) % self.cap) + 1
        new[i] = self[idx]
    end
    for i=self.len+1, newCapacity do
        new[i] = false
    end
    for i=1, self.cap do
        self[i] = nil
    end
    for i=1, newCapacity do
        self[i] = new[i]
    end
    self.cap = newCapacity
    self.head = 1
end


---Iterates from oldest to newest. Yields (i, value) where i is 1..size().
---@return fun():integer?, any
function RingBuffer:iter()
    local i = 0
    return function()
        i = i + 1
        if i > self.len then
            return nil
        end
        local idx = ((self.head - 1 + i - 1) % self.cap) + 1
        return i, self[idx]
    end
end


return RingBuffer
