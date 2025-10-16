---@class g.FishingWorld: objects.Class
local FishingWorld = objects.Class("g:FishingWorld")

function FishingWorld:init()
    ---@type g.FisherCat[]
    self.managedFishercat = {}
    ---@type g.FisherCat|nil
    self.mainFishercat = nil -- This is player's fishercat
end

if false then
    ---@return g.FishingWorld
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function FishingWorld() end
end

---@param dt number
function FishingWorld:update(dt)
    if self.mainFishercat then
        self.mainFishercat:update(dt)
    end

    for _, v in ipairs(self.managedFishercat) do
        v:update(dt)
    end
end

---@param a g.FisherCat
---@param b g.FisherCat
local function sortOrder(a, b)
    return a.y < b.y
end

function FishingWorld:draw()
    ---@type g.FisherCat[]
    local objlist = {}

    if self.mainFishercat then
        objlist[#objlist+1] = self.mainFishercat
    end

    for _, v in ipairs(self.managedFishercat) do
        objlist[#objlist+1] = v
    end

    table.sort(objlist, sortOrder)

    for _, v in ipairs(objlist) do
        v:draw()
    end
end


-- Note: this table MUSt be sorted by lowest window to highest.
local SPACING = {
    {
        window = 0.1,
        name = "Perfect",
    },
    {
        window = 0.3,
        name = "Nice",
    },
    {
        window = 0.55,
        name = "Great",
    },
    {
        window = 0.7,
        name = "Good",
    },
    {
        window = 1.0,
        name = "Okay",
    }
}

---@return number[]
function FishingWorld:querySpacing()
    local result = {}
    for _, v in ipairs(SPACING) do
        result[#result+1] = v.window
    end
    return result
end

---@param meter number Value between 0 and max(querySpacing()). 0 is perfect hit.
function FishingWorld:giveLootRewardFor(meter)
    local abs = math.abs(meter)

    for _, v in ipairs(SPACING) do
        if abs <= v.window then
            print("Got a(n) "..v.name.." catch")
            break
        end
    end
end

return FishingWorld
