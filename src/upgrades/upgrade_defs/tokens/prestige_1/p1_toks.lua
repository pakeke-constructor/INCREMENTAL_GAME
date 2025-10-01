

g.defineTokenUpgrade("grass_blades", "Grass Blades", {
    token = {
        resources = {money = 1},
        maxHealth = 5
    },
    upgrade = {
        prestige = 0,
        price = {money=1},
        x=1,y=1,
    }
})


g.defineTokenUpgrade("small_grass", "Small Grass", {
    token = {
        resources = {money = 2},
        maxHealth = 8
    },
    upgrade = {
        prestige = 0,
        price = {money=5},
        x=1,y=2,
    }
})


g.defineTokenUpgrade("thick_grass", "Thick Grass", {
    token = {
        resources = {money = 4},
        maxHealth = 15
    },
    upgrade = {
        prestige = 0,
        price = {money=100},
        x=1,y=3,
    }
})




g.defineTokenUpgrade("basic_log", "Basic Log", {
    token = {
        resources = {
            money = 5,
            logs = 1,
        },

        maxHealth = 15
    },

    upgrade = {
        prestige = 0,
        price = {money=10},
        x=2,y=1,
    }
})



