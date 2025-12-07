

g.defineToken("clay_pot", "Clay Pot", {
    maxHealth = 3,
    category = "chest",
    resources = {money = 20},
})


g.defineToken("chest_small", "Small Chest", {
    maxHealth = 6,
    category = "chest",
    resources = {money = 50},
})


g.defineToken("chest_big", "Big Chest", {
    maxHealth = 11,
    category = "chest",
    resources = {money = 100},
})


g.defineToken("chest_golden", "Golden Chest", {
    maxHealth = 20,
    category = "chest",
    resources = {money = 100},
})



--[[

All of these chests are special;
their `resources` tables are SUPPOSED to be adjusted!

]]
g.defineToken("chest_money", "Money Chest", {
    maxHealth = 7,
    category = "chest",
    resources = {money = 10},
})
g.defineToken("chest_fish", "Fishy Chest", {
    maxHealth = 7,
    category = "chest",
    resources = {fish = 10},
})
g.defineToken("chest_fabric", "Fabric Chest", {
    maxHealth = 7,
    category = "chest",
    resources = {fabric = 10},
})
g.defineToken("chest_juice", "Juice Chest", {
    maxHealth = 7,
    category = "chest",
    resources = {juice = 10},
})
g.defineToken("chest_bread", "Bread Chest", {
    maxHealth = 7,
    category = "chest",
    resources = {bread = 10},
})
