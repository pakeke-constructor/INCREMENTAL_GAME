

g.defineTokenUpgrade("basic_grass", "Basic Grass", {
    token = {
        resources = {money = 1},
        maxHealth = 4
    },
    upgrade = {
        description = loc"hi",
        prestige = 0,
        price = {money=1},
        x=1,y=1,
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



