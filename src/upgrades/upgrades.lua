


local upgrades = {}


local PRESTIGE_TYPES = {
    TOKEN = "TOKEN",
    HARVESTING = "HARVESTING",
    TOKEN_UPGRADES = "TOKEN_UPGRADES",
    MISC = "MISC",
}


local function niceAssert(bool, str, val)
    if not bool then
        str = str or "Assertion failed"
        if str and val then
            str = str .. " " .. tostring(val)
        end
        error(str, 2)
    end
end


function upgrades.init()
    upgrades.info = {--[[
        [upgradeId] -> Table (contains all info)
    ]]}

    upgrades.upgradeToPrestige = {--[[
        [upgrade] -> prestige
    ]]}

    -- what upgrades are actually unlocked?
    upgrades.unlocked = {--[[
        [prestigeId] -> level
        [upgradeId] -> level
    ]]}
end


function upgrades.getCurrentTokens()
    local toks = {}
    for upg,level in pairs(upgrades.unlocked) do
        local info
    end
end


function upgrades.definePrestige(prestigeId, tabl)
    --[[
    TODO: implement this later.
    ]]
end


---@param upgradeId string
---@param tabl table
function upgrades.defineUpgrade(upgradeId, tabl)
    niceAssert(type(upgradeId) == "string")
    niceAssert(PRESTIGE_TYPES[tabl.prestigeType], "Invalid prestige type: ", tabl.prestigeType)
    niceAssert(type(tabl.prestigeLevel) == "number", "Invalid prestige level:", tabl.prestigeLevel)
    niceAssert(type(tabl.x) == "number" and type(tabl.y) == "number", "Upgrades needs x,y coords")
    niceAssert(type(tabl.x) == "number" and type(tabl.y) == "number", "Upgrades needs x,y coords")
end


---@param upgradeId string
---@param tabl any
function upgrades.defineTokenUpgrade(upgradeId, tabl)
    upgrades.defineUpgrade(upgradeId, tabl)
end



---@param upgradeId string
---@return table
function upgrades.getInfo(upgradeId)
    return assert(upgrades.info[upgradeId])
end


---@param upgradeId string
---@return number?
function upgrades.getLevel(upgradeId)
    niceAssert(upgrades.info[upgradeId], "Upgrade doesnt exist")
    return upgrades.unlocked[upgradeId]
end


---@param upgradeId string
---@return number? level level of upgrade; nil if not upgraded.
function upgrades.upgrade(upgradeId)
    return 1
end



return upgrades


