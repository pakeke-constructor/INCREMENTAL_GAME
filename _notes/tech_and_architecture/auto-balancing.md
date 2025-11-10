

# Auto balancing algorithm:


### Key objective(s):
- Keep pacing relatively "samey": Time between upgrades should be relatively consistent
- Players unlock NEW upgrades at a *consistent-ish* rate



### Key Challenges:
- How do we handle different currencies? Do we decide manually?
- How to handle relic-upgrades?



### Algorithm:
```lua

local unlocked -- a set of all unlocked upgrades (level>0)
local purchasable -- a set of all upgrades with level 0

local lastPrice = 0

local TARGET_TIME_BETWEEN_UPGRADES = 45 -- in seconds

unlocked = {rootUpgrade}

-- ======== ALGORITHM ==========

while #purchasable > 0 do
    setPrice(rootUpgrade, 5)

    local rr = getResourcesPerSecond() -- 60 second simulation?
    local newUnlocks = 0
    for upg in unlocked do
        if getPrice(upg, upg.currentLevel) < lastPrice do
            newUnlocks += 1
            levelUp(upg)
        end
    end

    local efficiency = {}
    for upg in purchasable do
        local rr2 = getResourcesPerSecond(with upg)
        efficiency[upg] = rr - rr2
    end

    local upg = min in efficiency

    -- Okay... now compute price.
    -- Multiple methods we can use... 

    --- METHOD-1:  target time-taken to upgrade directly
    local price = TARGET_TIME_BETWEEN_UPGRADES * rr

    --- METHOD-2: scale price according "upgrade quality"
    -- this is more "balanced" with respect to upgrade-
    local rrPerPrice = priceOfAllUpgradesSoFar() / rr
    local price = rrPerPrice * efficiency[upg]

    --- METHOD 3: Hybrid..? Maybe average them?
    --- heuristic with constant?
    
    print("Relative upgrade ROI: ", efficiency[upg] / price)
    -- ^^^ if there are any upgrades with INSANELY high ROI;
    -- we may need to look at nerfing them.

    setPrice(upg, price)
    lastPrice = math.max(lastPrice, price)
end




whenRelicUpgrade(function()
    -- maybe theres a smarter way...?
    -- i think this is simple tho.
    pickRandomRelic()
end)


```


### Edge cases:
- What to do if an upgrade doesnt increase resource-production?
- 






