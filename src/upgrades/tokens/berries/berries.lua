

g.defineStalk("stalk_1", {
    image = "stalk_1",
    growthpos = {
        {x=0, y=0},
    }
})


g.defineStalk("stalk_2", {
    image = "stalk_2",
    growthpos = {
        {x=0, y=-2},
    }
})


g.defineStalk("stalk_3", {
    image = "stalk_3",
    dontFlip = true,
    growthpos = {
        {x=9, y=-2},
        {x=-3, y=-11},
    }
})


g.defineStalk("stalk_4", {
    image = "stalk_3",
    dontFlip = true,
    growthpos = {
        {x=0,y=0},
    }
})




for _, berry in ipairs({"blue_berry", "flax_berry"}) do
    for i=1, 3 do
        local id = "stalk_"..tostring(i)

        local name = berry .. tostring(i) -- TODO. do this properly

        g.defineToken(berry .. "_"..i, name, {
            maxHealth = 10,
            growths = {stalk = id, growth = berry},
            resources = {money = 10},
        })
    end
end

