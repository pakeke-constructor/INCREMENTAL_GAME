local Class = require(".Class")

---@class objects.Partition: objects.Class
---@field chunkSize number
---@field bins table<number, table>
local Partition = Class("objects:Partition")



local MAX_COORD = 32767
local COORD_OFFSET = 32768
local COORD_MULTIPLIER = 65536



-- validate coordinates are in range
local function validateCoord(coord, name)
    if coord < -MAX_COORD - 1 or coord > MAX_COORD then
        error(string.format("%s coordinate %d is out of range [%d, %d]", 
              name or "Bin", coord, -MAX_COORD - 1, MAX_COORD))
    end
end



function Partition:init(chunkSize)
    self.chunkSize = chunkSize
    self.bins = {}
    return self
end



-- Pairing functions for converting 2D coordinates to 1D key
local function pair(x, y)
    return ((x + COORD_OFFSET) * COORD_MULTIPLIER) + (y + COORD_OFFSET)
end


function Partition:add(obj, x, y)
    local binX = math.floor(x / self.chunkSize)
    local binY = math.floor(y / self.chunkSize)

    validateCoord(binX, "binX")
    validateCoord(binY, "binY")
    local key = pair(binX,binY)

    if not self.bins[key] then
        self.bins[key] = {}
    end

    table.insert(self.bins[key], obj)
end




--- Spatial query. Return true from the callback to stop early
---@param x number
---@param y number
---@param callback fun(item): true?
---@param range number?
function Partition:query(x, y, callback, range)
    local binX = math.floor(x / self.chunkSize)
    local binY = math.floor(y / self.chunkSize)

    local binRadius = range and math.ceil(range / self.chunkSize) or 1

    for dx = -binRadius, binRadius do
        for dy = -binRadius, binRadius do
            local key = pair(binX + dx, binY + dy)
            local bin = self.bins[key]
            if bin then
                for i = 1, #bin do
                    local stopEarly = callback(bin[i]) == true
                    if stopEarly then
                        return
                    end
                end
            end
        end
    end
end



function Partition:clear()
    for key, bin in pairs(self.bins) do
        table.clear(bin)
    end
end



return Partition
