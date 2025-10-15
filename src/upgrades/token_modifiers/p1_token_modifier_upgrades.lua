---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "TOKEN_MODIFIER"
    return g.defineUpgrade(id,name,tabl)
end



defUpgrade("grassy_poison", "Grass Poison", {
    price = {money = 20},
    description = "All grass spawns with 20% less health",
    maxLevel = 1,

    ---@param tok g.Token
    getTokenMaxHealthMultiplier = function(_, _, tok)
        return tok.category == "grass" and 0.8 or 1
    end
})



defUpgrade("grassy_shovel", "Grassy Shovel", {
    price = {money = 20},
    description = "Deal %{1} damage to grass",
    maxLevel = 10,
    getValues = function(uinfo, level)
        return 1 + level
    end,
    valueFormatter = {"+%d"},

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    getTokenDamageModifier = function(uinfo, level, tok)
        return tok.category == "grass" and uinfo:getValues(level) or 0
    end
})



defUpgrade("horticulture_book", "Horticulture Book", {
    price = {money = 20},
    description = "Grasses earn %{1}",
    maxLevel = 10,
    getValues = function(uinfo, level)
        return math.floor(level ^ 1.5)
    end,
    valueFormatter = {"+$%d"},

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    getTokenResourceModifier = function(uinfo, level, tok)
        if tok.category == "grass" then
            return {
                money = uinfo:getValues(level) or 0
            }
        end
        return nil
    end
})



defUpgrade("moldy_block", "Moldy Block", {
    price = {money = 20},
    description = "Mushrooms earn %{1}",
    maxLevel = 10,
    getValues = function(uinfo, level)
        return math.floor(level ^ 1.5)
    end,
    valueFormatter = {"+%d wood"},

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    getTokenResourceModifier = function(uinfo, level, tok)
        if (tok.category == "mushroom") then
            return {
                wood = uinfo:getValues(level)
            }
        end
        return nil
    end
})


