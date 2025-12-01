


local count = {}


---@param id string
---@param name string
---@param stat string
---@param amount number
local function defStatPotion(id, stat, name, amount)
    local newId = id .. "_" .. tostring(amount)
    local image = id .. "_potion"

    local ct = (count[id] or 1)
    count[id] = ct + 1

    local realName = name .. " ("..ct..")"

    g.defineToken(newId, realName, {
        image = image,
        maxHealth = 15,
        resources = {},
    })

    local key = tostring("get" .. stat .. "Modifier")
    ---@cast key string

    local effectDescription = interp("+%{amount} " .. stat)

    g.defineEffect(newId, realName, {
        image = image,
        isDebuff = false,
        description = effectDescription({amount = amount}),

        ---@diagnostic disable-next-line
        [key] = function(duration, ...)
            return amount
        end
    })

end


for val=4, 8, 2 do
    defStatPotion("hit_speed", "HitSpeed", "Hit Speed", val)
end

for val=2, 4 do
    defStatPotion("hit_damage", "HitDamage", "Damage", val)
end

for val=40,80,20 do
    defStatPotion("harvest_area", "HarvestArea", "Area", val)
end
