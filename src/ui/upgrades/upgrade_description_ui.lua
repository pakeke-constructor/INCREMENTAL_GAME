

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




local GIVES_RESOURCES = loc("Gives Resources", nil, {context = "Some form of currency in a videogame"})

---Create upgrade description automatically.
---@param self ui.UpgradeDescription
---@param tree g.Tree
---@param upg g.Tree.Upgrade
local function autoBuild(self, tree, upg)
    local uinfo = self.uinfo
    local isTokenUpgrade = uinfo.kind == "TOKEN"
    if isTokenUpgrade then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)
        local img = tinfo.image
        if tinfo.growths then
            -- best we can do is set to berry/growth img
            img = tinfo.growths.growth
        end
        self:addTitle(uinfo.name, img)
    else
        self:addTitle(uinfo.name)
    end

    if isTokenUpgrade then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)
        local show = false
        for resId,v in pairs(tinfo.resources) do
            if v > 0 then
                show=true
            end
        end
        if show then
            local text = GIVES_RESOURCES
            local actualText = "{yield_scythe}"..text
            self:addDivider()
            self:addInlineText(actualText, "center", 16)
            self:addSpacer(8)
            self:addTokenInfo(tinfo)
        end
    end

    local maxLevel = tree:getUpgradeMaxLevel(upg)
    if uinfo.description then
        local level = upg.level
        local realDesc = g.getUpgradeDescription(uinfo, math.max(level, 1), level > 0 and level < maxLevel)
        self:addSpacer(8)
        self:addText(realDesc)
    end

    self:addLevel(upg.level, maxLevel)

    -- Build price tag text.
    local price = tree:getUpgradePrice(upg)
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if price[resId] and price[resId]>0 then
            self.priceInfo[#self.priceInfo+1] = {resId, g.formatNumber(price[resId])}
        end
    end
end


---@param tree g.Tree
---@param upg g.Tree.Upgrade
function UpgradeDescription:init(tree, upg)
    self.font = g.getSmallFont(16)
    self.largeFont = g.getSmallFont(32)
    self.titleFont = g.getBigFont(32)

    self.time = 0

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
    self.priceInfo = {}

    self.titleBackgroundGradient = helper.newGradientMesh("horizontal", unpack(TITLE_BACKGROUND_GRADIENT))
    self.backgroundGradient = helper.newGradientMesh("horizontal", unpack(BODY_BACKGROUND_GRADIENT))

    autoBuild(self, tree, upg)
end

if false then
    ---@param tree g.Tree
    ---@param upg g.Tree.Upgrade
    ---@return ui.UpgradeDescription
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function UpgradeDescription(tree, upg) end
end

---@return g.Tree.Upgrade
function UpgradeDescription:getUpgrade()
    return self.upg
end



---@param text string
---@param image string?
function UpgradeDescription:addTitle(text, image)
    local tw = richtext.getWidth(text, self.titleFont)
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
    local fw, lines = richtext.getWrap(txt, self.font, DESCIPTION_TEXT_MAX_WIDTH)
    local fh = self.font:getHeight() * lines
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
    local fw = richtext.getWidth(txt, self.font)
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



local LEVEL_TEXT = interp("Level %{level}/%{maxLevel}", {
    context = "As in, the level of a game upgrade. Level 5/6"
})

---@param level integer
---@param maxLevel integer
function UpgradeDescription:addLevel(level, maxLevel)
    local col = helper.multiplyAlpha(objects.Color.WHITE, 0.4)
    local text = LEVEL_TEXT{level = level, maxLevel = maxLevel}
    local fw = richtext.getWidth(text, self.font)
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
        if tinfo.resources[resId] and tinfo.resources[resId]>0 then
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



-- hover on wobble
local HOVER_ROT_AMOUNT = 0.1
local HOVER_ROT_JERK_TIME = 0.1

---@param x number
---@param y number
function UpgradeDescription:draw(x, y)
    self.time = self.time + love.timer.getAverageDelta()
    lg.push()
    if self.time < HOVER_ROT_JERK_TIME then
        local w, h = self:getMainBoxDimensions()
        local centerX = x + w / 2
        local centerY = y + h / 2

        -- Lerp from ROT_AMOUNT to 0 with wobble
        local t = self.time / HOVER_ROT_JERK_TIME
        local eased = helper.EASINGS.easeOutBack(t)
        local wobble = math.sin(t * math.pi * 3) * (1 - t) * HOVER_ROT_AMOUNT
        local currentRotation = HOVER_ROT_AMOUNT * (1 - eased) + wobble
        lg.translate(centerX, centerY)
        lg.rotate(currentRotation)
        lg.translate(-centerX, -centerY)
    end

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

    local level = upg.level
    local maxLevel = self.tree:getUpgradeMaxLevel(self.upg)
    if level < maxLevel then
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

    lg.pop()
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
    local maxLevel = self.tree:getUpgradeMaxLevel(self.upg)
    local width, height = self:getMainBoxDimensions()
    local ptagW, ptagH = 0, -PRICE_TAG_OFFSET
    if self.upg.level < maxLevel then
        ptagW, ptagH = self:_getPriceTagDimensions(true)
    end
    return math.max(width, ptagW), height + ptagH + PRICE_TAG_OFFSET
end





---@param canAfford boolean
---@private
function UpgradeDescription:_getPriceTagDimensions(canAfford)
    local ptagQH = select(4, g.getImageQuad("pricetag_can_afford"):getViewport()) --[[@as number]]
    local ptagText = self:_createPriceTagString(canAfford)

    local ptagWidth = richtext.getWidth(ptagText, self.largeFont)
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

    for _, pt in ipairs(self.priceInfo) do
        local resInfo = g.getResourceInfo(pt[1])
        local col = objects.Color.BLACK
        if g.isResourceUnlocked(pt[1]) then
            col = objects.Color.WHITE
        end
        result[#result+1] = helper.wrapRichtextColor(col, " {"..resInfo.image.."} ")

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
