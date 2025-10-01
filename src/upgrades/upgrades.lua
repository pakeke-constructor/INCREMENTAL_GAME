


---@class upgrades
local upgrades = {}

---@type {[string]: g.UpgradeInfo?}
local upgradeInfos = {--[[
    [upgradeId] -> Table (contains all info)
]]}


---@type {[number]: g.UpgradeInfo?}
local upgradePositions = {--[[
    hash(x,y,prestige) -> UpgradeInfo
]]}


local HASHVAL = 100000

---@param x integer
---@param y integer
---@param prestige integer
---@return integer
local function hash(x,y, prestige)
    return prestige + (x * HASHVAL) + (y * HASHVAL^2)
end


local function assertSmallEnough(x)
    assert(math.abs(x) < HASHVAL, "Needs to be less than " .. HASHVAL .. " for hashing to work correctly!")
end


local function niceAssert(bool, str, val)
    if not bool then
        str = str or "Assertion failed"
        if str and val then
            str = str .. " " .. tostring(val)
        end
        error(str, 2)
    end
end



local questionCache = {} -- [questionName] -> {upgradeId1, upgradeId2, ...}

local eventCache = {} -- [eventName] -> {upgradeId1, upgradeId2, ...}


-- some upgrades lie across multiple ranges.
-- EG `wood` is purchasable at prestige-0 AND prestige-1. {lower=0, upper=1}
-- And some upgrades are valid across ALL prestiges. {lower=0, upper=INFINITY}




-- a list of "special" functions that upgrades use,
-- that ARENT q-bus or ev-bus. (eg ignore them)
local SPECIAL_FUNCTIONS = {
    getValues = true
}


-- Add this to defineUpgrade function

---@param upgradeId string
---@param tabl g.UpgradeInfo
function upgrades.defineUpgrade(upgradeId, tabl)
    niceAssert(type(upgradeId) == "string")
    niceAssert(type(tabl.prestige) == "number", "Invalid prestige: ", tabl.prestige)
    niceAssert(g.isImage(tabl.image), "Invalid image: ", tabl.image)
    niceAssert(type(tabl.x) == "number" and type(tabl.y) == "number", "Upgrades needs x,y coords")

    assertSmallEnough(tabl.x)
    assertSmallEnough(tabl.y)
    assertSmallEnough(tabl.prestige)

    tabl.type = upgradeId

    assert(not upgradeInfos[upgradeId], "Redefined upgrade!")
    upgradeInfos[upgradeId] = tabl

    -- Cache questions and events this upgrade can handle
    for key, func in pairs(tabl) do
        if type(func) == "function"  then
            if g.getQuestionInfo(key) then
                if not questionCache[key] then questionCache[key] = {} end
                table.insert(questionCache[key], upgradeId)
            elseif g.isEvent(key) then
                if not eventCache[key] then eventCache[key] = {} end
                table.insert(eventCache[key], upgradeId)
            elseif (not SPECIAL_FUNCTIONS[key]) then
                error("Not a question, event, or special-function: "..tostring(key))
            end
        end
    end
end




---@param upgradeId string
local function increaseUpgrade(upgradeId)
    local session = g.getSn()
    session.upgradeLevels[upgradeId] = (session.upgradeLevels[upgradeId] or 0) + 1
end



---@param upgradeId string
---@return number
function upgrades.getLevel(upgradeId)
    local session = g.getSn()
    assert(upgradeInfos[upgradeId], "")
    return (session.upgradeLevels[upgradeId] or 0)
end



function upgrades.ask(question, ...)
    local questionInfo = g.getQuestionInfo(question)
    local reducer = questionInfo.reducer
    local defaultValue = questionInfo.defaultValue
    local upgradeIds = questionCache[question]

    local result = defaultValue

    if not upgradeIds then return result end

    for _, upgradeId in ipairs(upgradeIds) do
        local level = upgrades.getLevel(upgradeId)
        if level > 0 then
            local info = upgrades.getInfo(upgradeId)
            local answerFunc = info[question]
            if answerFunc then
                local answer = answerFunc(level, ...) or defaultValue
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
---@return g.UpgradeInfo
function upgrades.getInfo(upgradeId)
    return assert(upgradeInfos[upgradeId])
end



---@param upgradeId string
---@return boolean
function upgrades.isLocked(upgradeId)
    local uinfo = upgrades.getInfo(upgradeId)
    if not g.inPrestigeRange(g.getPrestige(), uinfo.prestige) then
        -- not in prestige range... its obviously hidden
        return true
    end

    if upgrades.getLevel(upgradeId) > 0 then
        return false -- cant be hidden if level>0
    end
    if uinfo.isHidden and uinfo:isHidden() then
        return true
    end

    return false
end



---@param upgradeId string
---@return boolean
function upgrades.isHidden(upgradeId)
    local uinfo = upgrades.getInfo(upgradeId)
    if not g.inPrestigeRange(g.getPrestige(), uinfo.prestige) then
        -- not in prestige range... its obviously hidden
        return true
    end

    if upgrades.getLevel(upgradeId) > 0 then
        return false -- cant be hidden if level>0
    end
    if uinfo.isHidden and uinfo:isHidden() then
        return true
    end

    return false
end


---@param worldX number screen x coordinate (center of box)
---@param worldY number screen y coordinate (center of box)
---@return number grid_x
---@return number grid_y
local function invertCoords(worldX, worldY)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    local grid_x = worldX / spacing
    local grid_y = worldY / spacing
    return grid_x, grid_y
end


---@param worldX integer
---@param worldY integer
---@return g.UpgradeInfo?
function upgrades.getUpgradeAt(worldX, worldY)
    local prestige = g.getPrestige()
    local x,y = invertCoords(worldX, worldY)
    local h = hash(x,y,prestige)
    return upgradePositions[h]
end


---@param uinfo g.UpgradeInfo
---@return number
---@return number
---@return number
function upgrades.getCoords(uinfo)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    local x = uinfo.x * spacing
    local y = uinfo.y * spacing
    -- x,y is center of box
    -- `size` is size of upgrade-box
    return x,y,size
end





---@return g.UpgradeInfo?
function upgrades._draw()
    --[[
    NOTE: there is a hard-assumption that all
    upgrades are within the same "map".

    I dont think there will be though; so its fine
    ]]
    local hoveredUpgrade = nil

    for upgradeId, uinfo in pairs(upgradeInfos or {}) do
        if not upgrades.isHidden(upgradeId) then
            local level = upgrades.getLevel(upgradeId)
            local cx,cy,size = upgrades.getCoords(uinfo)
            local x,y,w,h = cx-size/2, cy-size/2, size, size

            local isHovered, wasJustClicked = ui.upgradeBoxUI(uinfo, level, x,y,w,h)
            if isHovered then
                hoveredUpgrade = uinfo
            end
            if wasJustClicked and g.trySubtractResources(uinfo.price) then
                increaseUpgrade(upgradeId)
            end
        end
    end

    return hoveredUpgrade
end




return upgrades


