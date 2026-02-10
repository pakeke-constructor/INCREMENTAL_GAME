
do

g.defineToken("wheat_big", "Big Wheat", {
    category = "grass",
    resources = {
        bread = 8,
    },
    maxHealth = 200,
    procGen = {weight = 3, distance = {1, 5}, resource = "bread"}
})


g.defineToken("wheat_medium", "Wheat", {
    category = "grass",
    resources = {
        bread = 1,
    },
    maxHealth = 120,
    procGen = {weight = 4, distance = {0, 4}, resource = "bread"}
})

end



