--[[

==================
PLANNING:
==================


TENETS:

- We want rewards to *feel* exciting.
- Decisions should feel somewhat meaningful.
- Have proc-genned rewards.


HOW TO ACHIEVE:
- Hardcoded early-game rewards?
- "tiers" or rarity for rewards?


REWARD TYPES:
- TEMPORARY REWARDS (resource-bundle, stacked-token, etc)
- PERMANENT REWARDS (permanent token, permanent upgrade)

When the player chooses between rewards, they either choose between
- 3 permanent rewards
- OR, 3 instant rewards.
DON'T MIX THEM!!! Or else balancing is a nightmare,
and players will always choose the permanent ones.


IDEAS:
- COMMON: +Resource bundle
- COMMON: Simple permanent stat increase
- COMMON: Grants temporary effect (g.grantEffect)
- RARE: Grants a bunch of stacked-tokens that give BIG rewards :)
- RARE: Exotic permanent stat increase:
    - Deal +1 damage to grass-tokens
    - When lightning strikes, 
- RARE: Permanent New Token
- UNIQUE: One-time upgrades, like "get new scythe!"

]]


local lg=love.graphics

local rewards = {}


---@alias g.RewardType
---Permanent Rewards
---| "permanent"
---Free Resources
---| "resource"
---Scythe Upgrades
---| "scythe"
---Potions/Temporary Effects
---| "effect"
---Stacked Token
---| "token"
---Instant, with custom behavior
---| "instant"
local REWARD_TYPE = {
    permanent = true,
    resource = true,
    scythe = true,
    effect = true,
    token = true,
    instant = true,
}

---@class g.Reward
---@field icon string
---@field type g.RewardType

---@class g.PermanentReward: g.Reward
---@field type "permanent"
---@field upgradeId string The id of a permanent reward

---@class g.ResourceReward: g.Reward
---@field type "resource"
---@field resources g.Bundle only for resource-rewards

---@class g.ScytheReward: g.Reward
---@field type "scythe"

---@class g.EffectReward: g.Reward
---@field type "effect"
---@field effect g.EffectInfo only for effect-rewards
---@field duration number (also effect-rewards)

---@class g.TokenReward: g.Reward
---@field type "token"
---@field token g.TokenInfo gives a stacked-token reward immediately
---@field count integer
---@field description string?
---@field resource {id:g.ResourceType, amount:number}? If the resource is modified on spawn, specify correct total amount here
---@field spawnFunc? fun(tok:g.Token)

---@class g.InstantReward: g.Reward
---@field type "instant"
---@field name string
---@field description string
---@field func function



---@generic T: g.Reward
---@param rew T
---@return T
local function assertRewardIsValid(rew)
    ---@cast rew g.Reward
    helper.assert(REWARD_TYPE[rew.type], "invalid reward type", rew.type)
    assert(rew.icon)

    if rew.type == "permanent" then
        ---@cast rew g.PermanentReward
        assert(rew.upgradeId, "Need upgrade id")
        g.getUpgradeInfo(rew.upgradeId) -- assertion
    elseif rew.type == "resource" then
        ---@cast rew g.ResourceReward
        assert(rew.resources, "Need resources")
        for k in pairs(rew.resources) do
            g.getResourceInfo(k) -- assertion
        end
    elseif rew.type == "effect" then
        ---@cast rew g.EffectReward
        assert(rew.effect, "Need effect ID")
        assert(rew.duration, "Effects need a duration")
    elseif rew.type == "token" then
        ---@cast rew g.TokenReward
        assert(rew.token, "stackedToken need token")
        assert(rew.count, "stackedToken rewards need a count")
        if not (rew.resource or rew.description) then
            error("stackedToken rewards need either description, or resource: " .. tostring(rew.token.type))
        end
    elseif rew.type == "instant" then
        ---@cast rew g.InstantReward
        assert(rew.name, "instant need name")
        assert(rew.description, "instant need description")
        assert(rew.func, "instant need function")
    end

    return rew
end


---@param rng love.RandomGenerator
---@return string
local function getRandomUnlockedResource(rng)
    local buf = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if g.isResourceUnlocked(resId) then
            table.insert(buf, resId)
        end
    end
    local resId = helper.randomChoice(buf, rng and function(max) return rng:random(max) end)
    return resId or "money"
end


---@param resId string
---@return number
local function getMostExpensiveUpgPrice(resId)
    local tree = g.getUpgTree()
    local upgs = tree:getUpgradesOnTree()
    local best = 0
    for _,upg in ipairs(upgs) do
        if upg.level > 0 then
            best = math.max(upg.basePrice[resId] or 0, best)
        end
    end
    return best
end




---@param rng love.RandomGenerator
local function generateResourceReward(rng)
    local resId = getRandomUnlockedResource(rng)
    local amount = getMostExpensiveUpgPrice(resId) / 10
    local resAmount = math.max(30, math.floor(amount / 5) * 5)
    if love.math.random() < 0.3 then
        resAmount = resAmount * 2
    end

    local resources = {}
    resources[resId] = resAmount
    ---@type g.ResourceReward
    local rew = {
        type = "resource",
        icon = "resource_bundle_reward",
        resources = resources
    }
    return assertRewardIsValid(rew)
end


---@type table<string, g.InstantReward>
local INSTANT_REWARDS = {
    slime_apocalypse = {
        type = "instant",
        icon = "slime_token",
        name = loc "Slime Apocalypse",
        description = loc "Slime all crops!\n(Slimed crops take extra damage!)",
        func = function()
            for _, tok in ipairs(g.getMainWorld().tokens) do
                ---@cast tok g.Token
                g.slimeToken(tok)
            end
        end
    },
    grim_reaper = {
        type = "instant",
        icon = "amethyst_scythe",
        name = loc "Grim Reaper",
        description = loc "Harvests all crops instantly!",
        func = function()
            for _, tok in ipairs(g.getMainWorld().tokens) do
                ---@cast tok g.Token
                g.damageToken(tok, 2147483647)
            end
        end
    },
    eclipse = {
        type = "instant",
        icon = "star_upgrade",
        name = loc "Eclipse",
        description = loc "Stars all crops!\n(Starred crops earn triple resources!)",
        func = function()
            ---@type g.Token[]
            local toks = {}
            for _, tok in ipairs(g.getMainWorld().tokens) do
                toks[#toks+1] = tok
            end
            helper.shuffle(toks)
            for i = 1, math.floor(#toks / 3) do
                g.starToken(toks[i])
            end
        end
    },
    grass_1_infestation = {
        type = "instant",
        icon = "grass_1",
        name = loc "Grass (I)",
        description = loc "+30 {grass_1} crops for 15 seconds!",
        func = function()
            g.grantEffect("grass_1_infestation", 15)
        end
    },
    grass_2_infestation = {
        type = "instant",
        icon = "grass_2",
        name = loc "Grass (II)",
        description = loc "+20 {grass_2} crops for 15 seconds!",
        func = function()
            g.grantEffect("grass_2_infestation", 15)
        end
    },
    blue_grass_1_infestation = {
        type = "instant",
        icon = "blue_grass_1",
        name = loc "Blue Grass (I)",
        description = loc "+30 {blue_grass_1} crops for 15 seconds!",
        func = function()
            g.grantEffect("blue_grass_1_infestation", 15)
        end
    },
    blue_grass_2_infestation = {
        type = "instant",
        icon = "blue_grass_2",
        name = loc "Blue Grass (II)",
        description = loc "+20 {blue_grass_2} crops for 15 seconds!",
        func = function()
            g.grantEffect("blue_grass_2_infestation", 15)
        end
    },
    knife_swarm = {
        type = "instant",
        icon = "knife",
        name = loc "Knife swarm!",
        description = loc "Shoots out knives for 15 seconds!",
        func = function()
            g.grantEffect("knife_swarm", 15)
        end
    },
    scythe_swarm = {
        type = "instant",
        icon = "iron_scythe",
        name = loc "Scythe swarm!",
        description = loc "Shoots out scythes for 15 seconds!",
        func = function()
            g.grantEffect("scythe_swarm", 15)
        end
    },
    explosion_swarm = {
        type = "instant",
        icon = "explosion_swarm",
        name = loc "Explosion swarm!",
        description = loc "Cause explosions for 15 seconds!",
        func = function()
            g.grantEffect("explosion_swarm", 15)
        end
    },
    farmer_cats = {
        type = "instant",
        icon = "grass_farmer_cat",
        name = loc "Farmer Cats!",
        description = loc "Temporarily hire farmer cats for 15 seconds!",
        func = function()
            local w,h = g.getWorldDimensions()
            for i=1,6 do
                local x = helper.lerp(20,w-20, love.math.random())
                local y = helper.lerp(20,h-20, love.math.random())
                local e = g.spawnEntity("grass_farmer_cat", x,y)
                e.lifetime = 15
            end
            for i=1,4 do
                local x = helper.lerp(20,w-20, love.math.random())
                local y = helper.lerp(20,h-20, love.math.random())
                local e = g.spawnEntity("lumberjack_cat", x,y)
                e.lifetime = 15
            end
        end
    },
    knife_cats = {
        type = "instant",
        icon = "knife_cat",
        name = "{c r=0.9 b=0.6 g=0.2}" .. loc "Knife Cats!",
        description = loc("Temporarily hire cats with knives for 15 seconds!", {
            context = "Cats that run around the map temporarily, throwing knives and harvesting crops"
        }),
        func = function()
            local w,h = g.getWorldDimensions()
            for i=1,10 do
                local x = helper.lerp(20,w-20, love.math.random())
                local y = helper.lerp(20,h-20, love.math.random())
                local e = g.spawnEntity("knife_cat", x,y)
                e.lifetime = 15
            end
        end
    },
    bomber_cats = {
        type = "instant",
        icon = "demolition_cat",
        name = "{c r=0.9 b=0.6 g=0.2}" .. loc "Bomber Cats!",
        description = loc("Temporarily hire cats with bombs for 15 seconds!", {
            context = "Cats that run around map temporarily, dropping bombs and harvesting crops"
        }),
        func = function()
            local w,h = g.getWorldDimensions()
            for i=1,8 do
                local x = helper.lerp(20,w-20, love.math.random())
                local y = helper.lerp(20,h-20, love.math.random())
                local e = g.spawnEntity("planter_cat_bomb", x,y)
                e.lifetime = 15
            end
        end
    },
    black_cube = {
        type = "instant",
        icon = "blackhole_effect",
        name = loc "Black Cube",
        description = loc "Pull crops towards mouse position for 15 seconds!",
        func = function()
            g.grantEffect("black_cube", 15)
        end
    },
}


---@class _TOKEN_REWARDS.reward
---@field public icon string
---@field public token string
---@field public name string
---@field public count {min:integer, max:integer}
---@field public resource {id: g.ResourceType, amount:number}
---@field public description string?
local _TOKEN_REWARDS_rew={}

---@type _TOKEN_REWARDS.reward[]
local TOKEN_REWARDS = {
    bomb = {
        icon = "bomb",
        token = "bomb",
        name = loc"Flying Bombs!",
        description = loc"A bunch of flying bombs!",
        count = {min = 15, max=20}
    },
    slime = {
        icon = "slime_token",
        token = "slime_token",
        name = loc"Flying slime!",
        description = loc"Slime weakens crops!",
        count = {min = 10, max=15}
    },
    mushroom_red = {
        token = "mushroom_red",
        icon = "mushroom_red",
        name = "Red Mushroom",
        description = loc("Red mushrooms will explode!"),
        count = {min = 10, max=15}
    },
    mushroom_green = {
        token = "mushroom_green",
        icon = "mushroom_green",
        name = "Green Mushroom",
        description = loc("Green mushrooms spawn grass!"),
        count = {min = 6, max=12}
    },
    mushroom_blue = {
        token = "mushroom_blue",
        icon = "mushroom_blue",
        name = "Blue Mushroom",
        description = loc("Blue mushrooms spawn lightning!"),
        count = {min = 10, max=15}
    },
}





---@param rng love.RandomGenerator
local function generateInstantReward(rng)
    local validRewards = {}
    for _, reward in pairs(INSTANT_REWARDS) do
        table.insert(validRewards, reward)
    end
    return helper.randomChoice(validRewards, function(max) return rng:random(max) end)
end



local generatePotionReward
do

local statPots = {}

for i=1,3 do
    table.insert(statPots, "hit_speed_" .. i)
    table.insert(statPots, "hit_damage_" .. i)
    table.insert(statPots, "harvest_area_" .. i)
    table.insert(statPots, "faster_spawn_" .. i)
    table.insert(statPots, "xp_" .. i)
    table.insert(statPots, "goldmine_" .. i)
end

---@param rng love.RandomGenerator
function generatePotionReward(rng)
    local potionId = helper.randomChoice(statPots, function(max) return rng:random(max) end)
    local einfo = g.getEffectInfo(potionId)
    ---@type g.EffectReward
    local rew = {
        type = "effect",
        effect = einfo,
        duration = 20 + rng:random(-5, 5),
        icon = einfo.image
    }
    return assertRewardIsValid(rew)
end

end


local generateStackedTokenReward
do


---@param resId g.ResourceType
---@param rng love.RandomGenerator
local function generateStackedChestToken(resId, rng)
    local prc = math.max(getMostExpensiveUpgPrice(resId) / 5, 20)
    local resAmount = math.max(1, 5*(math.floor(prc / 5)) / 10)
    if love.math.random() < 0.3 then
        resAmount = resAmount * 2
    end
    ---@type g.TokenReward
    local rew = {
        type = "token",
        ---@param tok g.Token
        spawnFunc = function(tok)
            tok.resources = {
                [resId] = resAmount
            }
            worldutil.initializeFlyingTokenWithPos(tok, 8 + rng:random()*3)
        end,
        token = g.getTokenInfo("chest_"..resId),
        count = math.floor(rng:random(8, 20) / 2) * 2,
        resource = {
            id = resId,
            amount = resAmount
        },
        icon = "chest_"..resId
    }
    return assertRewardIsValid(rew)
end


---@param entry _TOKEN_REWARDS.reward
---@param rng love.RandomGenerator
local function generateStackedGenericToken(entry, rng)
    local tokinfo = assert(g.getTokenInfo(entry.token))
    ---@type g.TokenReward
    local rew = {
        type = "token",
        token = tokinfo,
        resource = entry.resource or nil,
        description = entry.description,
        count = rng:random(entry.count.min,entry.count.max),
        icon = entry.icon,
        spawnFunc = function (tok)
            worldutil.initializeFlyingTokenWithPos(tok, 8 + rng:random()*3)
        end
    }
    return assertRewardIsValid(rew)
end


local assertEntriesValid
function assertEntriesValid()
    local r1 = love.math.newRandomGenerator()
    for _,entry in pairs(TOKEN_REWARDS)do
        local rew = generateStackedGenericToken(entry,r1)
        assertRewardIsValid(rew)
    end
    assertEntriesValid = nil
end

---@param rng love.RandomGenerator
function generateStackedTokenReward(rng)
    if assertEntriesValid then assertEntriesValid() end

    -- IDEALLY, it should be stuff that is scaling-agnostic
    if rng:random() < 0.6 then
        local validTokenRewards = {}
        for k, tokenReward in pairs(TOKEN_REWARDS) do
            table.insert(validTokenRewards, tokenReward)
        end
        local entry = helper.randomChoice(validTokenRewards, function(max) return rng:random(max) end)
        return generateStackedGenericToken(entry, rng)
    end

    return generateStackedChestToken(getRandomUnlockedResource(rng), rng)
end

end



---@return g.ScytheReward?
local function generateScytheReward()
    local sid = g.getNextScythe()
    if sid then
        local sinfo = g.getScytheInfo(sid)
        return {
            type = "scythe",
            icon = sinfo.image
        }
    end
    return nil
end



local PERM_UPGRADES = {
    "mushroom_blue",
    "mushroom_green",
    "percentage_5_more_xp",
    "percentage_10_more_area",
    "flat_2_more_area",
    "flat_3_more_damage",
    "flat_1_more_speed",
    "flat_2_more_area",
    "percentage_5_more_speed",
    "chest_big",
    "chest_small",
    "red_berry_2",
    "blue_berry_3",
    "mushroom_brown",
    "knife_bush",
    "mushroom_basic",
    "planter_cat_grass_1",
    "planter_cat_blue_grass_1",
    "orbital_knife",
    "orbital_scythe",
}


---@param upgradeId string
---@return g.PermanentReward
local function makePermanentReward(upgradeId)
    local uinfo = g.getUpgradeInfo(upgradeId)
    return assertRewardIsValid({
        type = "permanent",
        upgradeId = upgradeId,
        icon = uinfo.image
    })
end


---@param effectId string
---@param duration number
---@return g.EffectReward
local function makeEffectReward(effectId, duration)
    local einfo = g.getEffectInfo(effectId)
    return assertRewardIsValid({
        type = "effect",
        effect = einfo,
        duration = duration,
        icon = einfo.image
    })
end



---@param list table
---@param n number
---@param rng love.RandomGenerator
---@return table
local function selectNRandom(list, n, rng)
    local available = {unpack(list)}
    local result = {}
    for i = 1, n do
        local idx = rng:random(#available)
        result[i] = table.remove(available, idx)
    end
    return result
end


---@return g.Reward[]
function rewards.generateRandomRewards()
    local sn = g.getSn()

    local rng = love.math.newRandomGenerator(sn.level * 2654435761 + 12345)

    if sn.level == 0 then
        return {assert(generateScytheReward())}
    end

    -- Handle prestige 0 early levels
    if g.getPrestige() == 0 then
        if sn.level == 1 then
            return {
                makeEffectReward("harvest_area_2", 20),
                INSTANT_REWARDS.grass_1_infestation,
                makeEffectReward("hit_damage_1", 20)
            }
        elseif sn.level == 2 then
            return {
                INSTANT_REWARDS.grass_2_infestation,
                generateStackedTokenReward(rng),
                makeEffectReward("harvest_area_1", 20)
            }
        elseif sn.level == 3 then
            return {
                makePermanentReward("flat_2_more_damage"),
                makePermanentReward("flat_1_more_speed"),
                makePermanentReward("flat_2_more_area")
            }
        elseif sn.level == 4 then
            return {
                INSTANT_REWARDS.explosion_swarm,
                INSTANT_REWARDS.knife_swarm,
                INSTANT_REWARDS.scythe_swarm,
            }
        end
    end

    -- Special scythe reward every 10 levels
    if sn.level % 10 == 9 then
        local scy = g.getNextScythe()
        if scy then
            return {assert(generateScytheReward())}
        end
    end

    -- Validate all permanent upgrades exist
    for _, upgradeId in ipairs(PERM_UPGRADES) do
        local uinfo = g.getUpgradeInfo(upgradeId)
        assert(uinfo, "Missing upgrade info for: " .. upgradeId)
        assert(g.isImage(uinfo.image), "Missing image for: " .. upgradeId)
    end


    local rewardList
    -- every 3 levels = get a permanent reward.
    -- (todo could tweak this?)
    if sn.level % 3 == 0 then
        rewardList = {}
        local picks = selectNRandom(PERM_UPGRADES, 3, rng)
        for i = 1, 3 do
            rewardList[i] = makePermanentReward(picks[i])
        end
    else
        -- Else, generate normal reward list
        rewardList = {
            helper.randomChoice({generateResourceReward, generateInstantReward}, function(max) return rng:random(max) end)(rng),
            generateStackedTokenReward(rng),
            generatePotionReward(rng),
        }
    end

    -- Validate and shuffle rewards
    for _, rew in ipairs(rewardList) do
        assertRewardIsValid(rew)
    end
    helper.shuffle(rewardList)

    return rewardList
end



local PERMANENT_UPGRADE = "{wavy amp=0.3 f=2}{o}"..loc("PERMANENT UPGRADE:").."{/o}{/wavy}"
local PERMANENT_TOKEN = "{wavy amp=0.3 f=2}{o}{c r=0.5 g=0.7 b=1}"..loc("PERMANENT CROP:").."{/c}{/o}{/wavy}"


local NEW_SCYTHE = "{wavy amp=0.3 f=2}{o}"..loc("New Scythe Upgrade:").."{/o}{/wavy}"
local SCYTHE_UPGRADE = interp("+%{harvestRadius} harvest radius!", {
    context = "As in an upgrade for harvest area: '+4 harvest radius!'"
})


local STACKED_TOKEN = "{wavy amp=0.3 f=2}{o}"..loc("Spawns stuff:").."{/o}{/wavy}"
local STACKED_TOKEN_TOTAL = interp("%{tokens} total", {
    context = "Example result: \"+200 Money +200 Juice total\". The %{tokens} is \"+200 Money +200 Juice\" in that example."
})


local POTION = "{wavy amp=0.3 f=2}{o}"..loc("POTION!").."{/o}{/wavy}"
local GIVE_EFFECT = interp("{c r=0.6 g=0.7 b=1}%{str}{/c} for %{seconds} seconds!", {
    context = "A temporary potion effect / positive status effect. Example: '+2 Damage for 15 seconds!'"
})

local RESOURCE_BUNDLE = "{wavy amp=0.3 f=2}{o}"..loc("Free resources:", {}, {
    context = "A bundle of free resources"
}).."{/o}{/wavy}"

local PERM_TOKEN_UPGRADE = interp("When harvested, earn %{a}", {
    context = "Player is offered a new crop-type that yields resources. eg: PERMANENT CROP: 'When harvested, earn +5 gold'"
})





---@param bundle g.Bundle
---@param count integer
local function generateTotalResourcesText(bundle, count)
    local text = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if bundle[resId] then
            local resInfo = g.getResourceInfo(resId)
            text[#text+1] = "+"..g.formatNumber(bundle[resId] * count)
            text[#text+1] = "{"..resInfo.image.."}"
        end
    end

    return table.concat(text, " ")
end



---@param rew g.Reward
---@param r kirigami.Region
function rewards.drawRewardDescription(rew, r)
    -- used for reward-selection,
    -- AND used for reward-UI on HUD
    local font = g.getSmallFont(16)
    local icon, main = r:splitHorizontal(r.h, r.w-r.h)
    local time = love.timer.getTime()

    -- draw icon:
    lg.setColor(1,1,1)
    lg.rectangle("fill", icon:padRatio(0.1):get())
    do
    if rew.type == "token" then
        ---@cast rew g.TokenReward
        local txt
        icon, txt = icon:splitHorizontal(1,1)
        local x,y,w,h = icon:get()
        g.drawImageContained(rew.icon, x,y,w,h, math.sin(time)/14)
        helper.printTextOutlineContained("x"..tostring(rew.count), font, 1, txt:moveUnit(0,math.sin(time)*4))
    else
        local x,y,w,h = icon:padRatio(0.4):get()
        g.drawImageContained(rew.icon, x,y,w,h, math.sin(time)/14)
    end
    end

    main = main:padRatio(0.3)
    if rew.type == "resource" then
        ---@cast rew g.ResourceReward
        local resTxt = "{o}" .. generateTotalResourcesText(rew.resources, 1) .. "{/o}"
        local a,b = main:splitVertical(1,1)
        richtext.printRichContainedNoWrap(RESOURCE_BUNDLE, font, a:get())
        richtext.printRichContainedNoWrap(resTxt, font, b:get())
    elseif rew.type == "effect" then
        ---@cast rew g.EffectReward
        local a,b = main:splitVertical(1,4)
        richtext.printRichContained(POTION, font, a:get())
        richtext.printRichContainedNoWrap("{o}"..GIVE_EFFECT({
            str = rew.effect.description,
            seconds = rew.duration
        }).."{/o}", font, b:get())
    elseif rew.type == "token" then
        ---@cast rew g.TokenReward
        local a,b = main:splitVertical(2,3)
        richtext.printRichContained(STACKED_TOKEN, font, a:get())
        -- local txt = ("{o}{%s} => (%d {%s}){/o}"):format(tokImg, rew.stackedTokenResourceAmount*rew.stackedTokenCount, rew.stackedTokenResource)
        local txt
        if rew.description then
            txt = rew.description
        else
            assert(rew.resource)
            txt = STACKED_TOKEN_TOTAL {
                tokens = generateTotalResourcesText({[rew.resource.id] = rew.resource.amount}, rew.count)
            }
        end
        richtext.printRichContainedNoWrap("{o}"..txt.."{/o}", font, b:get())
    elseif rew.type == "permanent" then
        ---@cast rew g.PermanentReward
        local a,b = main:splitVertical(1,2)
        local uinfo = g.getUpgradeInfo(rew.upgradeId)
        if uinfo.tokenType then
            richtext.printRichContained(PERMANENT_TOKEN, font, a:get())
        else
            richtext.printRichContained(PERMANENT_UPGRADE, font, a:get())
        end
        local effect = "{wavy amp=0.3 f=2}{o}{c r=0.9 g=0.7 b=0.5}" 
        local txt = effect .. g.getUpgradeDescription(uinfo, 1, false)
        if uinfo.drawUI then
            uinfo:drawUI(1, icon:get())
        end
        if uinfo.tokenType then
            -- is a token upgrade: print specially.
            local tinfo = g.getTokenInfo(uinfo.tokenType)
            local res,val = nil,nil
            for k,v in pairs(tinfo.resources) do
                if v > 0 then
                    res,val = k, g.formatNumber(v)
                end
            end

            if res then
                local rtxt = "{o}" .. PERM_TOKEN_UPGRADE({
                    a = val .. " {" .. res .. "}"
                })
                local up,bot
                if txt == effect then
                    -- then there is no upg desc; dont render
                    richtext.printRichContained(rtxt, font, b:padRatio(0.1):get())
                else
                    up,bot = b:splitVertical(1,1)
                    richtext.printRichContained(rtxt, font, up:padRatio(0.1):get())
                    richtext.printRichContained(txt, font, bot:get())
                end
            else
                richtext.printRichContained(txt, font, b:get())
            end
        else
            -- is a normal upgrade: print normally.
            richtext.printRichContained(txt, font, b:get())
        end
    elseif rew.type == "scythe" then
        local a = main:splitVertical(1,2):attachToTopOf(main)
        local b,c = main:splitVertical(3,2)
        richtext.printRichContained(NEW_SCYTHE, font, a:get())
        local scythe, sinfo = g.getNextScythe()
        if scythe and sinfo then
            local currHA = g.getScytheInfo(g.getCurrentScythe()).harvestArea
            local nextHA = sinfo.harvestArea
            local diff = nextHA - currHA
            richtext.printRichContained("{rainbow}{o}" .. sinfo.name, font, b:get())
            local effect = "{wavy amp=0.3 f=2}{o}{c r=0.9 g=0.7 b=0.5}"
            richtext.printRichContained(effect.. SCYTHE_UPGRADE({
                harvestRadius = diff
            }), font, c:get())
        end
    elseif rew.type == "instant" then
        ---@cast rew g.InstantReward
        local a, b = main:splitVertical(1,1)
        richtext.printRichContainedNoWrap("{o}"..rew.name.."{/o}", font, a:get())
        richtext.printRichContainedNoWrap("{o}"..rew.description.."{/o}", font, b:get())
    else
        -- this shit doesnt need to be translated
        richtext.printRichContained("{o}ERROR. WTF? TELL OLI!{/o}", font, r:get())
    end
end



---@param rew g.Reward
function rewards.selectReward(rew)
    assertRewardIsValid(rew)
    g.clearEffects()

    if rew.type == "resource" then
        ---@cast rew g.ResourceReward
        g.addResources(rew.resources)
    elseif rew.type == "effect" then
        ---@cast rew g.EffectReward
        assert(rew.duration)
        g.grantEffect(rew.effect.type, rew.duration)
        -- g.stackPotionToken(rew.effectDuration, einfo)
    elseif rew.type == "token" then
        ---@cast rew g.TokenReward
        for _=1, rew.count do
            local w,h = ui.getScaledUIDimensions()
            local sx,sy = w/2 + love.math.random(-100,100), h/2 + love.math.random(-100,100)
            g.stackToken(rew.token.type, sx,sy, rew.spawnFunc)
        end
    elseif rew.type == "permanent" then
        ---@cast rew g.PermanentReward
        local uinfo = g.getUpgradeInfo(rew.upgradeId)
        local tree = g.getUpgTree()
        tree:addOrUpgradeUnboundUpgrade(uinfo)
    elseif rew.type == "scythe" then
        local sn = g.getSn()
        local scythe = g.getNextScythe()
        if scythe then
            sn.scythe = scythe
        else
            log.error("WTF BRUV? ERROR?")
        end
    elseif rew.type == "instant" then
        ---@cast rew g.InstantReward
        rew.func()
    end
end


return rewards
