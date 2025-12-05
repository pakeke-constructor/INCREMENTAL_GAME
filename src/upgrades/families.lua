

---@class g.families
local families = {}

--[[
how should we add upgs to families?


THINK SIMPLE.
WHATS A SIMPLER WAY TO ACHIEVE ALL OF THIS?

- We want EASY proc gen
- we want a balance between earlyGame and lateGame tokens
- we want to somewhat hardcode the first few prestiges
- ( Later on; we *may* want proc-genned trees. )

IDEA: How about we hardcode the upgrade-pools?
And once the pools are hardcoded, we generate the trees from there?
^^^ YES, that's an amazing idea.


QUESTION: How *much* hardcoding do we do?

]]


families.ROOT = "ROOT"
families.SIMPLE = "SIMPLE"

families.ORBIT = "ORBIT"

families.SLIME = "SLIME"
-- families.ICE = "ICE"
-- families.FIRE = "FIRE"


for k,v in pairs(families) do
    assert(k == v)
end

return families

