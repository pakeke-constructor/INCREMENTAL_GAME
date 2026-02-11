

g.defineToken("wheat_big", "Big Wheat", {
    category = "grass",
    resources = {
        bread = 8,
    },
    maxHealth = 160,
    procGen = {weight = 3, distance = {1, 5}, resource = "bread"}
})


g.defineToken("wheat_medium", "Wheat", {
    category = "grass",
    resources = {
        bread = 1,
    },
    maxHealth = 90,
    procGen = {weight = 4, distance = {0, 4}, resource = "bread"}
})





g.defineToken("bread_carrot", "Carrot Bread", {
    resources = {
        bread = 40,
    },
    maxHealth = 200,
    procGen = {weight = 3, distance = {1, 5}, resource = "bread"}
})


g.defineToken("bread_loaf", "Bread Loaf", {
    resources = {
        bread = 30,
        money = 20
    },
    maxHealth = 200,
    procGen = {weight = 3, distance = {1, 5}, resource = "bread"}
})


g.defineToken("sugar_loaf", "Sugar Loaf", {
    resources = {
        bread = 20,
        money = 50
    },
    maxHealth = 200,
    procGen = {weight = 3, distance = {1, 5}, resource = "bread"}
})

