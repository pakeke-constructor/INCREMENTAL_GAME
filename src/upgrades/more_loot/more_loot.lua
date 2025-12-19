

---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end




defUpgrade("more_loot", "More Loot", {
    image = "money", -- TODO: change
    description = "All crops have %{1} more health, and earn %{2} more resources.",

    getValues = function(uinfo, level)
        ---@diagnostic disable-next-line: redundant-return-value
        return 6 + level * 4, 10 * level
    end,
    valueFormatter = {"%d%%", "%d%%"},

    getTokenMaxHealthMultiplier = function(uinfo, level)
        local healthMult = uinfo:getValues(level) / 100
        return 1 + healthMult
    end,
    getTokenResourceMultiplier = function(uinfo, level)
        local resMult = select(2, uinfo:getValues(level)) / 100
        return 1 + resMult
    end
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
        local m = 1+(level)/4
        return m
    end
})


