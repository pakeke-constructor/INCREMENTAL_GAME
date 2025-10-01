

g.defineTokenUpgrade("grass_blades", "Grass Blades", {
    token = {
        resources = {money = 1},
        maxHealth = 3
    },
    upgrade = {
        prestige = 0,
        price = {money=3},
        x=1,y=1,
    }
})


g.defineTokenUpgrade("small_grass", "Small Grass", {
    token = {
        resources = {money = 3},
        maxHealth = 6
    },
    upgrade = {
        prestige = 0,
        price = {money=5},
        x=1,y=2,
    }
})


g.defineTokenUpgrade("thick_grass", "Thick Grass", {
    token = {
        resources = {money = 6},
        maxHealth = 10
    },
    upgrade = {
        prestige = 0,
        price = {money=10},
        x=1,y=3,
    }
})



g.defineTokenUpgrade("bamboo", "Bamboo", {
    token = {
        resources = {money = 15},
        maxHealth = 20
    },
    upgrade = {
        prestige = 0,
        price = {money=50},
        x=2,y=3,
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
        prestige = 0,
        price = {money=10},
        x=4,y=1,
    }
})


g.defineTokenUpgrade("basic_log", "Basic Log", {
    token = {
        resources = {
            money = 10,
            logs = 3,
        },

        maxHealth = 15
    },

    upgrade = {
        prestige = 0,
        price = {money=10},
        x=3,y=1,
    }
})



do

local X,Y = 2,-1
g.defineTokenUpgrade("happy_kitten", "Happy Kitten", {
    token = {
        resources = {
            money = 15,
        },
        maxHealth = 10
    },

    upgrade = {
        prestige = 0,
        price = {money=100},
        x=X-1,y=Y
    }
})


g.defineTokenUpgrade("happy_cat", "Happy Cat", {
    token = {
        resources = {
            money = 30,
        },
        maxHealth = 20
    },

    upgrade = {
        prestige = 0,
        price = {money = 400},
        x = X, y = Y
    }
})

g.defineTokenUpgrade("business_cat", "Business Cat", {
    token = {
        resources = {
            money = 300,
        },
        maxHealth = 50
    },

    upgrade = {
        prestige = 0,
        price = {money = 5000},
        x = X + 1, y = Y
    }
})

end


