---@class FarmerCatEntity: g.Entity
---@field public dirX -1|1
---@field public dirY -1|1
---@field public speed number
---@field public targetCategory g.Category
local FarmerCatEntity = {
    image = "farmer_cat",
    radius = 20,
    speed = 50,
    shadowRadius = 7
}

---@param self FarmerCatEntity
---@param dt number
local function farmerCatUpdate(self, dt)
    local world = g.getMainWorld()

    -- Update positions
    worldutil.updateLikeDVD(world, self, dt)
    worldutil.updateWaddleAnimation(self, self.dirX,self.dirY)
    self.sx = -self.sx

    -- Try harvest
    g.iterateTokensInArea(self.x, self.y, self.radius + consts.HARVEST_AREA_LEEWAY, function(tok)
        if tok.category == self.targetCategory then
            return g.tryHitToken(tok)
        end
    end)
end

function FarmerCatEntity:update(dt)
    return farmerCatUpdate(self, dt)
end


local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.09}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9,0.8}

function FarmerCatEntity:drawBelow()
    return worldutil.drawHarvestCircle(self.x, self.y, self.radius, HARVEST_CIRCLE_INSIDE, HARVEST_CIRCLE_BORDER)
end

g.defineEntity("farmer_cat", FarmerCatEntity)


---@class LumberjackCatEntity: FarmerCatEntity
local LumberjackCatEntity = {
    image = "lumberjack_cat",
    radius = 20,
    speed = 50,
    shadowRadius = 7,
    update = FarmerCatEntity.update,
    drawBelow = FarmerCatEntity.drawBelow
}

function LumberjackCatEntity:draw()
    g.drawImageOffset("iron_axe", self.x+(self.ox or 0), self.y+(self.oy or 0), self.rot or 0, -self.sx, 1, 0, 0.3)
end

g.defineEntity("lumberjack_cat", LumberjackCatEntity)
