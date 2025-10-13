


---@class ui.UpgradeDescription: objects.Class
local UpgradeDescription = objects.Class("g:UpgradeDescription")


local UPGRADE_DESC_MAX_WIDTH = 200
local CONTENT_PADDING = 8

---@param uinfo g.UpgradeInfo
function UpgradeDescription:init(uinfo)
    self.font = g.getSmallFont(16)
    self.titleFont = g.getBigFont(32)

    self.boxWidth = 100

    ---@class ui._UpgradeDescriptionElem
    ---@field package width number|nil
    ---@field package height number
    ---@field package render fun(x:number,y:number,w:number,h:number)
    ---@type ui._UpgradeDescriptionElem[]
    self.elements = {}
    self.uinfo = uinfo

    self:autoBuild(uinfo)
end

if false then
    ---@param uinfo g.UpgradeInfo
    ---@return ui.UpgradeDescription
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function UpgradeDescription(uinfo) end
end

function UpgradeDescription:getType()
    return self.uinfo.type
end


local STAT_UP_COLOR = {0.94, 0.56, 0.99}
---@param col [number, number, number]
---@param text string
local function wrapColor(col, text)
    return "{c r="..col[1].." g="..col[2].." b="..col[3].."}"..text.."{/c}"
end

---@param uinfo g.UpgradeInfo
---@param level integer
---@param nextLevel boolean? (Display next level values?)
local function getUpgradeDescription(uinfo, level, nextLevel)
    if not uinfo.description then
        return ""
    end

    local displayValue = {}

    if uinfo.getValues then
        local currentValues = {uinfo:getValues(level)}
        local nextValues = nil
        if nextLevel then
            nextValues = {uinfo:getValues(level + 1)}
            assert(#currentValues == #nextValues)
        end

        for i = 1, #currentValues do
            local formatter = uinfo.valueFormatter[i] or "%.14g"
            local value

            if type(formatter) == "string" then
                value = string.format(formatter, currentValues[i])
                if nextValues then
                    value = value..string.format(wrapColor(STAT_UP_COLOR, " -> "..formatter), nextValues[i])
                end
            else
                value = formatter(currentValues[i])
                if nextValues then
                    value = value..wrapColor(STAT_UP_COLOR, " -> "..formatter(nextValues[i]))
                end
            end

            displayValue[tostring(i)] = value
        end
    end

    -- TODO: Clarify if the description should be passed to interpolator or it's already in localization.Interpolator
    return loc(uinfo.description, displayValue)
end


---Create upgrade description automatically.
---@param uinfo g.UpgradeInfo
function UpgradeDescription:autoBuild(uinfo)
    local isTokenUpgrade = uinfo.kind == "TOKEN"
    if isTokenUpgrade then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)
        self:addTitle(uinfo.name, tinfo.image)
    else
        self:addTitle(uinfo.name)
    end
    self:addDivider()

    if isTokenUpgrade then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)
        self:addTokenInfo(tinfo)
        self:addDivider()

        if tinfo.description then
            self:addText(tinfo.description)
            self:addDivider()
        end
    elseif uinfo.description then
        local level = g.getUpgradeLevel(uinfo)
        local realDesc = getUpgradeDescription(uinfo, math.max(level, 1), level > 0 and level < uinfo.maxLevel)
        self:addText(realDesc)
        self:addDivider()
    end

    self:addPrice(g.getUpgradePrice(uinfo))
end


---@param text string
---@param image string?
function UpgradeDescription:addTitle(text, image)
    local tw = self.titleFont:getWidth(richtext.stripEffects(text))
    local th = self.titleFont:getHeight()

    if image then
        -- Text and image side-by-side
        -- 4 is spacing between text and image
        return self:addBox(tw + th + 4, th, function(x, y, w, h)
            richtext.printRich(text, self.titleFont, x, y, w, "left")
            -- It's just simpler to specify 0,0 offset
            g.drawImageOffset(image, x + w - h, y, 0, 2, 2, 0, 0)
        end)
    else
        -- Text only
        return self:addBox(tw, th, function(x, y, w, h)
            richtext.printRich(text, self.titleFont, x, y, w, "left")
        end)
    end
end


---@param x number
---@param y number
---@param w number
---@param h number
local function drawDivider(x, y, w, h)
    love.graphics.line(x + 8, y + h / 2, x + w - 8, y + h / 2)
end

---Divider always takes height of 8 and width of self.boxWidth - 16
function UpgradeDescription:addDivider()
    return self:addBox(nil, 8, drawDivider)
end


---This centers the text
---@param txt string
---@param align love.AlignMode?
function UpgradeDescription:addText(txt, align)
    local stripped = richtext.stripEffects(txt)
    local fw, lines = self.font:getWrap(stripped, UPGRADE_DESC_MAX_WIDTH)
    local fh = self.font:getHeight() * #lines
    align = align or "center"

    -- Update the box width
    self.boxWidth = math.max(self.boxWidth, fw)
    -- But respect the boxWidth dimension in case it's larger (so width is nil)
    -- this is needed so that alignment other than "center" works.
    return self:addBox(nil, fh, function(x,y,w,h)
        richtext.printRich(txt, self.font, x,y, w, align)
    end)
end



---@param w number|nil (specify nil to follow current box width)
---@param h number
---@param render fun(x:number,y:number,w:number,h:number)
function UpgradeDescription:addBox(w, h, render)
    self.elements[#self.elements+1] = {width = w, height = h, render = render}

    if w then
        self.boxWidth = math.min(math.max(self.boxWidth, w), UPGRADE_DESC_MAX_WIDTH)
    end
end

---@param bundle g.Bundle
function UpgradeDescription:addPrice(bundle)
    -- TODO: Support more than 1 resource while keeping the "Price" text inline
    -- It will be layouting nightmare though!
    ---@type string[]
    local resdata = {"Price"}

    for _, resId in ipairs(g.RESOURCE_LIST) do
        if bundle[resId] then
            local resInfo = g.getResourceInfo(resId)
            resdata[#resdata+1] = "{"..resInfo.image.."}"..g.formatNumber(bundle[resId])
        end
    end

    local actualText = table.concat(resdata, " ")
    local textWidth = self.font:getWidth(richtext.stripEffects(actualText)) + 16 * (#resdata - 1)
    return self:addBox(textWidth, self.font:getHeight(), function(x, y, w, h)
        richtext.printRich(actualText, self.font, x, y, w, "center")
    end)
end

---@param tinfo g.TokenInfo
function UpgradeDescription:addTokenInfo(tinfo)
    -- Token info layout is:
    -- * Left-side: List of resource it gives
    -- * Right-side: Health icon, centered.

    ---@type string[]
    local resources = {}
    local splits = {} -- For Kirigami only
    local healthText = tostring(tinfo.maxHealth)
    local healthWidth = (self.font:getWidth(healthText) + 16 + 2) * 2 -- +2 padding, x2 scaling
    local minWidth = healthWidth * 2 + 8 -- +8 distance between text

    for _, resId in ipairs(g.RESOURCE_LIST) do
        if tinfo.resources[resId] then
            -- TODO: Dynamic resource output
            local resInfo = g.getResourceInfo(resId)
            local value = "+"..g.formatNumber(tinfo.resources[resId])
            local textWidth = (self.font:getWidth(value) + 16 + 2) * 2
            resources[#resources+1] = value.."{"..resInfo.image.."}"
            splits[#splits+1] = 1
            minWidth = math.max(minWidth, textWidth + healthWidth + 8)
        end
    end

    local fontHeight = self.font:getHeight() * 2
    local height = #resources * fontHeight
    -- Update the box width
    self.boxWidth = math.max(self.boxWidth, minWidth)
    -- But respect the boxWidth dimension in case it's larger (so width is nil)
    return self:addBox(nil, height, function (x, y, w, h)
        local r = Kirigami(x, y, w, h)
        local leftR, rightR = r:splitHorizontal(1, 1)
        local rowsR = {leftR:splitVertical(unpack(splits))}

        for i, res in ipairs(resources) do
            local ix, iy, iw = rowsR[i]:get()
            richtext.printRich(res, self.font, ix, iy, iw / 2, "center", 0, 2, 2)
        end

        local healthR = rightR:set(nil, nil, nil, fontHeight):center(rightR)
        local ix, iy, iw = healthR:get()
        richtext.printRich("{health_icon}"..healthText, self.font, ix, iy, iw / 2, "center", 0, 2, 2)
    end)
end


---@param x number
---@param y number
function UpgradeDescription:draw(x, y)
    local w, h = self:getDimensions()

    -- Draw background color
    if g.canAfford(g.getUpgradePrice(self.uinfo)) then
        love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    else
        love.graphics.setColor(0.4, 0.2, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", x, y, w, h)

    -- Draw border
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.,0.,0.08)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setLineWidth(lw)

    -- Start drawing the content
    love.graphics.setColor(1,1,1)
    x = x + CONTENT_PADDING
    y = y + CONTENT_PADDING

    local yoff = 0
    for _, elem in ipairs(self.elements) do
        local width = elem.width or self.boxWidth
        local xoff = (self.boxWidth - width) / 2
        elem.render(x + xoff, y + yoff, width, elem.height)
        yoff = yoff + elem.height
    end
end

function UpgradeDescription:getDimensions()
    local width, height = self.boxWidth, 0

    for _, elem in ipairs(self.elements) do
        if elem.width then
            width = math.max(width, elem.width)
        end
        height = height + elem.height
    end

    return width + 2 * CONTENT_PADDING, height + 2 * CONTENT_PADDING
end


return UpgradeDescription
