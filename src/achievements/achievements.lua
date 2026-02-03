

--[[

ACHIVEMENTS:
======================

delegation: Unlock farmer-cat upgrade!
fishercat: Catch a fish!
harvester_1: Harvest 500 crops!
harvester_2: Harvest 5000 crops!
knife_cat: Spawn a knife-cat!
levelup: Reach level 30
merchant_1: Spend over $5000 on one upgrade
merchant_2: Spend over $20000 on one upgrade
rich_1: Earn over $1000!
rich_2: Earn over $10000!
slayer: Kill a boss!
slime: Unlock slime upgrade!

]]

---@class g.achievements
local achievements = {}



function achievements.emitPerSecondUpdate()
    local money = g.getResource("money")
    if money > 1000 then
        achievements.unlockAchievement("RICH_1")
    end
    if money > 10000 then
        achievements.unlockAchievement("RICH_2")
    end

    local cropsHarv = g.getMetric("totalTokensHarvested")
    if cropsHarv > 500 then
        achievements.unlockAchievement("HARVESTER_1")
    end
    if cropsHarv > 5000 then
        achievements.unlockAchievement("HARVESTER_2")
    end
    local sn = g.getSn()
    if sn.level > 30 then
        achievements.unlockAchievement("LEVELUP")
    end
end



---@param upgId string
---@param priceSpent g.Bundle
function achievements.emitUnlockUpgrade(upgId, priceSpent)
    if upgId == "grass_farmer_cat" then
        achievements.unlockAchievement("DELEGATION")
    end
    if upgId == "slime_token" then
        achievements.unlockAchievement("SLIME")
    end
    local money = (priceSpent and priceSpent.money) or 0
    if money > 5000 then
        achievements.unlockAchievement("MERCHANT_1")
    end
    if money > 20000 then
        achievements.unlockAchievement("MERCHANT_2")
    end
end





local dirty = false


---@param id string
function achievements.unlockAchievement(id)
    local luasteam = Steam.getSteam()
    if luasteam then
        local success, achieved = luasteam.userStats.getAchievement(id)
        if success and not achieved then
            luasteam.userStats.setAchievement(id)
            dirty = true
        end
    end
end



function achievements.update()
    local luasteam = Steam.getSteam()
    if not luasteam then return end

    if dirty then
        if not luasteam.userStats.storeStats() then
            log.error("Steam.userStats.storeStats() failed")
        end

        dirty = false
    end
end




return achievements


