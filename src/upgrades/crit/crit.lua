

--[[

crit upgrades:

- base crit upgrade
- crits spawn a knife
- crits cause crops to be slimed
- crit-potion upgrade: ALL hits are crits for 20 seconds!
- when critting, cause a chain of lightning

]]

---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end



local function drawUI(uinfo, level, x, y, w, h)
    local t1 = love.timer.getTime()/2

    local cx,cy = x, y+h/2
    local rad = w/4

    local x1,y1 = cx, cy+rad*math.cos(t1)

    g.drawImage("crit_strike_symbol", x1,y1)
end



defUpgrade("crit_strike_chance", "Critical Strikes", {
    description = "When hitting a crop, %{1} chance to {CRIT}CRITICAL-HIT{/CRIT}, dealing 10x damage!",
    getValues = function(uinfo, level)
        return level
    end,
    valueFormatter = {"%.14g%%"},

    getCritChanceModifier = function(uinfo, level)
        return uinfo:getValues(level) / 100
    end,
    drawUI=drawUI
})



defUpgrade("crit_knives", "Critical Knives", {
    description = "When a crop is {CRIT}Critically hit{/CRIT}, spawn %{1} knives!",
    getValues = function(uinfo, level)
        return level*2
    end,
    valueFormatter = {"%d"},

    maxLevel = 3,

    tokenCrit = function (uinfo, level, tok)
        local val = uinfo:getValues(level)
        for _=1,val do
            worldutil.spawnKnife(tok.x,tok.y, nil, 26)
        end
    end,
    drawUI=drawUI
})



