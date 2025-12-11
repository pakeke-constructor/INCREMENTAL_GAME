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
        self.speed = g.stats.AutoCatMoveSpeed
        -- Update positions
        worldutil.updateLikeDVD(self, dt)
        worldutil.updateWaddleAnimation(self, self.dirX,self.dirY)

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

local function makeDrawWithWeapon(itemImage)
    ---@param ent g.Entity
    return function(ent)
        love.graphics.push()
        love.graphics.translate(ent.x, ent.y)
        love.graphics.rotate(ent.rot or 0)
        love.graphics.scale(ent.sx or 1, ent.sy or 1)
        g.drawImageOffset(itemImage, 12, 4, math.pi / 4, -1, 1, 0.1, 0.9)
        love.graphics.pop()
    end
end



g.defineEntity("grass_farmer_cat", {
    image = "grass_farmer_cat",
    radius = 20,
    speed = 50,
    shadowRadius = 7,

    init = randomizeDir,
    update = makeFarmerCatUpdate("grass"),
    drawBelow = drawHarvestCircle,
    draw = makeDrawWithWeapon("basic_scythe"),
})

g.defineEntity("lumberjack_cat", {
    image = "lumberjack_cat",
    radius = 20,
    speed = 50,
    shadowRadius = 7,

    init = randomizeDir,
    update = makeFarmerCatUpdate("berry"),
    drawBelow = drawHarvestCircle,
    draw = makeDrawWithWeapon("steel_scythe"),
})






---------------------
-- Farmer Cat upgrade
---------------------

---@param id string
---@param name string
---@param def g.UpgradeDefinition|{kind:nil}
local function defineFarmerCat(id, name, def)
    function def:getEntityCount(level)
        return level
    end
    function def:spawnEntity()
        local worldW, worldH = g.getWorldDimensions()
        local x = love.math.random(0, worldW - 1)
        local y = love.math.random(0, worldH - 1)
        return g.spawnEntity(id, x, y)
    end
    def.kind = "MISC"

    g.defineUpgrade(id, name, def)
end

defineFarmerCat("grass_farmer_cat", "Grass Farmer Cat", {
    description = "Grass Farmer-Cats farm grasses automatically!",
    maxLevel = 5
})

defineFarmerCat("lumberjack_cat", "Lumberjack Cat", {
    description = "Lumberjack Cat farm woods automatically!",
    maxLevel = 5,
})




g.defineUpgrade("cat_in_boots", "Cats in Boots", {
    description = "Automatic cats move %{1} faster",
    kind = "HARVESTING",

    getValues = helper.percentageGetter(15),
    valueFormatter = {"%d%%"},

    getAutoCatMoveSpeedMultiplier = function(uinfo, level)
        local a=uinfo:getValues(level)
        return 1+(a/100)
    end
})
