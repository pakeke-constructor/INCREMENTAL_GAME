
local reducers = require("src.modules.reducers")


g.defineEvent("draw")
g.defineEvent("update")

g.defineEvent("perSecondUpdate")


g.defineEvent("populateTokenPool")




g.defineEvent("tokenDraw")
g.defineEvent("tokenSpawned")
g.defineEvent("tokenHitStart")
g.defineEvent("tokenHit")
g.defineEvent("tokenDamaged")
g.defineEvent("tokenDestroyed")




g.defineEvent("resourceChanged")

g.defineEvent("moneyChanged")
g.defineEvent("logsChanged")
g.defineEvent("bonesChanged")
g.defineEvent("rocksChanged")


g.defineQuestion("getTokenMaxHealthMultiplier", reducers.MULTIPLY, 1)

g.defineQuestion("getTokenHitMultiplier", reducers.MULTIPLY, 1)

g.defineQuestion("getTokenDamageModifier", reducers.ADD, 0)
g.defineQuestion("getTokenDamageMultiplier", reducers.MULTIPLY, 1)


g.defineQuestion("getTokenResourceMultiplier", reducers.MULTIPLY, 1)
g.defineQuestion("getTokenResourceModifier", function(a, b)
    if not b then
        return a
    end
    if not a then return b end
    return g.addBundles(a,b)
end, {})


g.defineQuestion("getUpgradePriceMultiplier", reducers.MULTIPLY, 1)
