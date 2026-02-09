

---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end


local drawUI = function (uinfo, level, x, y, w, h)
    local dy = math.sin(love.timer.getTime())*2
    g.drawImage("more_loot_upgrade_icon", x+w*0.8, y+h/10+dy, 0,1,1)
end


defUpgrade("more_loot", "More Loot", {
    image = "money", -- TODO: change
    description = "All crops have %{1} more health, and earn %{2} more resources.",

    getValues = function(uinfo, level)
        ---@diagnostic disable-next-line: redundant-return-value
        return level*20, level*20
    end,
    valueFormatter = {"%d%%", "%d%%"},

    getTokenMaxHealthMultiplier = function(uinfo, level)
        local healthMult = uinfo:getValues(level) / 100
        return 1 + healthMult
    end,
    getTokenResourceMultiplier = function(uinfo, level)
        local resMult = select(2, uinfo:getValues(level)) / 100
        return 1 + resMult
    end,

    drawUI = drawUI,

    procGen = {
        weight = 40,
        distance = {2, 8}
    }
})




defUpgrade("land_deed", "Land deed", {
    description = "All crops earn %{1} resources. Increases size of harvest area",

    getValues = function(uinfo, level)
        ---@diagnostic disable-next-line: redundant-return-value
        return level+1
    end,
    valueFormatter = {"%dx"},

    getTokenResourceMultiplier = function(uinfo, level)
        return level
    end,
    getWorldTileSizeMultiplier = function(uinfo, level)
        local m = 1+(level)/8
        return m
    end,
    drawUI = drawUI
})


