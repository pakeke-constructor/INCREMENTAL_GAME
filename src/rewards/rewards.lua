

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
- COMMON: +Resource bundle
- COMMON: Simple permanent stat increase
- COMMON: Grants temporary effect (g.grantEffect)
- RARE: Grants a bunch of stacked-tokens that give BIG rewards :)
- RARE: Exotic permanent stat increase:
    - Deal +1 damage to grass-tokens
    - When lightning strikes, 
- RARE: Permanent New Token
- UNIQUE: One-time upgrades, like "get new scythe!"



API?
HOW SHOULD WE DO THE UI?
- 


]]

local rewards = {}


---@alias g.Reward.Type "TOKEN"|"RESOURCE"|"STAT_BUFF"|""

---@class g.Reward
---
---@field token g.TokenInfo? only for token-rewards
---
---@field resources g.Bundle? only for resource-rewards
---
---@field effect g.EffectInfo? only for effect-rewards
---@field effectDuration number? (also effect-rewards)
---
---@field stackedToken g.TokenInfo? (also effect-rewards)
---@field stackedTokenCount number?
---
---@field description string?
---
---@field icon string
local Reward = {}



---@param rew g.Reward
local function assertRewardIsValid(rew)
    local ct = 0
    if rew.resources then ct = ct + 1 end
    if rew.effect then ct = ct + 1 end
    if rew.token then ct = ct + 1 end
    if rew.description then ct = ct + 1 end
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
    else

    end
end


return rewards
