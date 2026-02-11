

local function defJuicy(id, name, def)
    g.defineToken(id, name, def)
end



defJuicy("basic_apple", "Apple", {
    resources = {juice = 1},
    maxHealth = 80,
    procGen = {
        weight = 4,
        distance = {0, 3},
        resource = "juice"
    }
})


defJuicy("crab_apple", "Crab Apple", {
    resources = {juice = 4},
    maxHealth = 110,
    procGen = {
        weight = 3,
        distance = {1, 5},
        resource = "juice"
    }
})


defJuicy("raspberry_bunch", "Raspberry Bunch", {
    resources = {juice = 10},
    shadow = "shadow_big",
    maxHealth = 140,
    procGen = {
        weight = 2,
        distance = {2, 7},
        resource = "juice"
    }
})
