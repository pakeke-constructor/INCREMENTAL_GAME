

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
---@field effect g.EffectInfo? only for effect-rewards
---@field effectDuration number? (also effect-rewards)
---
---@field stackedToken g.TokenInfo? gives a stacked-token reward immediately
---@field stackedTokenCount number?
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
    assert(ct == 1, "Invalid reward: Rewards need to be exactly ONE type")

    if rew.effect then
        assert(rew.effectDuration, "Effects need a duration")
    end
    if rew.stackedToken then
        assert(rew.stackedTokenCount, "stackedToken rewards need a count")
    end

    assert(rew.icon)
    return rew
end



---@return g.Reward
local function generateResourceReward()
    local buf = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if g.isResourceUnlocked(resId) then
            table.insert(buf, resId)
        end
    end
    local resId = helper.randomChoice(buf)
    local rps = g.getResourcesPerSecond(resId)
    local SECONDS = love.math.random(15,40)

    local resources = {}
    resources[resId] = tonumber(g.formatNumber(rps*SECONDS))
    return assertRewardIsValid({
        icon = g.getResourceInfo(resId).image,
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
end

---@return g.Reward
function generatePotionReward()
    local r = love.math.random()
    local potionId = helper.randomChoice(statPots)
    local einfo = g.getEffectInfo(potionId)
    return {
        effect = einfo,
        effectDuration = 20 + love.math.random(-5, 5),
        icon = einfo.image
    }
end

end




---@return g.Reward[]
function rewards.generateRandomRewards()
    -- generates 3 random rewards to choose from
    local sn=g.getSn()
    if g.getPrestige() == 0 then
        if sn.level < 4 then
            -- HARD-CODE
        end
    end

    local rewardList = {
        generateResourceReward(),
        generateResourceReward(),
        generatePotionReward(),
        -- resource-reward
        -- effect-reward
        -- OTHER-reward
    }
    helper.shuffle(rewardList)
    return rewardList
end



local GIVE_EFFECT = interp("{o}Grants {c r=0.6 g=0.7 b=1}%{str}{/c} for %{seconds} seconds!{/o}", {
    context = "A temporary potion effect / positive status effect. Example: 'Grants +2 Damage for 15 seconds!'"
})


---@param rew g.Reward
---@param r kirigami.Region
function rewards.drawRewardDescription(rew, r)
    -- used for reward-selection,
    -- AND used for reward-UI on HUD
    local font = g.getSmallFont(16)
    local icon, main = r:splitHorizontal(r.h, r.w-r.h)

    -- draw icon:
    local cx,cy = icon:getCenter()
    lg.setColor(1,1,1)
    lg.rectangle("fill", icon:padRatio(0.1):get())
    g.drawImageContained(rew.icon, icon:padRatio(0.2):get())

    main = main:padRatio(0.3)
    if rew.resources then
        local resTxt = ""
        for resId,v in pairs(rew.resources) do
            resTxt = resTxt .. "+" .. tostring(v) .. " {" ..resId.. " scale=0.7}"
        end
        resTxt = "{o}" .. resTxt .. "{/o}"
        richtext.printRichContainedNoWrap(resTxt, font, main:get())
    elseif rew.effect then
        richtext.printRichContained(GIVE_EFFECT({
            str = rew.effect.description,
            seconds = rew.effectDuration
        }), font, main:get())
    elseif rew.stackedToken then
        
    elseif rew.upgradeId then
        
    else
        richtext.printRichContained("{o}ERROR. WTF? Tell Oli", font, r:get())
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
    end
end


return rewards
