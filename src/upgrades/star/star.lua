

g.defineUpgrade("star_upgrade", "Starred Crops", {
    description = "%{1} chance to make a crop starred on spawn.\n(Starred crops earn 3x more resources, and have 3x health!)",
    kind = "HARVESTING",
    image = "star_upgrade",

    getValues = helper.percentageGetter(1),
    valueFormatter = {"%d%%"},
    maxLevel = 5,

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    ---@param tok g.Token
    tokenSpawned = function(uinfo, level, tok)
        local chance = uinfo:getValues(level) / 100
        if love.math.random() <= chance then
            g.starToken(tok)
        end
    end,
    ---@param tok g.Token
    getTokenResourceMultiplier = function(_, _, tok)
        if tok.starred then
            return 3
        end
    end,
    procGen = {weight = 1, distance = {5, 12}}
})
