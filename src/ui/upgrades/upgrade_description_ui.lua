

local n9slice = require("src.modules.n9slice.n9slice")

---@class ui.UpgradeDescription: objects.Class
local UpgradeDescription = objects.Class("g:UpgradeDescription")


local CONTENT_PADDING = 9
local CONTENT_PADDING_BLACK_BORDER = 3
local DESCIPTION_TEXT_MAX_WIDTH = 200

local PRICE_TAG_PADDING = 16
local PRICE_TAG_OFFSET = -5


local UI_PANEL_COLOR = objects.Color("#".."FF14A0CD")
local TITLE_BACKGROUND_GRADIENT = {UI_PANEL_COLOR, objects.Color("#".."ff191e3c")}
local BODY_BACKGROUND_GRADIENT = {objects.Color("#".."FF14465A"), objects.Color("#".."ff191e3c")}



local STAT_UP_COLOR = objects.Color("#".."FFEF8EFC")

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
                    value = value..string.format(helper.wrapRichtextColor(STAT_UP_COLOR, " -> "..formatter), nextValues[i])
                end
            else
                value = formatter(currentValues[i])
                if nextValues then
                    value = value..helper.wrapRichtextColor(STAT_UP_COLOR, " -> "..formatter(nextValues[i]))
                end
            end

            displayValue[tostring(i)] = value
        end
    end

    return uinfo.description(displayValue)
end




---Create upgrade description automatically.
---@param self ui.UpgradeDescription
---@param tree g.UpgradeTree
---@param upg g.UpgradeTree.Upgrade
local function autoBuild(self, tree, upg)
    local uinfo = self.uinfo
    local isTokenUpgrade = uinfo.kind == "TOKEN"
    if isTokenUpgrade then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)
        self:addTitle(uinfo.name, tinfo.image)
    else
        self:addTitle(uinfo.name)
    end

    if isTokenUpgrade then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)
        if next(tinfo.resources) then
            local text = loc "Gives Resources"
            local actualText = "{yield_scythe}"..text
            self:addDivider()
            self:addInlineText(actualText, "center", 16)
            self:addSpacer(8)
            self:addTokenInfo(tinfo)
        end
    end

    if uinfo.description then
        local level = g.getUpgradeLevel(uinfo)
        local realDesc = getUpgradeDescription(uinfo, math.max(level, 1), level > 0 and level < uinfo.maxLevel)
        self:addSpacer(8)
        self:addText(realDesc)
    end

    self:addLevel(g.getUpgradeLevel(uinfo), uinfo.maxLevel)

    -- Build price tag text.
    local price = tree:getUpgradePrice(upg)
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if price[resId] then
            self.priceText[#self.priceText+1] = {resId, g.formatNumber(price[resId])}
            self.priceImageCount = self.priceImageCount + 1
        end
    end
end


---@param tree g.UpgradeTree
---@param upg g.UpgradeTree.Upgrade
function UpgradeDescription:init(tree, upg)
    self.font = g.getSmallFont(16)
    self.largeFont = g.getSmallFont(32)
    self.titleFont = g.getBigFont(32)

    self.boxWidth = 100

    ---@class ui._UpgradeDescriptionElem
    ---@field package width number|nil
    ---@field package height number
    ---@field package render fun(x:number,y:number,w:number,h:number)
    ---@type ui._UpgradeDescriptionElem[]
    self.elements = {}

    self.tree = tree
    self.upg = upg
    self.uinfo = assert(g.getUpgradeInfo(upg.id))

    self.priceTagPanels = {
        [true] = n9slice.new {
            image = g.getAtlas(),
            padding = {PRICE_TAG_PADDING, 0},
            quad = g.getImageQuad("pricetag_can_afford")
        },
        [false] = n9slice.new {
            image = g.getAtlas(),
            padding = {PRICE_TAG_PADDING, 0},
            quad = g.getImageQuad("pricetag_cant_afford")
        }
    }
    ---@type [g.ResourceType,string][]
    self.priceText = {}
    -- richText.stripEffects also strips image identifier
    -- so it's gone when passed through Font:getWidth()
    -- This means we have to track manually how many images it is.
    self.priceImageCount = 0

    self.titleBackgroundGradient = helper.newGradientMesh("horizontal", unpack(TITLE_BACKGROUND_GRADIENT))
    self.backgroundGradient = helper.newGradientMesh("horizontal", unpack(BODY_BACKGROUND_GRADIENT))

    autoBuild(self, tree, upg)
end

if false then
    ---@param uinfo g.UpgradeInfo
    ---@return ui.UpgradeDescription
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function UpgradeDescription(uinfo) end
end

---@return g.UpgradeTree.Upgrade
function UpgradeDescription:getUpgrade()
    return self.upg
end



---@param text string
---@param image string?
function UpgradeDescription:addTitle(text, image)
    local tw = self.titleFont:getWidth(richtext.stripEffects(text))
    local th = self.titleFont:getHeight()

    if image then
        -- Text and image side-by-side
        -- +32 because token image takes 16 pixel and we're using font size of 32px.
        tw = tw + 32 + self.titleFont:getWidth(" ")
        text = "{"..image.."} "..text
    end

    return self:addBox(tw, th, function(x, y, w, h)
        richtext.printRich(text, self.titleFont, x, y, 1000, "left")
    end)
end


---@param x number
---@param y number
---@param w number
---@param h number
local function drawDivider(x, y, w, h)
    local pad = CONTENT_PADDING - CONTENT_PADDING_BLACK_BORDER
    love.graphics.setColor(UI_PANEL_COLOR)
    love.graphics.rectangle("fill", x - pad, y + math.floor(h / 2), w + 2 * pad, 2)
end

---Divider always takes height of 4
function UpgradeDescription:addDivider()
    return self:addBox(nil, 4, drawDivider)
end


---This centers the text
---@param txt string
---@param align love.AlignMode?
function UpgradeDescription:addText(txt, align)
    local stripped = richtext.stripEffects(txt)
    local fw, lines = self.font:getWrap(stripped, DESCIPTION_TEXT_MAX_WIDTH)
    local fh = self.font:getHeight() * #lines
    align = align or "center"

    -- Update the box width
    self.boxWidth = math.max(self.boxWidth, fw)
    -- But respect the boxWidth dimension in case it's larger (so width is nil)
    -- this is needed so that alignment other than "center" works.
    return self:addBox(nil, fh, function(x,y,w,h)
        love.graphics.setColor(1, 1, 1)
        richtext.printRich(txt, self.font, x,y, w, align)
    end)
end

---This centers the text but no wrapping
---@param txt string
---@param align love.AlignMode?
---@param extraw number?
function UpgradeDescription:addInlineText(txt, align, extraw)
    local stripped = richtext.stripEffects(txt)
    local fw = self.font:getWidth(stripped)
    local fh = self.font:getHeight()
    align = align or "center"
    fw = fw + (extraw or 0)

    -- Update the box width
    self.boxWidth = math.max(self.boxWidth, fw)
    -- But respect the boxWidth dimension in case it's larger (so width is nil)
    -- this is needed so that alignment other than "center" works.
    return self:addBox(nil, fh, function(x,y,w,h)
        love.graphics.setColor(1, 1, 1)
        richtext.printRich(txt, self.font, x,y, w, align)
    end)
end




local function dummy() end
---@param h number
function UpgradeDescription:addSpacer(h)
    return self:addBox(nil, h, dummy)
end

---@param w number|nil (specify nil to follow current box width)
---@param h number
---@param render fun(x:number,y:number,w:number,h:number)
function UpgradeDescription:addBox(w, h, render)
    self.elements[#self.elements+1] = {width = w, height = h, render = render}

    if w then
        self.boxWidth = math.max(self.boxWidth, w)
    end
end


---@param level integer
---@param maxLevel integer
function UpgradeDescription:addLevel(level, maxLevel)
    local col = helper.multiplyAlpha(objects.Color.WHITE, 0.4)
    local text = loc("Level %{level}/%{maxLevel}", {level = level, maxLevel = maxLevel})
    local fw = self.font:getWidth(richtext.stripEffects(text))
    local fh = self.font:getHeight()

    self.boxWidth = math.max(self.boxWidth, fw)
    return self:addBox(nil, fh, function(x,y,w,h)
        love.graphics.setColor(col)
        richtext.printRich(text, self.font, x,y, w, "center")
    end)
end

---@param tinfo g.TokenInfo
function UpgradeDescription:addTokenInfo(tinfo)
    -- Token info layout is just grid.

    ---@type string[]
    local resources = {}
    local minCellWidth = 0

    for _, resId in ipairs(g.RESOURCE_LIST) do
        if tinfo.resources[resId] then
            -- TODO: Dynamic resource output
            local resInfo = g.getResourceInfo(resId)
            local value = "+"..g.formatNumber(tinfo.resources[resId])
            -- +32 for resource icon, +4 for padding
            local textWidth = self.largeFont:getWidth(value) + 32 + 4
            resources[#resources+1] = " {"..resInfo.image.."}"..value
            minCellWidth = math.max(minCellWidth, textWidth)
        end
    end
    local rows = math.ceil(#resources / 2)

    if rows == 0 then
        -- Nothing to add
        return
    end

    local fontHeight = self.font:getHeight() * 2
    local height = rows * fontHeight
    -- Update the box width
    self.boxWidth = math.max(self.boxWidth, minCellWidth * 2)
    -- But respect the boxWidth dimension in case it's larger (so width is nil)
    return self:addBox(nil, height, function (x, y, w, h)
        local r = Kirigami(x, y, w, h)
        local cellsR = r:grid(2, rows)

        for i = 1, #resources do
            local cellR = cellsR[i]
            richtext.printRich(resources[i], self.largeFont, cellR.x, cellR.y, 1000, "left")
        end
    end)
end


---@param x number
---@param y number
function UpgradeDescription:draw(x, y)
    local w, h = self:getMainBoxDimensions()
    local uinfo = g.getUpgradeInfo(self.upg.id)
    local upg = self.upg
    local tree = self.tree

    -- Draw background color
    -- I'm sorry for have failed to create flexible system. These offset and sizes
    -- are hardcoded. I can't find a way to make it modular with simple code.
    do
        local p = 4
        local heightdivider = 41
        love.graphics.draw(self.titleBackgroundGradient, x + p, y + p, 0, w - 2 * p, heightdivider)
        love.graphics.draw(self.backgroundGradient, x + p, y + heightdivider + p, 0, w - 2 * p, h - heightdivider - p)
    end

    -- Draw border
    love.graphics.setColor(UI_PANEL_COLOR)
    ui.drawPanel(x, y, w, h)

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

    local level = g.getUpgradeLevel(uinfo)
    if level < uinfo.maxLevel then
        local canAfford = g.canAfford(tree:getUpgradePrice(upg))
        -- Start drawing price tag
        love.graphics.setColor(1,1,1)

        -- Yeah I'm lazy calculating layout by hand
        local r = Kirigami(x - CONTENT_PADDING, y - CONTENT_PADDING, w, h)
        local ptagW, ptagH, ptagText = self:_getPriceTagDimensions(canAfford)
        local ptagR = Kirigami(0, 0, ptagW, ptagH)
            :attachToBottomOf(r)
            :centerX(r)
            :moveUnit(0, PRICE_TAG_OFFSET)
        self.priceTagPanels[canAfford]:drawConstraint(ptagR)

        richtext.printRich(ptagText, self.largeFont, ptagR.x - 4, ptagR.y + 6, ptagR.w, "center")
    end
end

---@return integer
---@return integer
function UpgradeDescription:getMainBoxDimensions()
    local width, height = self.boxWidth, 0

    for _, elem in ipairs(self.elements) do
        if elem.width then
            width = math.max(width, elem.width)
        end
        height = height + elem.height
    end

    return width + 2 * CONTENT_PADDING, height + 2 * CONTENT_PADDING
end

---@return number
---@return number
function UpgradeDescription:getDimensions()
    local width, height = self:getMainBoxDimensions()
    local ptagW, ptagH = 0, -PRICE_TAG_OFFSET
    if g.getUpgradeLevel(self.uinfo) < self.uinfo.maxLevel then
        ptagW, ptagH = self:_getPriceTagDimensions(true)
    end
    return math.max(width, ptagW), height + ptagH + PRICE_TAG_OFFSET
end





---@param canAfford boolean
---@private
function UpgradeDescription:_getPriceTagDimensions(canAfford)
    local ptagQH = select(4, g.getImageQuad("pricetag_can_afford"):getViewport()) --[[@as number]]
    local ptagText = self:_createPriceTagString(canAfford)

    local ptagWidth = self.largeFont:getWidth(richtext.stripEffects(ptagText))
        + self.priceImageCount * 32
        + CONTENT_PADDING * 2
        + 8
    return ptagWidth, ptagQH, ptagText
end

---@param canAfford boolean
---@private
function UpgradeDescription:_createPriceTagString(canAfford)
    local result = {}
    local price = self.tree:getUpgradePrice(self.upg)
    local alpha = canAfford and 1 or 0.75

    for _, pt in ipairs(self.priceText) do
        local resInfo = g.getResourceInfo(pt[1])
        local col = objects.Color.BLACK
        if g.isResourceUnlocked(pt[1]) then
            col = objects.Color.WHITE
        end
        result[#result+1] = helper.wrapRichtextColor(col, " {"..resInfo.image.."}")

        local textcol
        if g.getResource(pt[1]) >= price[pt[1]] then
            textcol = g.COLORS.CAN_AFFORD
        else
            textcol = g.COLORS.CANT_AFFORD
        end
        result[#result+1] = helper.wrapRichtextColor(helper.multiplyAlpha(textcol, alpha), g.formatNumber(price[pt[1]]))
    end

    return table.concat(result).." "
end


return UpgradeDescription
