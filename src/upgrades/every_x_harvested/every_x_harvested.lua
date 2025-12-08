


---@param id string
---@param name string
---@param def g.UpgradeDefinition
local function defEveryXUpgrade(id, name, def)
    def.description = "Every "
    g.defineUpgrade(id, name, def)
end


-- Spawn a {bomb/crop/chest/lightning} for every 10 {grass/berry} harvested

---@class _.every_x_ACTION
local ACTIONS = {
    {id = "lightning", name="Lightning", description="spawn lightning!", func = function(tok)
        worldutil.spawnLightning(tok.x, tok.y, 2, 6)
    end},
    {id = "bombs", name="Bombs", description="spawn a bomb!", func = function(tok)
        g.spawnToken("bomb",tok.x,tok.y)
    end},
    {id = "chests", name="Chests", description="spawn a random chest!", func = function(tok)
        local x,y = g.getRandomPositionForToken()
        if x and y then
            if love.math.random() < 0.5 then
                g.spawnToken("chest_big", x,y)
            else
                g.spawnToken("chest_small", x,y)
            end
        end
    end},
    {id = "money_bonus", name="Bonuses", description="earn +10 {money}", func = function(tok)
        g.addResource("money", 10)
    end},
    {id = "xp_bonus", name="Experience", description="earn +10 experience", func = function(tok)
        local sn = g.getSn()
        sn.xp = sn.xp + 10
    end},
}


---@class _.every_x_CATEGORY
local CATEGORIES = {
    {id = "mushroom", name="Mushroom",plural="mushrooms"},
    {id = "grass", name="Grassy",plural="grass"},
    {id = "berry", name="Berry",plural="berries"},
}


for _,action in ipairs(ACTIONS) do
    for _,category in pairs(CATEGORIES) do
        local id = "every_x_" .. category.id .. "_do_" .. action.id
        local name = category.name .. action.name -- eg:  "Mushroom Bombs"
        defEveryXUpgrade(id, name, {
            image = "null_image",

            kind = "HARVESTING",

            description = ("Every %{1} %s harvested, "):format(category.plural) .. action.description,

            tokenDestroyed = function(uinfo,level, tok)
                if tok.category == category.id then
                    if g.getTokensDestroyedInCategory(category.id) then
                        action.func(tok)
                    end
                end
            end,
            drawUI = function(uinfo, level, x, y, w, h)
                -- todo: draw orbiting shit here?
            end
        })
    end
end

