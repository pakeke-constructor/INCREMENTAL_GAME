

g.defineTokenUpgrade("grass_blades", "Grass Blades", {
    token = {
        particles = "grass",
        category = "grass",
        resources = {money = 1},
        maxHealth = 3
    },
    upgrade = {
        startingUpgrade=true,
    }
})


g.defineTokenUpgrade("small_grass", "Small Grass", {
    token = {
        particles = "grass",
        category = "grass",
        resources = {money = 3},
        maxHealth = 6
    },
    upgrade = {}
})


g.defineTokenUpgrade("thick_grass", "Thick Grass", {
    token = {
        particles = "grass",
        category = "grass",
        resources = {money = 6},
        maxHealth = 8
    },
    upgrade = {}
})



g.defineTokenUpgrade("bamboo", "Bamboo", {
    token = {
        category = "wood",
        resources = {money = 15},
        maxHealth = 12
    },
    upgrade = {}
})





g.defineTokenUpgrade("stick", "Stick", {
    token = {
        category = "wood",
        resources = {
        },

        maxHealth = 5
    },

    upgrade = {}
})


g.defineTokenUpgrade("basic_log", "Basic Log", {
    token = {
        category = "wood",
        resources = {
            money = 10,
        },

        maxHealth = 10
    },

    upgrade = {
    }
})



do

g.defineTokenUpgrade("happy_kitten", "Happy Kitten", {
    token = {
        category = "cat",
        resources = {
            money = 15,
        },
        maxHealth = 8
    },

    upgrade = {
    }
})


g.defineTokenUpgrade("happy_cat", "Happy Cat", {
    token = {
        category = "cat",
        resources = {
            money = 30,
        },
        maxHealth = 10
    },

    upgrade = {
    }
})

g.defineTokenUpgrade("business_cat", "Business Cat", {
    token = {
        category = "cat",
        resources = {
            money = 300,
        },
        maxHealth = 15
    },

    upgrade = {
    }
})

end

