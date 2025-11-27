

--[[

==================
PLANNING:
==================


TENETS:

- We want relics to *feel* exciting.
- Decisions should feel somewhat meaningful.
- Have proc-genned relics.


HOW TO ACHIEVE:
- Hardcoded early-game relics?
- "tiers" or rarity for relics?


RELIC TYPES:
- COMMON: +Resource bundle
- COMMON: Simple permanent stat increase
- COMMON: Grants temporary effect (g.grantEffect)
- RARE: Exotic permanent stat increase:
    - Deal +1 damage to grass-tokens
    - When lightning strikes, 
- RARE: Permanent New Token
- UNIQUE: One-time upgrades, like "get new scythe!"



API?
HOW SHOULD WE DO THE UI?
- 


]]

local relics = {}


function relics.generateRandomRelics()
    -- generates 3 random relics to choose from
    local sn=g.getSn()
    if g.getPrestige() == 0 then
        if sn.level < 4 then
            -- HARD-CODE
        end
    end

    return relicList
end



function relics.drawRelicDescription(rel, x,y,w,h)
    -- used for relic-selection,
    -- AND used for 

end


function relics.addRelic()
    return relic
end


