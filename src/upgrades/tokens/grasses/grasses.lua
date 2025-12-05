

local function defGrass(id,name,def)
    def.particles="grass"
    def.category="grass"
    g.defineToken(id,name,def)
end



defGrass("grass_1", "Grass (I)", {
    shadow = "shadow_small",
    resources = {money = 1},
    maxHealth = 3
})


defGrass("grass_2", "Grass (II)", {
    resources = {money = 3},
    maxHealth = 6
})


defGrass("grass_3", "Grass (III)", {
    resources = {money = 10},
    shadow = "shadow_big",
    maxHealth = 8
})


defGrass("grass_4", "Grass (IV)", {
    resources = {money = 50},
    shadow = "shadow_big",
    maxHealth = 12
})



