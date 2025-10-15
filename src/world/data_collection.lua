---@class g.DataCollection: objects.Class
local DataCollection = objects.Class("g:DataCollection")

local table_new = require("table.new")

---@param count integer
function DataCollection:init(count)
    assert(count > 1)
    self.pointer = 0
    ---@type number[]
    self.buffer = table_new(count, 0)
    for i = 1, count do
        self.buffer[i] = 0
    end
end

if false then
    ---@param count integer
    ---@return g.DataCollection
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function DataCollection(count) end
end

---@param value number
function DataCollection:setAndIncrementPointer(value)
    self.buffer[self.pointer + 1] = value
    self.pointer = (self.pointer + 1) % #self.buffer
end

function DataCollection:getPrevious()
    return self.buffer[(self.pointer - 1) % #self.buffer + 1]
end

---@return number
function DataCollection:sumdiff()
    local result = 0

    for i = 1, #self.buffer - 1 do
        local prev = self.buffer[(self.pointer - i) % #self.buffer + 1]
        local prev2 = self.buffer[(self.pointer - i - 1) % #self.buffer + 1]
        result = result + math.max(prev - prev2, 0)
    end

    return result
end

function DataCollection:avgdiff()
    return self:sumdiff() / (#self.buffer - 1)
end

return DataCollection
