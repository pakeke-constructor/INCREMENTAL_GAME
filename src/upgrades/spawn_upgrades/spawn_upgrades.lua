-------------
-- Fertilizer
-------------

g.defineToken("residue", "Residue", {
    maxHealth = 50,
    image = "residue",
    shadow = "shadow_small",
    category = "grass",
    resources = {money = 1},
    procGen = {weight = 2, distance = {2, 8}}
})


g.defineUpgrade("fertilizer", "Fertilizer", {
    description = "When a crop is harvested, %{1} chance to leave behind residue {residue}!",
    kind = "MISC",
    image = "residue",

    getValues = helper.percentageGetter(5),
    valueFormatter = {"%d%%"},

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    tokenDestroyed = function(uinfo, level, tok)
        if tok.type == "residue" then
            return
        end

        local chance = uinfo:getValues(level) / 100
        if love.math.random() <= chance then
            worldutil.spawnTokenNearPosition("residue", tok.x, tok.y, 16)
        end
    end,
    procGen = {weight = 2, distance = {2, 6}}
})


g.defineUpgrade("fertilizer_spawner_by_cropcount", "Fertilizer+", {
    description = "for every %{1} crops harvested, spawn residue {residue}.",
    kind = "MISC",
    image = "fertilizer_plus",
    maxLevel = 11,

    getValues = function(uinfo, level)
        return 24 - level*4
    end,

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    tokenDestroyed = function(uinfo, level, tok)
        local count = uinfo:getValues(level)

        if g.getMetric("totalTokensHarvested") % count == 0 then
            worldutil.spawnTokenNearPosition("residue", tok.x, tok.y, 16)
        end
    end,
    procGen = {weight = 2, distance = {3, 8}, needs = "fertilizer"}
})




----------------
-- Tax Deduction
----------------

g.defineUpgrade("tax_deduction", "Tax Deduction", {
    description = "Earn %{1} {money} every time a crop is spawned.",
    kind = "MISC",
    maxLevel = 1,

    getValues = function (uinfo, level)
        return level*3
    end,

    tokenSpawned = function(uinfo, level)
        g.addResource("money", level*3)
    end,
    procGen = {weight = 1, distance = {3, 8}}
})
