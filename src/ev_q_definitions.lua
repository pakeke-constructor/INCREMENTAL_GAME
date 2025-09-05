
local reducers = require("src.modules.reducers")


g.defineEvent("draw")
g.defineEvent("update")



g.defineEvent("populateTokenPool")




g.defineEvent("tokenDraw")

g.defineEvent("tokenHit")
g.defineEvent("tokenDamaged")
g.defineEvent("tokenDestroyed")





g.defineQuestion("getTokenDamageMultiplier", reducers.MULTIPLY, 1)




