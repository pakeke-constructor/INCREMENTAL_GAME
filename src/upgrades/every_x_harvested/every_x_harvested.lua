


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
    {id = "lightning", name="Lightning",description="spawn lightning!", func = function(tok)
        worldutil.spawnLightning(tok.x,tok.y, 2,6)
    end},
    {id = "bombs", name="Bombs",description="spawn a bomb!"},
    {id = "chests", name="Chests",description="spawn a random chest!"},
    {id = "money_bonus", name="Bonuses",description="earn +10 {money}"},
    {id = "xp_bonus", name="Experience",description="earn +10 experience"},
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
        local name =  category.name .. action.name -- eg:  "Mushroom Bombs"
        defEveryXUpgrade(id, name, {
            image = action.image,
            kind = "HARVESTING",

            description = ("Every %{1} %s harvested, "):format(category.plural) .. action.description,

            tokenDestroyed = function(uinfo,level, tok)
                if tok.category == category.id then
                    if g.getTokensDestroyedInCategory(category.id) then
                        action.func(tok)
                    end
                end
            end
        })
    end
end

