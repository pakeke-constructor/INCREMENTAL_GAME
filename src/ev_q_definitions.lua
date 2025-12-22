
local reducers = require("src.modules.reducers")


g.defineEvent("draw")
g.defineEvent("update")

g.defineEvent("perSecondUpdate")


g.defineEvent("populateTokenPool") -- define the whitelist
g.defineEvent("depopulateTokenPool") -- clear tokens (blacklist)




g.defineEvent("drawToken")
g.defineEvent("tokenSpawned")
g.defineEvent("tokenHitStart")
g.defineEvent("tokenHit")
g.defineEvent("tokenDamaged")
g.defineEvent("tokenCrit")
g.defineEvent("tokenDestroyed")
g.defineEvent("tokenEarnedResources")
g.defineEvent("tokenSlimed")
g.defineEvent("tokenStarred")




g.defineEvent("resourceChanged")

g.defineEvent("moneyChanged")
g.defineEvent("logsChanged")
g.defineEvent("bonesChanged")
g.defineEvent("rocksChanged")


g.defineQuestion("getTokenMaxHealthMultiplier", reducers.MULTIPLY, 1)

g.defineQuestion("getTokenHitMultiplier", reducers.MULTIPLY, 1)

g.defineQuestion("getTokenDamageModifier", reducers.ADD, 0)
g.defineQuestion("getTokenDamageMultiplier", reducers.MULTIPLY, 1)
g.defineQuestion("getPerTokenRespawnTimeMultiplier", reducers.MULTIPLY, 1)





-- Slight hack: using __index to set all keys to 1.
-- (we dont know what resoruces are defined yet)
local MULTIPLICATIVE_IDENTITY = setmetatable({},{__index = function() return 1 end})
g.defineQuestion("getTokenResourceMultiplier", function(a, b)
    if not b then
        return a
    end
    return g.multBundles(a,b)
end, MULTIPLICATIVE_IDENTITY)

g.defineQuestion("getTokenResourceModifier", function(a, b)
    if not b then
        return a
    end
    if not a then return b end
    return g.addBundles(a,b)
end, {})



g.defineQuestion("getUpgradePriceMultiplier", reducers.MULTIPLY, 1)
