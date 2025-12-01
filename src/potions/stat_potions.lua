

local statPotions = {}


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

    g.defineToken(newId, realName, {
        image = image,
        maxHealth = 15,
        resources = {},
    })

    local key = tostring("get" .. stat .. "Modifier")
    ---@cast key string

    local effectDescription = interp("+%{amount} " .. name)

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



local hitspds = {4, 6, 8}
for i = 1, #hitspds do
    defStatPotion(i, "hit_speed", "HitSpeed", "Hit Speed", hitspds[i])
end

local dmgs = {2, 3, 4}
for i = 1, #dmgs do
    defStatPotion(i, "hit_damage", "HitDamage", "Damage", dmgs[i])
end

local areas = {40, 60, 80}
for i = 1, #areas do
    defStatPotion(i, "harvest_area", "HarvestArea", "Area", areas[i])
end

