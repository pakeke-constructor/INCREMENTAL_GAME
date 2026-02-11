

---@param id string
---@param name string
---@param def g.TokenDefinition
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
    maxHealth = 80,
    procGen = {
        weight = 4,
        distance = {0, 2}
    }
})


defGrass("grass_2", "Grass (II)", {
    resources = {money = 3},
    maxHealth = 100,
    procGen = {
        weight = 3,
        distance = {0, 4}
    }
})


defGrass("grass_3", "Grass (III)", {
    resources = {money = 10},
    shadow = "shadow_big",
    maxHealth = 120,
    procGen = {
        weight = 2,
        distance = {1, 4}
    }
})


defGrass("grass_4", "Grass (IV)", {
    resources = {money = 50},
    shadow = "shadow_big",
    maxHealth = 140,
    procGen = {
        weight = 1,
        distance = {2, 8}
    }
})




defUpgrade("grassy_poison", "Grass Poison", {
    description = "All grass spawns with 20% less health",
    maxLevel = 1,

    ---@param tok g.Token
    getTokenMaxHealthMultiplier = function(_, _, tok)
        return tok.category == "grass" and 0.8 or 1
    end,
    procGen = {weight = 2, distance = {2, 6}, needs = "grass_1"}
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
    end,
    procGen = {weight = 2, distance = {2, 6}, needs = "grass_1"}
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
    end,
    procGen = {weight = 2, distance = {3, 8}, needs = "grass_1"}
})





