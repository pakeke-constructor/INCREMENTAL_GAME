

g.defineToken("grass_blades", "Grass Blades", {
    particles = "grass",
    category = "grass",
    shadow = "shadow_small",
    resources = {money = 1},
    maxHealth = 3
})


g.defineToken("small_grass", "Small Grass", {
    particles = "grass",
    category = "grass",
    resources = {money = 3},
    maxHealth = 6
})


g.defineToken("thick_grass", "Thick Grass", {
    particles = "grass",
    category = "grass",
    resources = {money = 6},
    shadow = "shadow_big",
    maxHealth = 8
})



g.defineToken("bamboo", "Bamboo", {
    category = "wood",
    resources = {money = 15},
    maxHealth = 12
})





g.defineToken("stick", "Stick", {
    category = "wood",
    resources = {
    },

    maxHealth = 5
})


g.defineToken("basic_log", "Basic Log", {
    category = "wood",
    resources = {
        money = 10,
    },

    maxHealth = 10
})



do

g.defineToken("happy_kitten", "Happy Kitten", {
    category = "cat",
    resources = {
        money = 15,
    },
    maxHealth = 8
})


g.defineToken("happy_cat_token", "Happy Cat", {
    category = "cat",
    resources = {
        money = 30,
    },
    maxHealth = 10
})
end

