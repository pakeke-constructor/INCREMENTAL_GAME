

g.defineStalk("stalk_1", {
    image = "stalk_1",
    growthpos = {
        {x=0, y=-2},
    }
})


g.defineStalk("stalk_2", {
    image = "stalk_2",
    growthpos = {
        {x=0, y=-4},
    }
})


g.defineStalk("stalk_3", {
    image = "stalk_3",
    dontFlip = true,
    growthpos = {
        {x=9, y=-4},
        {x=-1, y=-12},
    }
})



g.defineStalk("stalk_4", {
    image = "stalk_4",
    growthpos = {
        {x=8,y=-2},
        {x=-6,y=-7},
        {x=-4,y=4},
    }
})


g.defineStalk("stalk_5", {
    image = "stalk_5",
    dontFlip = true,
    growthpos = {
        {x=1, y=-2},
        {x=-1, y=-16},
        {x=1, y=-30},
    }
})

for i=1, 5 do
    local base = g.getStalkInfo("stalk_"..i)
    g.defineStalk("fish_stalk_"..i, {
        image = base.image,
        dontFlip = base.dontFlip,
        growthpos = base.growthpos,
        growthOy = -2,
    })
end


local BERRIES = {
    {
        id = "blue_berry",
        name = "Blueberry",
        resources = {money = 4}
    },
    {
        id = "red_berry",
        name = "Redberry",
        resources = {money = 10}
    },
    {
        id = "flax_berry",
        name = "Flaxberry",
        resources = {bread = 1}
    },
    {
        id = "purple_berry",
        name = "Purpleberry",
        -- TODO: Maybe in future, purpleBerry should yield fabric?
        resources = {money = 20}
    },
    {
        id = "dark_berry",
        name = "Darkberry",
        resources = {money = 30}
    },
    {
        id = "melon_berry",
        name = "Melonberry",
        resources = {juice = 2}
    },

    {
        id = "cod_fish",
        name = "Cod",
        resources = {fish = 2},
        stalk = "fish_stalk",
    },
}


local RESOURCE_MULTIPLIERS = {
    1, 2, 5, 20,25
}

local TOKEN_HEALTHS = {
    120,140, 180, 200,220
}

local MAX_LEVELS = {
    -- whats the maximum level each tier can go up to?
    15,10, 8, 5,3
}


local PROCGEN_WEIGHTS = {5, 4, 3, 2, 2}
local PROCGEN_DISTS = {{0,3}, {1,5}, {2,6}, {3,8}, {4,10}}


local function makeId(berry, i)
    return berry.id .. "_" .. tostring(i)
end


local STALK_NAMES = {
    "seedling",
    "shrub",
    "sprout",
    "bush",
    "vine",
}

local function makeName(berry, i)
    return berry.name .. " " .. STALK_NAMES[i]
end


for _, berry in ipairs(BERRIES) do
    -- define berry-tokens:
    for i=1, 5 do
        local token_id = makeId(berry,i)
        local name = makeName(berry,i)

        local mult = RESOURCE_MULTIPLIERS[i]

        local desc = nil

        local stalk_id = (berry.stalk or "stalk") .. "_" .. tostring(i)
        g.defineToken(token_id, name, {
            growths = {stalk = stalk_id, growth = berry.id},
            resources = g.multBundles(berry.resources, mult),
            maxLevel = MAX_LEVELS[i],
            maxHealth = TOKEN_HEALTHS[i],

            description = desc,

            procGen = {
                weight = PROCGEN_WEIGHTS[i],
                distance = PROCGEN_DISTS[i],
                needs = i > 1 and makeId(berry, 1) or nil
            }
        })
    end

    g.defineUpgrade("improved_berry_"..berry.id, "Improved " .. berry.name, {
        image = "improved_berries",
        kind = "TOKEN_MODIFIER",

        description = "Earn +%{1} {money} when harvesting {" .. berry.id .. "} crops",

        drawUI = function (uinfo, level, x, y, w, h)
            local dy = 2*math.sin(love.timer.getTime()*2)
            g.drawImage(berry.id, x+w-6,y+6+dy, 0)
        end,
        getTokenResourceModifier = function(uinfo,level, tok)
            if tok.growths and tok.growths.growth == berry.id then
                local val = uinfo:getValues(level)
                return {money = val}
            end
        end,
        getValues = helper.valueGetter(3,3),
        procGen = {
            weight = 2,
            distance = {3, 8},
            needs = berry.id .. "_1"
        }
    })
end


