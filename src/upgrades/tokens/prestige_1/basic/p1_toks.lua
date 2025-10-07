

g.defineTokenUpgrade("grass_blades", "Grass Blades", {
    token = {
        particles = "grass",
        resources = {money = 1},
        maxHealth = 3
    },
    upgrade = {
        startingUpgrade=true,
        price = {money=3},
    }
})


g.defineTokenUpgrade("small_grass", "Small Grass", {
    token = {
        particles = "grass",
        resources = {money = 3},
        maxHealth = 6
    },
    upgrade = {
        price = {money=5},
    }
})


g.defineTokenUpgrade("thick_grass", "Thick Grass", {
    token = {
        particles = "grass",
        resources = {money = 6},
        maxHealth = 8
    },
    upgrade = {
        price = {money=10},
    }
})



g.defineTokenUpgrade("bamboo", "Bamboo", {
    token = {
        resources = {money = 15},
        maxHealth = 12
    },
    upgrade = {
        price = {money=50},
    }
})





g.defineTokenUpgrade("stick", "Stick", {
    token = {
        resources = {
            logs = 1,
        },

        maxHealth = 5
    },

    upgrade = {
        price = {money=10},
    }
})


g.defineTokenUpgrade("basic_log", "Basic Log", {
    token = {
        resources = {
            money = 10,
            logs = 3,
        },

        maxHealth = 10
    },

    upgrade = {
        price = {money=10},
    }
})



do

g.defineTokenUpgrade("happy_kitten", "Happy Kitten", {
    token = {
        resources = {
            money = 15,
        },
        maxHealth = 8
    },

    upgrade = {
        price = {money=100},
    }
})


g.defineTokenUpgrade("happy_cat", "Happy Cat", {
    token = {
        resources = {
            money = 30,
        },
        maxHealth = 10
    },

    upgrade = {
        price = {money = 400},
    }
})

g.defineTokenUpgrade("business_cat", "Business Cat", {
    token = {
        resources = {
            money = 300,
        },
        maxHealth = 15
    },

    upgrade = {
        price = {money = 5000},
    }
})

end


