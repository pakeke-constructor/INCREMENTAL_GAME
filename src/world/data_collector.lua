
---@class g.DataCollector: objects.Class
local DataCollector = objects.Class("g:DataCollector")

local table_new = require("table.new")

---@param count integer
function DataCollector:init(count, startValue)
    assert(count > 1)
    self.pointer = 0
    ---@type number[]
    self.buffer = table_new(count, 0)
    for i = 1, count do
        self.buffer[i] = startValue
    end
end

if false then
    ---@param count integer
    ---@param startValue number
    ---@return g.DataCollector
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function DataCollector(count, startValue) end
end

---@param value number
function DataCollector:setAndIncrementPointer(value)
    self.buffer[self.pointer + 1] = value
    self.pointer = (self.pointer + 1) % #self.buffer
end

function DataCollector:getPrevious()
    return self.buffer[(self.pointer - 1) % #self.buffer + 1]
end

---@return number
function DataCollector:sumdiff()
    local result = 0

    for i = 1, #self.buffer - 1 do
        local prev = self.buffer[(self.pointer - i) % #self.buffer + 1]
        local prev2 = self.buffer[(self.pointer - i - 1) % #self.buffer + 1]
        result = result + math.max(prev - prev2, 0)
    end

    return result
end

function DataCollector:avgdiff()
    return self:sumdiff() / (#self.buffer - 1)
end

return DataCollector
