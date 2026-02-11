



-- Spawn a {bomb/crop/chest/lightning} for every 10 {grass/berry} harvested

---@class _.every_x_ACTION
local ACTIONS = {
    {id = "lightning", name="Lightning", description="spawn lightning!", func = function(tok)
        worldutil.spawnLightning(tok.x, tok.y)
    end, image="lightning_icon"},
    {id = "bombs", name="Bombs", description="spawn a bomb!", func = function(tok)
        g.spawnToken("bomb",tok.x,tok.y)
    end, image="bomb"},
    {id = "chests", name="Chests", description="spawn a random chest!", func = function(tok)
        local x,y = g.getRandomPositionForToken()
        if x and y then
            if love.math.random() < 0.5 then
                g.spawnToken("chest_big", x,y)
            else
                g.spawnToken("chest_small", x,y)
            end
        end
    end, image="chest_small"},
    {id = "money_bonus", name="Bonuses", description="earn +10 {money}", func = function(tok)
        g.addResource("money", 10)
    end,image="money"},
    {id = "xp_bonus", name="Experience", description="earn +10 experience", func = function(tok)
        local sn = g.getSn()
        sn.xp = sn.xp + 10
    end, image="xp_increase_icon"},
}


---@class _.every_x_CATEGORY
local CATEGORIES = {
    {id = "mushroom", name="Mushroom",plural="mushrooms", count=20, image="mushroom_red"},
    {id = "grass", name="Grassy",plural="grass", count=50, image="grass_3"},
    {id = "berry", name="Berry",plural="berries", count=50, image="blue_berry"},
    {id = "wheat", name="Wheat",plural="wheat", count=30, image="wheat_big"},
}


for _,action in ipairs(ACTIONS) do
    for _,category in pairs(CATEGORIES) do
        local id = "every_x_" .. category.id .. "_do_" .. action.id
        local name = category.name .. " " .. action.name -- eg:  "Mushroom Bombs"
        local description = ("Every %{1} ".. category.plural .." harvested, ") .. action.description

        g.defineUpgrade(id, name, {
            image = "null_image",

            kind = "HARVESTING",
            maxLevel = 4,

            description = description,

            getValues = function (uinfo, level)
                local count = category.count
                if count > 5 then
                    return category.count - level*5
                end
                return category.count - level*2
            end,

            tokenDestroyed = function(uinfo,level, tok)
                if tok.category == category.id then
                    local count = uinfo:getValues(level)
                    local numDestroyed = g.getTokensDestroyedInCategory(category.id)
                    if numDestroyed%count == 0 then
                        action.func(tok)
                    end
                end
            end,
            drawUI = function(uinfo, level, x, y, w, h)
                local t1 = love.timer.getTime()/2
                local t2 = t1 + math.pi

                local cx,cy = x+w/2, y+h/2
                local rad = w/4

                local x1,y1 = cx+rad*math.sin(t1), cy+rad*math.cos(t1)
                local x2,y2 = cx+rad*math.sin(t2), cy+rad*math.cos(t2)

                g.drawImage(action.image, x1,y1)
                g.drawImage(category.image, x2,y2)
            end,
            procGen = {
                weight = 25,
                distance = {4, 7}
            }
        })
    end
end

