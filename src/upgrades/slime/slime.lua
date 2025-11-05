

g.defineTokenUpgrade("slime_token", "Slime", {
    token = {
        particles = "slime",
        category = "slime",
        description = "When destroyed, covers surrounding crops in slime!",
        resources = {money = 0},
        maxHealth = 7,
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
    },

    upgrade = {
        price = {money=500},
        maxLevel=2,
    }
})



local function drawSlime(uinfo,level,x,y,w,h)
    local s=math.sin(love.timer.getTime()*4)
    g.drawImage("slimed_visual2",x,y+s,0)
end


g.defineUpgrade("corrosive_slime", "Corrosive Slime", {
    drawUI=drawSlime,
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

    price={money=2000},
})


--[[

Corrosive slime: Crops that are slimed take +X% extra damage
Better-slime: Crops that are slimed earn +5% resources
Slime apocalypse: Every second, 1 random crop becomes slimed
Slime pandemic: When a slimed crop is destroyed, 20% chance to spread slimed to a nearby crop
Slime genetics: Crops that are slimed earn $1 passively every second
Slime crockpot: Grass crops that are slimed earn +X% money
Slime recycling: When Grass crops that are slimed earn +X% money
Slime grenade: Crops that are slimed have a 10% chance to explode when destroyed!


]]

