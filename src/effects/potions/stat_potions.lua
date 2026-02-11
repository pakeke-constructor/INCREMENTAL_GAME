


local count = {}


---@param id string
---@param name string
---@param stat string
---@param amount number
local function defStatPotion(i, id, stat, name, amount)
    local newId = id .. "_" .. tostring(i)
    local image = id .. "_potion"

    local ct = (count[id] or 1)
    count[id] = ct + 1

    local realName = name .. " ("..ct..")"
    local statInfo = g.VALID_STATS[stat]
    local effectDescription = interp("+%{amount} " .. name)

    g.defineEffect(newId, realName, {
        nameContext = "A potion",
        image = image,
        isDebuff = false,
        rawDescription = effectDescription({amount = amount}),

        ---@diagnostic disable-next-line
        [statInfo.addQuestion] = function(duration, ...)
            return amount
        end
    })

end



local hitspds = {6, 8, 10}
for i = 1, #hitspds do
    defStatPotion(i, "hit_speed", "HitSpeed", "Hit Speed", hitspds[i])
end

local dmgs = {2, 3, 4}
for i = 1, #dmgs do
    defStatPotion(i, "hit_damage", "HitDamage", "Damage", dmgs[i])
end

local areas = {20, 30, 40}
for i = 1, #areas do
    defStatPotion(i, "harvest_area", "HarvestArea", "Area", areas[i])
end

local speedreduction = {0.7, 0.45, 0.2}
for i, v in ipairs(speedreduction) do
    local effectDescription = interp("-%{amount:d}% crop respawn time")
    g.defineEffect("faster_spawn_"..i, "Crop Respawn Time ("..i..")", {
        image = "faster_spawn_potion",
        isDebuff = false,
        rawDescription = effectDescription({amount = (1 - v) * 100}),

        ---@diagnostic disable-next-line: assign-type-mismatch
        [g.VALID_STATS.TokenRespawnTime.multQuestion] = function()
            return v
        end
    })
end

local xpmul = {0.2, 0.4, 1}
for i, v in ipairs(xpmul) do
    local effectDescription = interp("+%{amount:d}% XP Multiplier")
    g.defineEffect("xp_"..i, "XP ("..i..")", {
        image = "xp_potion",
        isDebuff = false,
        rawDescription = effectDescription({amount = v * 100}),

        ---@diagnostic disable-next-line: assign-type-mismatch
        [g.VALID_STATS.XpMultiplier.multQuestion] = function()
            return 1 + v
        end
    })
end

local goldminemul = {1.3, 1.4, 1.5}
for i, v in ipairs(goldminemul) do
    local effectDescription = interp("x%{amount:.14g} Resource Multiplier")
    local mul = {money = v}
    g.defineEffect("goldmine_"..i, "Goldmine ("..i..")", {
        image = "goldmine_potion",
        isDebuff = false,
        rawDescription = effectDescription({amount = v}),

        getTokenResourceMultiplier = function()
            return mul
        end
    })
end
