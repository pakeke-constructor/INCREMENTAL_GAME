
--[[

(TOKEN) Slime: When destroyed, slime surrounding crops
Corrosive slime: Crops that are slimed take +X% extra damage
Better-slime: Crops that are slimed earn +5% resources
Acidic slime: Crops that are slimed take X damage every second
Slime apocalypse: Every 4 seconds, 1 random crop becomes slimed
Slime pandemic: When a slimed crop is destroyed, 20% chance to spread slimed to a nearby crop
Slime fertilizer: Crops that are slimed earn $X passively every second
Slime grenade: Crops that are slimed have a 10% chance to explode when destroyed!


]]


local function slimeProcGen(weight, min,max)
    return {
        weight = weight,
        distance = {min or 5,max or 20},
        needs = "slime_token"
    }
end


g.defineToken("slime_token", "Slime", {
    particles = "slime",
    category = "slime",
    description = "When destroyed, covers surrounding crops in slime!\n(Slimed crops take extra damage)",
    resources = {money = 0},
    maxHealth = 100,
    maxLevel=3,
    procGen = {
        weight = 4,
        distance = {3,12}
    },
    tokenDestroyed = function(tok)
        local MAX_TOKENS_TO_SLIME = 5
        local i = 0
        g.iterateTokensInArea(tok.x,tok.y, 50, function(tok)
            i = i + 1
            if i <= MAX_TOKENS_TO_SLIME then
                g.slimeToken(tok)
            end
        end)
    end
})



local function drawSlime(uinfo,level,x,y,w,h)
    local s=math.sin(love.timer.getTime()*4)
    g.drawImage("slimed_visual2",x+8,y+6+s,0)
end


g.defineUpgrade("corrosive_slime", "Corrosive Slime", {
    drawUI=drawSlime,
    procGen = slimeProcGen(2),

    kind="HARVESTING",

    maxLevel = 6,

    getValues = helper.percentageGetter(10),

    description = "Crops that are slimed take +%{1}% extra damage",

    ---@param tok g.Token
    getTokenDamageMultiplier = function(self,level, tok)
        if tok.slimed then
            local a=self:getValues(level)
            return 1+(a/100)
        end
    end,
})




g.defineUpgrade("better_slime", "Better Slime", {
    drawUI=drawSlime,
    procGen = slimeProcGen(2),

    kind="TOKEN_MODIFIER",

    maxLevel = 6,
    getValues = helper.percentageGetter(5),

    description = "Crops that are slimed earn +%{1}% extra resources",

    ---@param tok g.Token
    getTokenResourceMultiplier = function(self,level, tok)
        if tok.slimed then
            local a=self:getValues(level)
            return 1+(a/100)
        end
    end,
})




g.defineUpgrade("acidic_slime", "Acidic Slime", {
    drawUI=drawSlime,
    procGen = slimeProcGen(1),

    kind="TOKEN_MODIFIER",

    maxLevel = 6,
    getValues = helper.valueGetter(10),

    description = "Crops that are slimed take %{1} damage every second",

    perSecondUpdate = function(self,level)
        local world = g.getSn().mainWorld
        local dmg = self:getValues(level)
        for _,tok in ipairs(world.tokens)do
            ---@cast tok g.Token
            if tok.slimed then
                g.damageToken(tok, dmg)
            end
        end
    end,
})






g.defineUpgrade("slime_apocalypse", "Slime Apocalypse", {
    drawUI=drawSlime,
    procGen = slimeProcGen(2),

    kind="TOKEN_MODIFIER",

    maxLevel = 4,

    getValues = function(uinfo,level)
        return 15 - level*2
    end,

    description = "Every %{1} seconds, ALL crops become slimed!",

    perSecondUpdate = function(self,level, seconds)
        local val = self:getValues(level)
        if seconds % val == 0 then
            local world = g.getMainWorld()
            for _,tok in ipairs(world.tokens) do
                if not tok.slimed then
                    g.slimeToken(tok)
                end
            end
        end
    end,
})




g.defineUpgrade("slime_pandemic", "Slime Pandemic", {
    drawUI=drawSlime,
    procGen = slimeProcGen(2, 16,20),

    kind="TOKEN_MODIFIER",

    maxLevel = 4,

    getValues = helper.percentageGetter(8,20),
    valueFormatter = helper.PERCENTAGE_FORMATTER,

    description = "When a slimed crop is destroyed, %{1} chance to spread slimed to a nearby crop",

    tokenDestroyed = function(self,level, tok)
        if tok.slimed then
            local p = (self:getValues(level)/100)
            if love.math.random() < p then
                local done=false
                g.iterateTokensInArea(tok.x,tok.y, 60, function (t)
                    if (not done) and (not t.slimed) then
                        g.slimeToken(t)
                        done=true
                    end
                end)
            end
        end
    end,
})




g.defineUpgrade("slime_fertilizer", "Slime Fertilizer", {
    drawUI=drawSlime,
    procGen = slimeProcGen(2),

    kind="TOKEN_MODIFIER",

    maxLevel = 4,

    getValues = helper.valueGetter(1),

    description = "Crops that are slimed earn %{1} {money} passively every second",

    perSecondUpdate = function(self,level)
        local world = g.getSn().mainWorld
        local moneh = self:getValues(level)
        local bundle = {
            money=moneh
        }
        for _,tok in ipairs(world.tokens)do
            ---@cast tok g.Token
            if tok.slimed then
                g.addResourceFrom(tok, bundle)
            end
        end
    end,
})




g.defineUpgrade("slime_grenade", "Slime Grenade", {
    procGen = slimeProcGen(0.5, 16,20),

    drawUI=drawSlime,
    kind="HARVESTING",

    maxLevel = 5,

    getValues = helper.percentageGetter(5,10),
    valueFormatter=helper.PERCENTAGE_FORMATTER,

    description = "Crops that are slimed have a %{1} chance to explode when destroyed!",

    tokenDestroyed = function(self,level, tok)
        ---@cast tok g.Token
        if tok.slimed then
            worldutil.explosion(tok.x,tok.y)
        end
    end,
})


