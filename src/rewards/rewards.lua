

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



local function generateResourceReward()
    local buf = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if g.isResourceUnlocked(resId) then
            table.insert(buf, resId)
        end
    end
    local res = helper.randomChoice(buf)
end


---@param rew g.Reward
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
end


function rewards.generateRandomRewards()
    -- generates 3 random rewards to choose from
    local sn=g.getSn()
    if g.getPrestige() == 0 then
        if sn.level < 4 then
            -- HARD-CODE
        end
    end

    local rewardList = {
        -- resource-reward
        -- effect-reward
        -- OTHER-reward
    }
    helper.shuffle(rewardList)
    return rewardList
end




---@param rew g.Reward
---@param x any
---@param y any
---@param w any
---@param h any
function rewards.drawRewardDescription(rew, x,y,w,h)
    -- used for reward-selection,
    -- AND used for reward-UI on HUD

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
