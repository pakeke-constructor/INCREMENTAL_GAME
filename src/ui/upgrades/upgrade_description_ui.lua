


---@class ui.UpgradeDescription: objects.Class
local UpgradeDescription = objects.Class("g:UpgradeDescription")


local UPGRADE_DESC_MAX_WIDTH = 200

function UpgradeDescription:init()
    self.font = g.getSmallFont(16)
    self.titleFont = g.getBigFont(32)

    self.boxWidth = 100

    ---@class ui._UpgradeDescriptionElem
    ---@field package width number|nil
    ---@field package height number
    ---@field package render fun(x:number,y:number,w:number,h:number)
    ---@type ui._UpgradeDescriptionElem[]
    self.elements = {}

end

if false then
    ---@return ui.UpgradeDescription
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function UpgradeDescription() end
end



---@param uinfo g.UpgradeInfo
---@param level integer
---@param nextLevel boolean? (Display next level values?)
local function getUpgradeDescription(uinfo, level, nextLevel)
    if not uinfo.description then
        return ""
    end

    local currentValues = {uinfo:getValues(level)}
    local nextValues = nil
    if nextLevel then
        nextValues = {uinfo:getValues(level + 1)}
        assert(#currentValues == #nextValues)
    end
    local displayValue = {}
    for i = 1, #currentValues do
        local formatter = uinfo.valueFormatter[i]
        local value

        if type(formatter) == "string" then
            if nextValues then
                value = string.format(formatter.." -> "..formatter, currentValues[i], nextValues[i])
            else
                value = string.format(formatter, currentValues[i])
            end
        else
            local val = formatter(currentValues[i])
            if nextValues then
                val = val.." -> "..formatter(nextValues[i])
            end
        end

        displayValue[tostring(i)] = value
    end

    -- TODO: Clarify if the description should be passed to interpolator or it's already in localization.Interpolator
    return loc(uinfo.description, displayValue)
end


---Create upgrade description automatically.
---@param uinfo g.UpgradeInfo
function UpgradeDescription:autoBuild(uinfo)
    self:addTitle(uinfo.name, uinfo.image)
    self:addDivider()

    if uinfo.kind == "TOKEN" then
        local tinfo = g.getTokenInfo(uinfo.tokenType or uinfo.type)

        -- Draw token info
        ---@type [string, string][]
        local defs = {}
        for _, resId in ipairs(g.RESOURCE_LIST) do
            if tinfo.resources[resId] then
                defs[#defs+1] = {g.getResourceInfo(resId).image, "+"..g.formatNumber(tinfo.resources[resId])}
            end
        end

        -- Lifetime always on 2nd column 1stfirst row
        if #defs > 0 then
            table.insert(defs, 2, {"health_icon", tostring(tinfo.maxHealth)})
        else
            defs[#defs+1] = {"health_icon", tostring(tinfo.maxHealth)}
        end

        self:addTextImageGrid(false, defs)
        self:addDivider()

        if tinfo.description then
            self:addText(tinfo.description)
            self:addDivider()
        end
    elseif uinfo.description then
        local level = g.getUpgradeLevel(uinfo)
        local realDesc = getUpgradeDescription(uinfo, math.max(level, 1), level > 0)
        self:addText(realDesc)
        self:addDivider()
    end

    -- Just pick first price in resource for now
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


local DISTANCE_BETWEEN_TEXT_AND_IMAGE = 2

---@param font love.Font
---@param image string
---@param text string
---@return number
local function computeWidthOfImageText(font, image, text)
    local imgq = g.getImageQuad(image)
    local textw = font:getWidth(richtext.stripEffects(text))
    return select(3, imgq:getViewport()) + textw + DISTANCE_BETWEEN_TEXT_AND_IMAGE
end

---@param imagefirst boolean
---@param defs {[1]:string,[2]:string}[] (first element is image, second element is text)
---@param scale number?
function UpgradeDescription:addTextImageGrid(imagefirst, defs, scale)
    scale = scale or 1
    local rows = math.ceil(#defs / 2)
    local minwidth = self.boxWidth

    for i = 1, #defs, 2 do
        local width = computeWidthOfImageText(self.font, defs[i][1], defs[i][2]) * scale

        if defs[i + 1] then
            width = width + 8 + computeWidthOfImageText(self.font, defs[i + 1][1], defs[i + 1][2]) * scale
        end

        minwidth = math.max(minwidth, width)
    end

    -- Used for splitVertical
    local rowgen = {}
    for _ = 1, rows do
        rowgen[#rowgen+1] = 1
    end

    -- Update the box width
    self.boxWidth = math.max(self.boxWidth, minwidth)
    -- But respect the boxWidth dimension in case it's larger (so width is nil)
    return self:addBox(nil, rows * 16, function(x, y, w, h)
        local root = Kirigami(x, y, w, h)
        ---@type layout.Region[][]
        local rowsR = {}

        -- Generate cells
        for _, rowR in ipairs({root:splitVertical(unpack(rowgen))}) do
            rowsR[#rowsR+1] = {rowR:splitHorizontal(1, 1)}
        end

        for i, def in ipairs(defs) do
            local cellR = rowsR[math.floor((i - 1) / 2) + 1][(i - 1) % 2 + 1]
            local rx, ry, rw, rh = cellR:get()
            local imageWidth = select(3, g.getImageQuad(def[1]):getViewport()) --[[@as number]]
            local textWidth = self.font:getWidth(richtext.stripEffects(def[2]))

            if imagefirst then
                g.drawImageOffset(def[1], rx, ry, 0, 1, 1, 0, 0)
                richtext.printRich(
                    def[2], self.font, rx + imageWidth + DISTANCE_BETWEEN_TEXT_AND_IMAGE, ry, textWidth, "left"
                )
            else
                richtext.printRich(def[2], self.font, rx, ry, textWidth, "left")
                g.drawImageOffset(def[1], rx + textWidth + DISTANCE_BETWEEN_TEXT_AND_IMAGE, ry, 0, 1, 1, 0, 0)
            end
        end
    end)
end


---@param bundle g.Bundle
function UpgradeDescription:addPrice(bundle)
    -- TODO: Support more than 1 resource while keeping the "Price" text inline
    -- It will be layouting nightmare though!
    local res, value = next(bundle)
    if res then
        assert(value)
        local resInfo = g.getResourceInfo(res)
        local imageWidth = select(3, g.getImageQuad(resInfo.image):getViewport()) --[[@as number]]
        self:addBox(nil, 16, function(x, y, w, h)
            local priceR, resourceR = Kirigami(x, y, w, h):splitHorizontal(1, 1)

            local px, py = priceR:get()
            love.graphics.print("Price", self.font, px, py)

            local rx, ry = resourceR:get()
            g.drawImageOffset(resInfo.image, rx, ry, 0, 1, 1, 0, 0)
            love.graphics.print(g.formatNumber(value), self.font, rx + imageWidth + 2, ry)
        end)
    end
    --[[
    -- adds the price at the bottom
    local prices = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if bundle[resId] then
            prices[#prices+1] = {g.getResourceInfo(resId).image, g.formatNumber(bundle[resId])}
        end
    end
    self:addTextImageGrid(true, prices)
    ]]
end


---@param startx number
---@param starty number
function UpgradeDescription:draw(startx, starty)
    local yoff = 0
    for _, elem in ipairs(self.elements) do
        local width = elem.width or self.boxWidth
        local xoff = (self.boxWidth - width) / 2
        elem.render(startx + xoff, starty + yoff, width, elem.height)
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

    return width, height
end


return UpgradeDescription
