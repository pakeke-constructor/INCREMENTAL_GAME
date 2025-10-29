

g.defineTokenUpgrade("grass_blades", "Grass Blades", {
    token = {
        particles = "grass",
        category = "grass",
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
        category = "grass",
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
        category = "grass",
        resources = {money = 6},
        maxHealth = 8
    },
    upgrade = {
        price = {money=10},
    }
})



g.defineTokenUpgrade("bamboo", "Bamboo", {
    token = {
        category = "wood",
        resources = {money = 15},
        maxHealth = 12
    },
    upgrade = {
        price = {money=50},
    }
})





g.defineTokenUpgrade("stick", "Stick", {
    token = {
        category = "wood",
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
        category = "wood",
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
        category = "cat",
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
        category = "cat",
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
        category = "cat",
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



do

g.defineTokenUpgrade("pebbles", "Pebbles", {
    token = {
        category = "rock",
        resources = {rocks = 1},
        maxHealth = 8
    },
    upgrade = {
        price = {money = 40}
    }
})

g.defineTokenUpgrade("small_rock", "Rock", {
    token = {
        category = "rock",
        resources = {rocks = 5},
        maxHealth = 18
    },
    upgrade = {
        price = {money = 90}
    }
})

g.defineTokenUpgrade("big_rock", "Big Rock", {
    token = {
        category = "rock",
        resources = {rocks = 10},
        maxHealth = 34
    },
    upgrade = {
        price = {money = 200}
    }
})

end
