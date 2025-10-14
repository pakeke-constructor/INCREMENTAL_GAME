---@class FarmerCatEntity: g.Entity
---@field public dirX -1|1
---@field public dirY -1|1
---@field public speed number
local FarmerCatEntity = {
    image = "farmer_cat",
    radius = 20,
    speed = 50
}

function FarmerCatEntity:update(dt)
    local world = g.getMainWorld()

    -- Update positions
    worldutil.updateLikeDVD(world, self, dt)
    worldutil.updateWaddleAnimation(self, self.dirX,self.dirY)

    -- Try harvest
    g.iterateTokensInArea(self.x, self.y, self.radius + consts.HARVEST_AREA_LEEWAY, g.tryHitToken)
end


local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.09}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9,0.8}

function FarmerCatEntity:drawBelow()
    return worldutil.drawHarvestCircle(self.x, self.y, self.radius, HARVEST_CIRCLE_INSIDE, HARVEST_CIRCLE_BORDER)
end

g.defineEntity("farmer_cat", FarmerCatEntity)
