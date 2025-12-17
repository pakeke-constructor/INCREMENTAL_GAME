


local count = {}


---@param id string
---@param name string
---@param stat string
---@param amount number
---@param iscroprespawn boolean? (only for token respawn time, requires specialization)
local function defStatPotion(i, id, stat, name, amount, iscroprespawn)
    local newId = id .. "_" .. tostring(i)
    local image = id .. "_potion"

    local ct = (count[id] or 1)
    count[id] = ct + 1

    local realName = name .. " ("..ct..")"

    local key = tostring("get" .. stat .. "Modifier")
    ---@cast key string

    local effectDescription
    if iscroprespawn then
        effectDescription = interp("%{amount:d}% " .. name)
    else
        effectDescription = interp("+%{amount} " .. name)
    end

    g.defineEffect(newId, realName, {
        image = image,
        isDebuff = false,
        description = effectDescription({amount = iscroprespawn and (math.log(amount, 2) * 100) or amount}),

        ---@diagnostic disable-next-line
        [key] = function(duration, ...)
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
    defStatPotion(i, "faster_spawn", "TokenRespawnTime", "Crop Respawn Time", v, true)
end
