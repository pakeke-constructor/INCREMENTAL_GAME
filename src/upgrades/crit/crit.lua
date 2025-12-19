

---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end



defUpgrade("critical_damage", "Critical Damage", {
    --[[
    TODO!!
    We should have more upgrades related to critical-strikes.
    ]]
    description = "%{1} chance of hitting token with 10x more damage.",
    getValues = function(uinfo, level)
        return 1 + (level - 1) / 2
    end,
    valueFormatter = {"%.14g%%"},

    getTokenHitMultiplier = function(uinfo, level)
        local val = uinfo:getValues(level) / 100
        return love.math.random() <= val and 10 or 1
    end
})


