

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



---@class g.Reward
---
---@field upgradeId string? The id of a permanent reward
---
---@field resources g.Bundle? only for resource-rewards
---
---@field scythe boolean? is this a scythe upgrade
---
---@field effect g.EffectInfo? only for effect-rewards
---@field effectDuration number? (also effect-rewards)
---
---@field stackedToken g.TokenInfo? gives a stacked-token reward immediately
---@field stackedTokenCount number?
---@field stackedTokenResource string?
---@field stackedTokenResourceAmount number?
---@field stackedTokenSpawnFunc fun(tok:g.Token)?
---
---@field icon string
local Reward = {}




---@param rew g.Reward
---@return g.Reward
local function assertRewardIsValid(rew)
    local ct = 0
    if rew.resources then ct = ct + 1 end
    if rew.effect then ct = ct + 1 end
    if rew.upgradeId then ct = ct + 1 end
    if rew.stackedToken then ct = ct + 1 end
    if rew.scythe then ct = ct + 1 end
    assert(ct == 1, "Invalid reward: Rewards need to be exactly ONE type")

    if rew.effect then
        assert(rew.effectDuration, "Effects need a duration")
    end
    if rew.stackedToken then
        assert(rew.stackedTokenCount, "stackedToken rewards need a count")
        assert(rew.stackedTokenResource, "need a resource")
        assert(rew.stackedTokenResourceAmount, "need resourceAmount")
    end

    assert(rew.icon)
    return rew
end



---@return string
local function getRandomUnlockedResource()
    local buf = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if g.isResourceUnlocked(resId) then
            table.insert(buf, resId)
        end
    end
    local resId = helper.randomChoice(buf)
    return resId or "money"
end



---@return g.Reward
local function generateResourceReward()
    local resId = getRandomUnlockedResource()
    local rps = math.max(1, g.getResourcesPerSecond(resId))
    local seconds = math.floor(love.math.random(15,40) / 5) * 5

    local resources = {}
    resources[resId] = rps*seconds
    return assertRewardIsValid({
        icon = "resource_bundle_reward",
        resources = resources
    })
end



local generatePotionReward
do
local statPots = {}
for i=1,3 do
    table.insert(statPots, "hit_speed_" .. i)
    table.insert(statPots, "hit_damage_" .. i)
    table.insert(statPots, "harvest_area_" .. i)
    table.insert(statPots, "faster_spawn_" .. i)
end

---@return g.Reward
function generatePotionReward()
    local potionId = helper.randomChoice(statPots)
    local einfo = g.getEffectInfo(potionId)
    return assertRewardIsValid({
        effect = einfo,
        effectDuration = 20 + love.math.random(-5, 5),
        icon = einfo.image
    })
end

end


local generateStackedTokenReward
-- https://youtu.be/dQw4w9WgXcQ?si=7ZmxRrDo3EFVD9gi
do


---@param resId string
---@return g.Reward
local function generateStacked(resId)
    local rps = g.getResourcesPerSecond(resId)
    local resAmount = math.max(1, 5*(math.floor(rps*3 / 5)))
    return assertRewardIsValid{
        ---@param tok g.Token
        stackedTokenSpawnFunc = function(tok)
            tok.resources = {
                [resId] = resAmount
            }
        end,
        stackedToken = g.getTokenInfo("chest_"..resId),
        stackedTokenCount = math.floor(math.random(8, 20) / 2) * 2,
        stackedTokenResourceAmount = resAmount,
        stackedTokenResource = resId,
        icon = "chest_"..resId
    }
end

---@return g.Reward
function generateStackedTokenReward()
    local lv = g.getSn().level
    -- IDEA: spawn stackedToken bombs here?

    -- IDEA: stackedToken mushrooms?

    -- IDEALLY, it should be stuff that is scaling-agnostic

    if love.math.random() < 0.4 then
        return generateStacked("money")
    end

    return generateStacked(getRandomUnlockedResource())
end

end



---@return g.Reward?
local function generateScytheReward()
    local sid = g.getNextScythe()
    if sid then
        local sinfo = g.getScytheInfo(sid)
        return {
            scythe = true,
            icon = sinfo.image
        }
    end
    return nil
end



---@return g.Reward[]
function rewards.generateRandomRewards()
    -- generates 3 random rewards to choose from
    local sn=g.getSn()
    if g.getPrestige() == 0 then
        if sn.level == 0 then
            return {assert(generateScytheReward())}
        elseif sn.level == 1 then
           -- uhh idk lol. TODO
        end
        if sn.level < 4 then
            -- HARD-CODE
        end
    end

    if sn.level % 10 == 9 then
        local scy = g.getNextScythe()
        if scy then
            return {assert(generateScytheReward())}
        end
    end


    assert(
        g.isImage("more_damage") and
        g.isImage("more_speed") and
        g.isImage("more_area")
    )
    assert(
        g.getUpgradeInfo("percentage_more_damage") and
        g.getUpgradeInfo("percentage_more_speed") and
        g.getUpgradeInfo("percentage_more_area")
    )

    local rewardList

    if sn.level % 5 == 0 then
        -- generate permanent rewards!
        rewardList = {
            {
                upgradeId = "percentage_more_damage",
                icon = "more_damage"
            },
            {
                upgradeId = "percentage_more_speed",
                icon = "more_speed"
            },
            {
                upgradeId = "percentage_more_area",
                icon = "more_area"
            }

        }
    else
        rewardList = {
            generateResourceReward(),
            generateStackedTokenReward(),
            generatePotionReward(),
        }
    end

    for _,rew in ipairs(rewardList) do
        assertRewardIsValid(rew)
    end
    helper.shuffle(rewardList)
    return rewardList
end




local PERMANENT_UPGRADE = loc("{wavy amp=0.3 f=2}{o}PERMANENT UPGRADE:{/o}{/wavy}")


local NEW_SCYTHE = loc("{wavy amp=0.3 f=2}{o}New Scythe Upgrade:{/o}{/wavy}")
local SCYTHE_UPGRADE = interp("{wavy amp=0.3 f=2}{o}+%{harvestRadius} harvest radius!{/o}{/wavy}", {
    context = "As in an upgrade for harvest area: '+4 harvest radius!'"
})


local STACKED_TOKEN = loc("{wavy amp=0.3 f=2}{o}Spawns stuff to harvest:{/o}{/wavy}")
local STACKED_TOKEN_TOTAL = loc("{o}+%s {%s} total{/o}", {}, {
    context = "Example usage: (+400 {gold} total), where %d=400 and %s=gold. Please keep the string formatting."
})


local POTION = loc("{wavy amp=0.3 f=2}{o}POTION!{/o}{/wavy}")
local GIVE_EFFECT = interp("{o}Grants {c r=0.6 g=0.7 b=1}%{str}{/c} for %{seconds} seconds!{/o}", {
    context = "A temporary potion effect / positive status effect. Example: 'Grants +2 Damage for 15 seconds!'"
})

local RESOURCE_BUNDLE = loc("{wavy amp=0.3 f=2}{o}Free resources:{/o}{/wavy}", {}, {
    context = "A bundle of free resources"
})



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
    if rew.stackedToken then
        local txt
        icon, txt = icon:splitHorizontal(1,1)
        local x,y,w,h = icon:get()
        g.drawImageContained(rew.icon, x,y,w,h, math.sin(time)/14)
        richtext.printRichContained("{o}x"..tostring(rew.stackedTokenCount), font, txt:moveUnit(0,math.sin(time)*4):get())
    else
        local x,y,w,h = icon:padRatio(0.4):get()
        g.drawImageContained(rew.icon, x,y,w,h, math.sin(time)/14)
    end
    end

    main = main:padRatio(0.3)
    if rew.resources then
        local resTxt = ""
        for resId,v in pairs(rew.resources) do
            resTxt = resTxt .. "+" .. tostring(g.formatNumber(v)) .. " {" ..resId.. " scale=0.7}"
        end
        resTxt = "{o}" .. resTxt .. "{/o}"
        local a,b = main:splitVertical(1,1)
        richtext.printRichContainedNoWrap(RESOURCE_BUNDLE, font, a:get())
        richtext.printRichContainedNoWrap(resTxt, font, b:get())
    elseif rew.effect then
        local a,b = main:splitVertical(1,2)
        richtext.printRichContained(POTION, font, a:get())
        richtext.printRichContained(GIVE_EFFECT({
            str = rew.effect.description,
            seconds = rew.effectDuration
        }), font, b:get())
    elseif rew.stackedToken then
        local a,b = main:splitVertical(2,3)
        richtext.printRichContained(STACKED_TOKEN, font, a:get())
        -- local txt = ("{o}{%s} => (%d {%s}){/o}"):format(tokImg, rew.stackedTokenResourceAmount*rew.stackedTokenCount, rew.stackedTokenResource)
        local total = g.formatNumber(rew.stackedTokenResourceAmount*rew.stackedTokenCount)
        local txt = (STACKED_TOKEN_TOTAL):format(total, rew.stackedTokenResource)
        richtext.printRichContainedNoWrap(txt, font, b:get())
    elseif rew.upgradeId then
        local a,b = main:splitVertical(1,2)
        richtext.printRichContained(PERMANENT_UPGRADE, font, a:get())
        local uinfo = g.getUpgradeInfo(rew.upgradeId)
        local txt = g.getUpgradeDescription(uinfo, 1, false)
        local effect = "{wavy amp=0.3 f=2}{o}{c r=0.9 g=0.7 b=0.5}"
        richtext.printRichContained(effect.. txt, font, b:get())
    elseif rew.scythe then
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
    else
        -- this shit doesnt need to be translated
        richtext.printRichContained("{o}ERROR. WTF? TELL OLI!{/o}", font, r:get())
    end
end



---@param rew g.Reward
function rewards.selectReward(rew)
    assertRewardIsValid(rew)

    if rew.resources then
        g.addResources(rew.resources)
    elseif rew.effect then
        assert(rew.effectDuration)
        g.grantEffect(rew.effect.type, rew.effectDuration)
        -- g.stackPotionToken(rew.effectDuration, einfo)
    elseif rew.stackedToken then
        for _=1, rew.stackedTokenCount do
            local w,h = ui.getScaledUIDimensions()
            local sx,sy = w/2 + love.math.random(-100,100), h/2 + love.math.random(-100,100)
            g.stackToken(rew.stackedToken.type, sx,sy)
        end
    elseif rew.upgradeId then
        local uinfo = g.getUpgradeInfo(rew.upgradeId)
        local tree = g.getUpgTree()
        tree:addOrUpgradeUnboundUpgrade(uinfo)
    elseif rew.scythe then
        local sn = g.getSn()
        local scythe = g.getNextScythe()
        if scythe then
            sn.scythe = scythe
        else
            log.error("WTF BRUV? ERROR?")
        end
    end
end


return rewards
