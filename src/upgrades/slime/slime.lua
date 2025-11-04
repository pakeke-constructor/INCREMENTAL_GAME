

g.defineTokenUpgrade("slime_token", "Slime", {
    token = {
        particles = "slime",
        category = "slime",
        description = "When destroyed, covers surrounding tokens in slime!",
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


--[[
TODO: 
rename this shit, its dumb,
and doesnt fit with theme.
]]
g.defineUpgrade("slime_knife", "Slime Knife", {
    drawUI=drawSlime,
    kind="HARVESTING",

    maxLevel = 4,

    getValues = function(self,level)
        -- level 1: 20%
        -- level 2: 30%
        -- etc.
        return (level+1)*10
    end,

    description = "Slimed tokens take +%{1}% extra damage",

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

UPGRADE: Slimed-tokens gain +1 gold
UPGRADE: Slimed-tokens explode when destroyed
UPGRADE: When a token is slimed, deal 10 damage to it!
UPGRADE: Grass has a 10% chance to spawn slimed
UPGRADE: Rocks have a 10% chance to spawn slimed

]]