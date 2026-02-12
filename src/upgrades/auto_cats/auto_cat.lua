---@class CatEntity: g.Entity
---@field public dirX -1|1
---@field public dirY -1|1
---@field public baseSpeed number
---@field public speed number
---@field public radius number

---@param self CatEntity
local function randomizeDir(self)
    self.dirX = love.math.random(0, 1) * 2 - 1
    self.dirY = love.math.random(0, 1) * 2 - 1
end


local function getRadius(self)
    return self.radius * g.stats.AutoCatRadiusMultiplier
end


---@param update fun(self: CatEntity, dt:number)
local function makeCatUpdate(update)
    ---@param self CatEntity
    ---@param dt number
    local function farmerCatUpdate(self, dt)
        self.speed = (self.baseSpeed or 20) + g.stats.AutoCatMoveSpeed
        -- Update positions
        worldutil.updateLikeDVD(self, dt)
        worldutil.updateWaddleAnimation(self, self.dirX,self.dirY)

        update(self, dt)
    end

    return farmerCatUpdate
end

local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.09}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9,0.8}

---@param self CatEntity
local function drawHarvestCircle(self)
    return worldutil.drawHarvestCircle(self.x, self.y, getRadius(self), HARVEST_CIRCLE_INSIDE, HARVEST_CIRCLE_BORDER)
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





local MAX_TOKENS_PLANTED = 40

---@param id string
---@param tok_id string
---@param def table
local function definePlanterCat(id, def, tok_id)
    def.image = def.image or "planter_cat"
    def.baseSpeed = 10

    ---@param self CatEntity|{_timeout:number}
    def.init = function (self)
        randomizeDir(self)
        self._timeout = 5
    end

    ---@param self CatEntity|{_timeout:number}
    def.update = makeCatUpdate(function (self, dt)
        self._timeout = self._timeout - dt
        if self._timeout <= 0 then
            -- spawn crop!!
            local w = g.getMainWorld()
            self._timeout = 5
            if w:getTokenCount(tok_id) <= MAX_TOKENS_PLANTED then
                g.spawnToken(tok_id, self.x,self.y)
            end
        end
    end)

    def.draw = makeDrawWithWeapon(tok_id)

    g.defineEntity(id,def)
end



g.defineEntity("grass_farmer_cat", {
    image = "grass_farmer_cat",
    radius = 20,
    baseSpeed = 20,

    init = randomizeDir,
    update = makeCatUpdate(function(self, dt)
        ---@param tok g.Token
        local function tokenHitter(tok)
            if tok.category == "grass" then
                return g.tryHitToken(tok)
            end
        end
        local rad = getRadius(self) + consts.HARVEST_AREA_LEEWAY
        g.iterateTokensInArea(self.x, self.y, rad, tokenHitter)
    end),

    drawBelow = drawHarvestCircle,
    draw = makeDrawWithWeapon("iron_scythe"),
})



g.defineEntity("lumberjack_cat", {
    image = "lumberjack_cat",
    radius = 20,
    baseSpeed = 2,

    init = randomizeDir,
    update = makeCatUpdate(function(self, dt)
        local rad = getRadius(self) + consts.HARVEST_AREA_LEEWAY
        g.iterateTokensInArea(self.x, self.y, rad, g.tryHitToken)
    end),
    drawBelow = drawHarvestCircle,
    draw = makeDrawWithWeapon("steel_scythe"),
})







---------------------
-- Farmer Cat upgrade
---------------------

---@param id string
---@param name string
---@param def g.UpgradeDefinition|{kind:nil}
local function defineCatUpgrade(id, name, def)
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
    def.procGen =  {
        weight = 30,
        distance = {3, 8}
    }

    g.defineUpgrade(id, name, def)
end


defineCatUpgrade("grass_farmer_cat", "Grass Farmer Cat", {
    description = "Farmer-Cats farm grasses automatically!",
    maxLevel = 5
})



defineCatUpgrade("lumberjack_cat", "Lumberjack Cat", {
    description = "Lumberjack Cat moves slow, but harvests all crop types!",
    maxLevel = 5,
})


local PLANTER_CATS = {
    {"grass_1", "Tiny Grass", nil, "Gardener Cat"},
    {"grass_2", "Small Grass", nil, "Gardener Cat II"},
    {"grass_4", "Big Grass", nil, "Gardener Cat III"},
    {"blue_grass_1", "Tiny Blue Grass", nil, "Gardener Cat"},
    {"blue_grass_2", "Small Blue Grass", nil, "Gardener Cat II"},
    {"blue_grass_4", "Big Blue Grass", nil, "Gardener Cat III"},
    {"bomb", "Bombs", "demolition_cat", "Demolition Cat" },
    {"mushroom_blue", "Lightning Mushrooms", "lightning_cat", "Lightning Cat"},
    {"chest_golden", "Golden Chests", nil, "Treasure Cat"},
}

for i, def in ipairs(PLANTER_CATS) do
    local tok_id = def[1]
    local tokName = def[2]
    local img = def[3] or "planter_cat"
    local catName = def[4] or tokName .. " Cat"

    local idd = "planter_cat_"  .. tok_id

    definePlanterCat(idd, {
        image = img
    }, tok_id)

    defineCatUpgrade(idd, catName, {
        image = "null_image",
        drawUI = function (uinfo, level, x, y, w, h)
            local t = love.timer.getTime()*3
            g.drawImage(img, x+w/3, y+h/2)
            g.drawImage(tok_id, x+w*0.8, y+h/2 + 3*math.sin(t))
        end,
        description = "Plants " .. tokName .. "!",
    })
end



g.defineEntity("knife_cat", {
    image = "knife_cat",
    radius = 20,
    baseSpeed = 30,

    init = function(self)
        ---@diagnostic disable-next-line
        randomizeDir(self)
        achievements.unlockAchievement("KNIFE_CAT")
    end,

    update = makeCatUpdate(function (self, dt)end),

    perSecondUpdate = (function(self, dt)
        local rot = love.math.random() * math.pi*2
        local CT=4
        for i = 1, CT do
            local r = rot + i*2*math.pi/CT
            worldutil.spawnKnife(self.x,self.y, r, 1)
        end
    end),

    drawBelow = function(ent)
        helper.drawWings(ent.x, ent.y, love.timer.getTime()*1.3)
    end,
})

defineCatUpgrade("knife_cat", "Knife Cat", {
    drawUI = function (uinfo, level, x, y, w, h)
        local xx,yy = x+w/2, y+h/2
        helper.drawWings(xx,yy, love.timer.getTime())
    end,
    description = "Shoots out knives!",
})



















--[[

Meta-Cat upgrades

]]

g.defineUpgrade("cat_in_boots", "Cats in Boots", {
    description = "All cats move %{1} faster!",
    kind = "HARVESTING",

    getValues = helper.percentageGetter(25),
    valueFormatter = {"%d%%"},

    getAutoCatMoveSpeedMultiplier = function(uinfo, level)
        local a=uinfo:getValues(level)
        return 1+(a/100)
    end,
    procGen = {weight = 1, distance = {4, 10}}
})


g.defineUpgrade("slab_of_salmon", "Slab of Salmon", {
    description = "All cats have %{1} bigger radius!",
    kind = "HARVESTING",

    getValues = helper.percentageGetter(20),
    valueFormatter = {"%d%%"},

    getAutoCatRadiusMultiplierMultiplier = function(uinfo, level)
        local a=uinfo:getValues(level)
        return 1+(a/100)
    end,
    procGen = {weight = 1, distance = {3, 8}}
})

