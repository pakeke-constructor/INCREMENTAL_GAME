

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
        resources = {money = 40}
    },
}


local RESOURCE_MULTIPLIERS = {
    1, 2, 5, 20,25
}
local MAX_LEVELS = {
    -- whats the maximum level each tier can go up to?
    15,10, 8, 10,10
}
local TOKEN_HEALTHS = {
    4,5, 9, 15,18
}

local MAX_LEVELS = {
    15,10, 8, 5,3
}

local DEPOPULATE_TOKEN = {
    -- should this upgrade depopulate any of the earlier upgrades?
    nil,nil,nil, 1,2
}


local function makeId(berry, i)
    return berry.id .. "_" .. tostring(i)
end


for _, berry in ipairs(BERRIES) do
    -- define berry-tokens:
    for i=1, 5 do
        local token_id = makeId(berry,i)
        local name = berry.name .. " ("..tostring(i)..")"

        local mult = RESOURCE_MULTIPLIERS[i]

        ---@param tp g.TokenPool
        local depopulateTokenPool = DEPOPULATE_TOKEN[i] and function (uinfo, level, tp)
            local depopId = DEPOPULATE_TOKEN[i]
            local strId = makeId(berry, depopId)
            tp:subtract(strId)
        end

        local stalk_id = "stalk_"..tostring(i)
        g.defineToken(token_id, name, {
            growths = {stalk = stalk_id, growth = berry.id},
            resources = g.multBundles(berry.resources, mult),
            maxLevel = MAX_LEVELS[i],
            maxHealth = TOKEN_HEALTHS[i],

            upgradeDefinition = {
                ---@diagnostic disable-next-line
                depopulateTokenPool = depopulateTokenPool
            }
        })
    end

    g.defineUpgrade("improved_berry_"..berry.id, "Improved " .. berry.name, {
        image = "improved_berries",
        kind = "TOKEN_MODIFIER",

        description = "Earn +%{1} {money} from {" .. berry.id .. "}",

        drawUI = function (uinfo, level, x, y, w, h)
            local dy = 4*math.sin(love.timer.getTime())
            g.drawImage(berry.id, x+w-4,y+4+dy, 0)
        end,
        getTokenResourceModifier = function(uinfo,level, tok)
            if tok.growths and tok.growths.growth == berry.id then
                return {money = level}
            end
        end,
        getValues = helper.valueGetter(3,3)
    })
end


