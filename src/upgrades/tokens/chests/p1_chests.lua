

local function defChest(id,name, def)
    def.category = "chest"
    def.particles = "wood"

    g.defineToken(id,name,def)
end



defChest("clay_pot", "Clay Pot", {
    maxHealth = 60,
    resources = {money = 20},
    procGen = {weight = 3, distance = {1, 6}}
})


defChest("chest_small", "Small Chest", {
    maxHealth = 120,
    resources = {money = 50},
    procGen = {weight = 3, distance = {1, 5}}
})


defChest("chest_big", "Big Chest", {
    maxHealth = 220,
    resources = {money = 100},
    procGen = {weight = 2, distance = {2, 6}}
})


defChest("chest_golden", "Golden Chest", {
    maxHealth = 400,
    resources = {money = 300},
    procGen = {weight = 1, distance = {3, 8}}
})



--[[

All of these chests are special;
their `resources` tables are SUPPOSED to be adjusted!

]]
defChest("chest_money", "Money Chest", {
    maxHealth = 140,
    resources = {money = 10},
    procGen = {weight = 2, distance = {2, 7}, resource = "money"}
})
defChest("chest_fish", "Fishy Chest", {
    maxHealth = 140,
    resources = {fish = 10},
    procGen = {weight = 2, distance = {2, 7}, resource = "fish"}
})
defChest("chest_fabric", "Fabric Chest", {
    maxHealth = 140,
    resources = {fabric = 10},
    procGen = {weight = 2, distance = {2, 7}, resource = "fabric"}
})
defChest("chest_juice", "Juice Chest", {
    maxHealth = 140,
    resources = {juice = 10},
    procGen = {weight = 2, distance = {2, 7}, resource = "juice"}
})
defChest("chest_bread", "Bread Chest", {
    maxHealth = 140,
    resources = {bread = 10},
    procGen = {weight = 2, distance = {2, 7}, resource = "bread"}
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
    end,
    procGen = {weight = 2, distance = {3, 8}}
})

