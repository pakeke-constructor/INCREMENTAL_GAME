

--[[

ACHIVEMENTS:
======================

Earn over $100!
Earn over $10000!
Unlock slime upgrade!
Spawn a knife-cat!
Kill a boss!
Spend over $5000 on one upgrade
Spend over $20000 on one upgrade
Catch a fish!
Harvest 100 crops!
Harvest 1000 crops!




]]

local achievements = {}



function achievements.perSecondUpdate()
    
end


function achievements.defineAchievement(id, img)
end


function achievements.unlockAchievement(id)
    local luasteam = Steam.getSteam()
    if luasteam then
        luasteam.setAchievement(id)
    end
end




return achievements


