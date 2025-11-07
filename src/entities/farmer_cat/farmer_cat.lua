---@class FarmerCatEntity: g.Entity
---@field public dirX -1|1
---@field public dirY -1|1
---@field public speed number
---@field public radius number

---@param self FarmerCatEntity
local function randomizeDir(self)
    self.dirX = love.math.random(0, 1) * 2 - 1
    self.dirY = love.math.random(0, 1) * 2 - 1
end

---@param targetCategory g.Category
local function makeFarmerCatUpdate(targetCategory)
    ---@param tok g.Token
    local function  tokenHitter(tok)
        if tok.category == targetCategory then
            return g.tryHitToken(tok)
        end
    end

    ---@param self FarmerCatEntity
    ---@param dt number
    local function farmerCatUpdate(self, dt)
        -- Update positions
        worldutil.updateLikeDVD(self, dt)
        worldutil.updateWaddleAnimation(self, self.dirX,self.dirY)
        self.sx = -self.sx

        -- Try harvest
        g.iterateTokensInArea(self.x, self.y, self.radius + consts.HARVEST_AREA_LEEWAY, tokenHitter)
    end

    return farmerCatUpdate
end

local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.09}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9,0.8}

---@param self FarmerCatEntity
local function drawHarvestCircle(self)
    return worldutil.drawHarvestCircle(self.x, self.y, self.radius, HARVEST_CIRCLE_INSIDE, HARVEST_CIRCLE_BORDER)
end




g.defineEntity("grass_farmer_cat", {
    image = "grass_farmer_cat",
    radius = 20,
    speed = 50,
    shadowRadius = 7,

    init = randomizeDir,
    update = makeFarmerCatUpdate("grass"),
    drawBelow = drawHarvestCircle
})

g.defineEntity("lumberjack_cat", {
    image = "lumberjack_cat",
    radius = 20,
    speed = 50,
    shadowRadius = 7,

    init = randomizeDir,
    update = makeFarmerCatUpdate("wood"),
    drawBelow = drawHarvestCircle,
    draw = function(self)
        g.drawImageOffset("iron_axe", self.x+(self.ox or 0), self.y+(self.oy or 0), self.rot or 0, -self.sx, 1, 0, 0.3)
    end
})
