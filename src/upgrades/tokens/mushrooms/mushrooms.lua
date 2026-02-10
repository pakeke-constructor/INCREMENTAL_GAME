


---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "TOKEN_MODIFIER"
    return g.defineUpgrade(id,name,tabl)
end


defUpgrade("moldy_block", "Moldy Block", {
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
                fabric = uinfo:getValues(level)
            }
        end
        return nil
    end,
    procGen = {weight = 2, distance = {3, 8}}
})






g.defineToken("mushroom_blue", "Blue Mushroom", {
    category = "mushroom",
    maxHealth = 150,
    resources = {},
    description = "Spawns lightning when destroyed!",
    tokenDestroyed = function(tok)
        worldutil.spawnLightning(tok.x, tok.y)
    end,
    procGen = {weight = 3, distance = {1, 6}}
})




g.defineToken("mushroom_red", "Red Mushroom", {
    category = "mushroom",
    description = "Explodes when destroyed!",
    maxHealth = 150,
    resources = {},
    tokenDestroyed = function(tok)
        worldutil.explosion(tok.x, tok.y)
    end,
    procGen = {weight = 3, distance = {1, 6}}
})




g.defineToken("mushroom_green", "Green Mushroom", {
    category = "mushroom",
    maxHealth = 150,
    resources = {},
    description = "When harvested, spawns 3 grass crops",
    tokenDestroyed = function(tok)
        local function getPos()
            local x,y = tok.x + math.random(-40,40), tok.y + math.random(-40,40)
            x,y = g.clampInsideWorld(x,y)
            if g.canSpawnTokenHere(x,y, 8) then
                return x,y
            end
        end
        worldutil.spawnShockwave(tok.x, tok.y, 0.2, 50, objects.Color.LIME)
        for _=1, 3 do
            local x,y = getPos()
            if x and y then
                local t = nil
                local r = love.math.random()
                if r < 0.4 then
                    t = "grass_1"
                elseif r < 0.7 then
                    t = "grass_2"
                else
                    t = "grass_3"
                end
                g.spawnToken(t, x,y)
            end
        end
    end,
    procGen = {weight = 3, distance = {1, 6}}
})




g.defineToken("mushroom_basic", "Basic Mushroom", {
    category = "mushroom",
    shadow = "shadow_big",
    maxHealth = 200,
    resources = {money=10},
    description = "Earns bonus xp when harvested!",
    tokenDestroyed = function(tok)
        g.addXP(14) -- yolo IDK what a good number is
    end,
    procGen = {weight = 4, distance = {0, 5}}
})



g.defineToken("mushroom_brown", "Brown Mushroom", {
    category = "mushroom",
    shadow = "shadow_medium",
    maxHealth = 120,
    resources = {money=6},
    procGen = {weight = 3, distance = {1, 6}}
})





