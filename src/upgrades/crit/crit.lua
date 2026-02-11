

--[[

crit upgrades:

- base crit upgrade
- crits spawn a knife
- crits cause crops to be slimed
- crit-potion upgrade: ALL hits are crits for 20 seconds!
- when critting, cause a chain of lightning

]]


local function drawUI(uinfo, level, x, y, w, h)
    local t1 = love.timer.getTime()*3

    local cx,cy = x+w*0.8, y+h/4
    local bx,by = x+w*0.2, y+h*3/4
    local rad = w/16

    local x1,y1 = cx, cy+rad*math.cos(t1)
    local x2,y2 = bx, by+rad*math.sin(t1)

    --g.drawImage("crit_strike_symbol", x1,y1)
    g.drawImage("crit_strike_symbol_2", x1,y1)
    g.drawImage("crit_strike_symbol_2", x2,y2)
end


g.defineUpgrade("crit_strike_chance", "Critical Strikes", {
    kind = "HARVESTING",
    description = "When hitting a crop, %{1} chance to {CRIT}Critical-Hit{/CRIT}, dealing 10x damage!",
    getValues = function(uinfo, level)
        return level
    end,
    valueFormatter = {"%.14g%%"},

    getCritChanceModifier = function(uinfo, level)
        return uinfo:getValues(level) / 100
    end,
    drawUI=drawUI,
    procGen = {
        weight = 10,
        distance = {0, 6}
    }
})


---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    tabl.procGen = {
        weight = 2,
        distance = {2, 6},
        needs = "crit_strike_chance",
    }
    g.defineUpgrade(id,name,tabl)
end


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





defUpgrade("crit_slime", "Critical Slime", {
    description = "When a crop is {CRIT}Critically hit{/CRIT}, slime it!",
    getValues = function(uinfo, level)
        return 1
    end,
    valueFormatter = {"%d"},

    maxLevel = 1,

    tokenCrit = function (uinfo, level, tok)
        g.slimeToken(tok)
    end,
    drawUI=drawUI
})



defUpgrade("crit_lightning", "Critical Lightning", {
    image = "lightning_icon",
    description = "{CRIT}Critical hits{/CRIT} spawn %{1} lightning chains!",
    getValues = function(uinfo, level)
        return level
    end,
    valueFormatter = {"%d"},

    maxLevel = 5,

    tokenCrit = function (uinfo, level, tok)
        local val = uinfo:getValues(level)
        for i=1,val do
            worldutil.spawnLightning(tok.x, tok.y)
        end
    end,
    drawUI=drawUI
})



for _, resId in ipairs(g.RESOURCE_LIST)do
    defUpgrade("crit_loot_"..resId, "Critical Loot!", {
        image = resId,
        description = "{CRIT}Critical hits{/CRIT} earn %{1} {" .. resId .. "}!",
        getValues = function(uinfo, level)
            return level * 3
        end,
        valueFormatter = {"%d"},

        maxLevel = 5,

        isHidden = function (uinfo)
            local shouldBeVisible = g.isResourceUnlocked(resId)
            return not shouldBeVisible
        end,

        tokenCrit = function (uinfo, level, tok)
            local val = uinfo:getValues(level)
            g.addResourceFrom(tok, {
                [resId]=val
            })
        end,
        drawUI=drawUI
    })
end


