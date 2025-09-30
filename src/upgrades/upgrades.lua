


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



---@param uinfo g.UpgradeInfo
---@param upgradeId string
---@return boolean isHovered
local function drawUpgrade(uinfo, upgradeId)
    local level = upgrades.getLevel(upgradeId)

    local cx,cy,size = upgrades.getCoords(uinfo)
    local x,y,w,h = cx-size/2, cy-size/2, size, size

    local isHovered = false
    if iml.isHovered(x,y,w,h) then
        love.graphics.setColor(0.7,0.7,0.85)
        isHovered = true
    else
        love.graphics.setColor(1,1,1)
    end

    -- background:
    love.graphics.rectangle("fill",x,y,w,h)

    g.drawImage(uinfo.image, cx, cy)

    love.graphics.setColor(1,0.3,0.2)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x,y,w,h)
    love.graphics.setColor(1,1,1)

    if level > 0 then
        local xx,yy,ww,hh = cx, cy, size,size
        --love.graphics.rectangle("line",xx,yy,ww,hh)
        richtext.printRichContained("{o thickness=4}"..tostring(level), love.graphics.getFont(), xx,yy,ww,hh)
    end

    if iml.wasJustClicked(x,y,w,h) then
        if g.trySubtractResources(uinfo.price) then
            increaseUpgrade(uinfo.type)
        end
    end
    return isHovered
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
            local isHovered = drawUpgrade(uinfo, upgradeId)
            if isHovered then
                hoveredUpgrade = uinfo
            end
        end
    end

    return hoveredUpgrade
end



do


local W = 200


--[[

TODO:
We almost certainly want retained-UI here.

Or else we will be doing weird double-passes all the time.
- When we hover a new element, create a retained-ui upgrade-description
- (retained-ui object should be instantiated and stored inside upgrade-scene)
- Check it's w,h and then render it. :) ez

We should probably make a new file,
`src/ui/upgrade_description.lua`?
^^^ Maybe something like that?

And then for API:
upgDesc:addHeight()
upgDesc:expandWidth()
upgDesc:addText()
upgDesc:addSeparator()

and have it *tightly coupled* with upgrade-descriptions.
KEEP IT SIMPLE, DONT OVERENGINEER.

]]

---@param uinfo g.UpgradeInfo
---@param r layout.Region
local function drawTitle(uinfo, r, noDraw)
    -- for now; assume all upgrades are tokens
    -- (Title, Image)

    local f = g.getBigFont(32)
    local tW,tH = f:getWidth(richtext.stripEffects(uinfo.name)), f:getHeight()

    local textR = Kirigami(0, 0, tW, tH)
        :attachToTopOf(r)
        :moveRatio(0, 1)
        :centerX(r)
    local imageR = nil
    if uinfo.image then
        -- The idea in here is that both icon and upgrade name are in center side-by-side.
        local leftPadding = 4
        imageR = Kirigami(0, 0, 32, 32)
        textR = Kirigami(0, 0, tW, tH)
            :attachToTopOf(r)
            :moveRatio(0, 1)
            :centerX(r)
            :moveUnit(-(imageR.w + leftPadding) / 2, 0)
        imageR = imageR:attachToRightOf(textR):centerY(textR):moveUnit(leftPadding)
    end

    local h = (tH * 1)
    local h1 = (tH * 1.2)
    if not noDraw then
        love.graphics.setColor(1, 1, 1)

        -- Draw text
        local tX, tY = textR:get()
        richtext.printRich(uinfo.name, f, tX, tY, tW, "left")

        -- Draw image
        if imageR and uinfo.image then
            local iX, iY = imageR:getCenter()
            g.drawImage(uinfo.image, iX, iY, 0, 2, 2)
        end
    end

    if imageR then
        return textR:union(imageR)
    else
        return textR
    end
end



---@param tinfo g.TokenInfo
---@param x number?
---@param currentY number?
local function drawTokenInfo(tinfo, x, currentY)
    
end


---@param x number?
---@param currentY number?
local function drawDescription(uinfo, x, currentY)
    -- draw 
end


---@param x number?
---@param currentY number?
local function drawPrice(uinfo, x, currentY)
    -- draw price at bottom
end


---@param uinfo g.UpgradeInfo
---@return number
---@return number
function upgrades.getUpgradeDescriptionSize(uinfo)
    return W,120
end


---@param uinfo g.UpgradeInfo
---@param x number
---@param y number
function upgrades.drawUpgradeDescription(uinfo, x,y)
    -- x,y top left

    local w,h = upgrades.getUpgradeDescriptionSize(uinfo)
    local r = Kirigami(x, y, w, h)

    -- bg:
    love.graphics.setColor(0.2,0.2,0.4,0.8)
    love.graphics.rectangle("fill", r:get())

    -- border:
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.,0.,0.08)
    love.graphics.rectangle("line", r:get())

    local contentR = r:padUnit(4)

    -- Draw title
    local titleR = drawTitle(uinfo, contentR)
    -- Draw outline
    local outlineR = contentR:padUnit(16, 0)
        :set(nil, nil, nil, 1)
        :attachToBottomOf(titleR)
        :moveUnit(0, 4)
    love.graphics.rectangle("fill", outlineR:get())

    -----------
    -- draw token-info
    -----------
    -- draw description
    -----------
    -- draw price
end

end



return upgrades


