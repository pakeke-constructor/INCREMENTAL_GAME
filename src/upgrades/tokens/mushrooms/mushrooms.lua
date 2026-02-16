


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



g.defineToken("mushroom_purple", "Purple Mushroom", {
    category = "mushroom",
    shadow = "shadow_medium",
    maxHealth = 150,
    resources = {},
    description = "Pull crops when harvested!",
    procGen = {weight = 3, distance = {1, 6}},

    tokenDestroyed = function(tok)
        worldutil.spawnShockwave(tok.x, tok.y, 0.2, 50, objects.Color.PURPLE)
        g.spawnEntity("token_sucker", tok.x, tok.y, 1)
    end
})

local SUCKING_POWER = 24
local SUCKING_RADIUS = 64
g.defineEntity("token_sucker", {
    init = function(ent, duration)
        duration = duration or 1
        ent.lifetime = duration
        ent.duration = duration
    end,
    update = function(ent, dt)
        local mul1 = math.sqrt(helper.clamp(math.sin(ent.lifetime / ent.duration * math.pi), 0, 1))
        local ww, wh = g.getWorldDimensions()
        local mx = ent.x
        local my = ent.y

        for _, gtok in ipairs(g.getMainWorld().tokens) do
            ---@cast gtok g.Token
            if not gtok.bossfight then
                local dist = helper.magnitude(gtok.y - my, gtok.x - mx)
                local mul2 = math.min(SUCKING_RADIUS / dist, 1)
                local power = mul1 * mul2 * SUCKING_POWER * dt
                local rot = math.atan2(gtok.y - my, gtok.x - mx)
                gtok.x = helper.clamp(gtok.x - math.cos(rot) * power, 0, ww)
                gtok.y = helper.clamp(gtok.y - math.sin(rot) * power, 0, wh)
            end
        end
    end,
    draw = function(ent)
        if g.isBeingSimulated() then
            return
        end

        local r, gc, b, a = love.graphics.getColor()
        local a2 = helper.clamp(math.sin(ent.lifetime / ent.duration * math.pi), 0, 1)
        love.graphics.setColor(0, 0, 0, a * a2 * 0.7)
        worldutil.drawWaveAnimation(ent.x, ent.y, 32, -g.getWorldTime())
        love.graphics.setColor(r, gc, b, a)
    end
})
