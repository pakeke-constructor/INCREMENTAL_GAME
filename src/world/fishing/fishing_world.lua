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

    local wharfY = 100
    local wharfW = 100
    self.wharfArea = Kirigami(0-3000,wharfY,wharfW+3000,50)

    self.worldArea = Kirigami(0,0,300,200)
    self.castArea = Kirigami(wharfW + 20, wharfY-25, 100,100)
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

    love.graphics.setColor(objects.Color("#".."FF8E5F31"))
    love.graphics.rectangle("fill", self.wharfArea:get())

    love.graphics.setColor(0,0,0.8)
    love.graphics.rectangle("line", self.worldArea:get())
    love.graphics.rectangle("line", self.castArea:get())

    love.graphics.setColor(1,1,1)
    for _, v in ipairs(objlist) do
        v:draw()
    end
end


---@param rarity g.FishingRarity
function FishingWorld:giveLootRewardFor(rarity)
    print("Got a(n) "..rarity.." fish")
end

return FishingWorld
