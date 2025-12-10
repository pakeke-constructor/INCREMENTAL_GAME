-------------
-- Fertilizer
-------------

g.defineToken("manure", "Manure", {
    maxHealth = 5,
    resources = {money = 1}
})

g.defineUpgrade("manure_spawner", "Fertilizer", {
    description = "When a crop is harvested, %{1} chance to leave behind fertilizer!",
    kind = "MISC",
    image = "manure",

    getValues = helper.percentageGetter(5),
    valueFormatter = {"%d%%"},

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    tokenDestroyed = function(uinfo, level, tok)
        if tok.id == "manure" then
            return
        end

        local chance = uinfo:getValues(level) / 100
        if love.math.random() <= chance then
            worldutil.spawnTokenNearPosition("manure", tok.x, tok.y, 16)
        end
    end
})

g.defineUpgrade("manure_spawner_by_cropcount", "Fertilizer+", {
    description = "for every %{1} crops harvested, spawn a fertilizer.",
    kind = "MISC",
    image = "manure",
    maxLevel = 11,

    getValues = function(uinfo, level)
        return 21 - level
    end,

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    tokenDestroyed = function(uinfo, level, tok)
        local count = uinfo:getValues(level)

        if g.getMetric("totalTokensHarvested") % count == 0 then
            worldutil.spawnTokenNearPosition("manure", tok.x, tok.y, 16)
        end
    end
})




----------------
-- Tax Deduction
----------------

g.defineUpgrade("tax_deduction", "Tax Deduction", {
    description = "Earn $1 for every crops spawned.",
    kind = "MISC",
    maxLevel = 1,

    tokenSpawned = function()
        g.addResource("money", 1)
    end
})
