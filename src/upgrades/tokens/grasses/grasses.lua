

local function defGrass(id,name,def)
    def.particles="grass"
    def.category="grass"
    g.defineToken(id,name,def)
end

---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "TOKEN_MODIFIER"
    return g.defineUpgrade(id,name,tabl)
end





defGrass("grass_1", "Grass (I)", {
    shadow = "shadow_small",
    resources = {money = 1},
    maxHealth = 80
})


defGrass("grass_2", "Grass (II)", {
    resources = {money = 3},
    maxHealth = 100
})


defGrass("grass_3", "Grass (III)", {
    resources = {money = 10},
    shadow = "shadow_big",
    maxHealth = 120
})


defGrass("grass_4", "Grass (IV)", {
    resources = {money = 50},
    shadow = "shadow_big",
    maxHealth = 140
})




defUpgrade("grassy_poison", "Grass Poison", {
    description = "All grass spawns with 20% less health",
    maxLevel = 1,

    ---@param tok g.Token
    getTokenMaxHealthMultiplier = function(_, _, tok)
        return tok.category == "grass" and 0.8 or 1
    end
})



defUpgrade("grassy_shovel", "Grassy Shovel", {
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
                money = uinfo:getValues(level)
            }
        end
        return nil
    end
})





