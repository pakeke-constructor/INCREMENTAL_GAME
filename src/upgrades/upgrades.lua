


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


local questionCache = {} -- [questionName] -> {upgradeId1, upgradeId2, ...}

local eventCache = {} -- [questionName] -> {upgradeId1, upgradeId2, ...}


-- Add this to defineUpgrade function
function upgrades.defineUpgrade(upgradeId, tabl)
    niceAssert(type(upgradeId) == "string")
    niceAssert(PRESTIGE_TYPES[tabl.prestigeType], "Invalid prestige type: ", tabl.prestigeType)
    niceAssert(type(tabl.prestigeLevel) == "number", "Invalid prestige level:", tabl.prestigeLevel)
    niceAssert(type(tabl.x) == "number" and type(tabl.y) == "number", "Upgrades needs x,y coords")

    assert(not upgrades.info[upgradeId], "Redefined upgrade!")
    upgrades.info[upgradeId] = tabl

    -- Cache questions and events this upgrade can handle
    for key, func in pairs(tabl) do
        if type(func) == "function" then
            if g.getQuestionInfo(key) then
                if not questionCache[key] then questionCache[key] = {} end
                table.insert(questionCache[key], upgradeId)
            elseif g.isEvent(key) then
                if not eventCache[key] then eventCache[key] = {} end
                table.insert(eventCache[key], upgradeId)
            end
        end
    end
end



function upgrades.ask(question, ...)
    local questionInfo = g.getQuestionInfo(question)
    local reducer = questionInfo.reducer
    local result = questionInfo.defaultValue
    local upgradeIds = questionCache[question]

    if not upgradeIds then return result end

    for _, upgradeId in ipairs(upgradeIds) do
        local level = upgrades.getLevel(upgradeId)
        if level and level > 0 then
            local info = upgrades.getInfo(upgradeId)
            local answerFunc = info[question]
            if answerFunc then
                local answer = answerFunc(level, ...)
                result = reducer(answer, result)
            end
        end
    end

    return result
end



function upgrades.call(event, ...)
    local upgradeIds = eventCache[event]
    if not upgradeIds then return end

    for _, upgradeId in ipairs(upgradeIds) do
        local level = upgrades.getLevel(upgradeId)
        if level and level > 0 then
            local info = upgrades.getInfo(upgradeId)
            local eventFunc = info[event]
            if eventFunc then
                eventFunc(level, ...)
            end
        end
    end
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


