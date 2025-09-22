


---@class upgrades
local upgrades = {}

local upgradeInfos = {--[[
    [upgradeId] -> Table (contains all info)
]]}


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




function upgrades.definePrestige(prestigeId, tabl)
    --[[
    TODO: implement this later.
    ]]
end


local questionCache = {} -- [questionName] -> {upgradeId1, upgradeId2, ...}

local eventCache = {} -- [eventName] -> {upgradeId1, upgradeId2, ...}


-- Add this to defineUpgrade function
function upgrades.defineUpgrade(upgradeId, tabl)
    niceAssert(type(upgradeId) == "string")
    niceAssert(PRESTIGE_TYPES[tabl.prestigeType], "Invalid prestige type: ", tabl.prestigeType)
    niceAssert(type(tabl.prestigeLevel) == "number", "Invalid prestige level: ", tabl.prestigeLevel)
    niceAssert(g.isImage(tabl.image), "Invalid image: ", tabl.image)
    niceAssert(type(tabl.x) == "number" and type(tabl.y) == "number", "Upgrades needs x,y coords")

    assert(not upgradeInfos[upgradeId], "Redefined upgrade!")
    upgradeInfos[upgradeId] = tabl

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
        local level = g.getSn():getUpgradeLevel(upgradeId)
        if level > 0 then
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
        local level = g.getSn():getUpgradeLevel(upgradeId)
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
    return assert(upgradeInfos[upgradeId])
end




function upgrades._draw()
    -- TODO: allow for alternative upgrade maps in future?
    for upgradeId, info in pairs(upgradeInfos or {}) do
        local level = g.getSn():getUpgradeLevel(upgradeId)
        local size = consts.UPGRADE_IMAGE_SIZE
        local spacing = consts.UPGRADE_GRID_SPACING + size
        local x = info.x * spacing
        local y = info.y * spacing

        g.drawImage(info.image, x, y)
        love.graphics.rectangle("line", x-size/2, y-size/2, size, size)

        if level > 0 then
            love.graphics.print(tostring(level), x, y)
        end
    end
end



return upgrades


