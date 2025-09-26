

g.defineToken("basic_grass", {
    image = "basic_grass",

    resources = {money = 1},

    maxHealth = 4
})

g.defineUpgrade("basic_grass", {
    image = "basic_grass",
    prestige = 0,

    price = {money=1},

    populateTokenPool = function(level, tokens)
        tokens:add("basic_grass", level)
    end,

    x=1,y=1,

    description = loc"hi",
})






g.defineToken("basic_log", {
    image = "basic_log",

    resources = {
        money = 5,
        logs = 1,
    },

    maxHealth = 15
})

g.defineUpgrade("basic_log", {
    image = "basic_log",
    prestige = 0,

    price = {money=10},

    x=2,y=1,
})


