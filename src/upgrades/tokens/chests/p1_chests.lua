

local function defChest(id,name, def)
    def.category = "chest"
    def.particles = "wood"

    g.defineToken(id,name,def)
end



defChest("clay_pot", "Clay Pot", {
    maxHealth = 3,
    resources = {money = 20},
})


defChest("chest_small", "Small Chest", {
    maxHealth = 6,
    resources = {money = 50},
})


defChest("chest_big", "Big Chest", {
    maxHealth = 11,
    resources = {money = 100},
})


defChest("chest_golden", "Golden Chest", {
    maxHealth = 20,
    resources = {money = 100},
})



--[[

All of these chests are special;
their `resources` tables are SUPPOSED to be adjusted!

]]
defChest("chest_money", "Money Chest", {
    maxHealth = 7,
    resources = {money = 10},
})
defChest("chest_fish", "Fishy Chest", {
    maxHealth = 7,
    resources = {fish = 10},
})
defChest("chest_fabric", "Fabric Chest", {
    maxHealth = 7,
    resources = {fabric = 10},
})
defChest("chest_juice", "Juice Chest", {
    maxHealth = 7,
    resources = {juice = 10},
})
defChest("chest_bread", "Bread Chest", {
    maxHealth = 7,
    resources = {bread = 10},
})




g.defineUpgrade("better_chests", "Better Chests", {
    kind = "TOKEN_MODIFIER",
    description = "All chests earn %{1} more resources!",
    valueFormatter = {"+%d%%"},

    image = "chest_golden",

    maxLevel = 5,

    getValues = helper.percentageGetter(25, 50),

    getTokenResourceMultiplier = function(uinfo, level, tok)
        if tok.category == "chest" then
            local a=uinfo:getValues(level)
            return 1+(a/100)
        end
    end,

    drawUI = function(uinfo, level, x, y, w, h)
        -- use this for other stuff mayb?
        local dy = math.sin(love.timer.getTime()*3 + 2.1)*2
        g.drawImage("generic_increase_icon", x+w/4,y+h/4+dy)
    end
})

