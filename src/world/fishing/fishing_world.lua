---@class g.FishingWorld: objects.Class
local FishingWorld = objects.Class("g:FishingWorld")

---@alias g.FishingRarity
---| "common"
---| "rare"
---| "epic"

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



---@return number[]
function FishingWorld:querySpacing()
    local result = {}
    for _, v in ipairs(SPACING) do
        result[#result+1] = v.window
    end
    return result
end

---@param rarity g.FishingRarity
function FishingWorld:giveLootRewardFor(rarity)
    print("Got a(n) "..rarity.." fish")
end

return FishingWorld
