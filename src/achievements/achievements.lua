

--[[

ACHIVEMENTS:
======================

rich_1: Earn over $1000!
rich_2: Earn over $10000!
slime: Unlock slime upgrade!
knife_cat: Spawn a knife-cat!
slayer: Kill a boss!
levelup: Reach level 30
merchant_1: Spend over $5000 on one upgrade
merchant_2: Spend over $20000 on one upgrade
fishercat: Catch a fish!
harvester_1: Harvest 500 crops!
harvester_2: Harvest 5000 crops!
delegation: Unlock farmer-cat upgrade!

]]

local achievements = {}



function achievements.perSecondUpdate()
    
end


function achievements.defineAchievement(id, img)
end



-- simple runtime caching, avoids overhead of steam API
local UNLOCKED_ACHIEVEMENT_RUNTIME_CACHE = {}


function achievements.unlockAchievement(id)
    if UNLOCKED_ACHIEVEMENT_RUNTIME_CACHE[id] then
        return
    end
    UNLOCKED_ACHIEVEMENT_RUNTIME_CACHE[id] = true
    local luasteam = Steam.getSteam()
    if luasteam then
        luasteam.setAchievement(id)
    end
end




return achievements


