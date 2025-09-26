
local reducers = require("src.modules.reducers")


g.defineEvent("draw")
g.defineEvent("update")



g.defineEvent("populateTokenPool")




g.defineEvent("tokenDraw")

g.defineEvent("tokenHitStart")
g.defineEvent("tokenHit")
g.defineEvent("tokenDamaged")
g.defineEvent("tokenDestroyed")




g.defineEvent("resourceChanged")

g.defineEvent("moneyChanged")
g.defineEvent("logsChanged")
g.defineEvent("bonesChanged")
g.defineEvent("rocksChanged")



g.defineQuestion("getTokenHitMultiplier", reducers.MULTIPLY, 1)

g.defineQuestion("getTokenDamageMultiplier", reducers.MULTIPLY, 1)




