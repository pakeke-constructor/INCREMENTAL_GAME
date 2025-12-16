


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
    end
})






g.defineToken("mushroom_blue", "Blue Mushroom", {
    category = "mushroom",
    maxHealth = 7,
    resources = {},
    description = "Spawns lightning when destroyed!",
    tokenDestroyed = function(tok)
        worldutil.spawnLightning(tok.x, tok.y, 2)
    end
})




g.defineToken("mushroom_red", "Red Mushroom", {
    category = "mushroom",
    description = "Explodes when destroyed!",
    maxHealth = 4,
    resources = {},
    tokenDestroyed = function(tok)
        worldutil.explosion(tok.x, tok.y, 10)
    end
})




g.defineToken("mushroom_green", "Green Mushroom", {
    category = "mushroom",
    maxHealth = 7,
    resources = {},
    description = "When destroyed, spawns 6 grass crops",
    tokenDestroyed = function(tok)
        local function getPos()
            local x,y = tok.x + math.random(-40,40), tok.y + math.random(-40,40)
            x,y = g.clampInsideWorld(x,y)
            if g.canSpawnTokenHere(x,y, 8) then
                return x,y
            end
        end
        worldutil.spawnShockwave(tok.x, tok.y, 0.2, 50, objects.Color.LIME)
        for _=1, 6 do
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
    end
})


