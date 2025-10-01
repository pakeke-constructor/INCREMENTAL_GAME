


---@class g.UpgradeDescription: objects.Class
local UpgradeDescription = objects.Class("g:UpgradeDescription")


local UPGRADE_DESC_MAX_WIDTH = 200

---@param uinfo g.UpgradeInfo
function UpgradeDescription:init(uinfo)
    self.font = g.getSmallFont(16)
    self.titleFont = g.getBigFont(32)

    self.boxWidth = 100

    ---@class g._UpgradeDescriptionElem
    ---@field package width number|nil
    ---@field package height number
    ---@field package render fun(x:number,y:number,w:number,h:number)
    ---@type g._UpgradeDescriptionElem[]
    self.elements = {}

end

if false then
    ---@param uinfo g.UpgradeInfo
    ---@return g.UpgradeDescription
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function UpgradeDescription(uinfo) end
end


---@param uinfo g.UpgradeInfo
function UpgradeDescription:autoBuild(uinfo)
    self:addTitle(uinfo.name, uinfo.image)
    self:addDivider()

    if uinfo.kind == "TOKEN" then
        -- Draw token info
    end

    -- FIXME: Price is dynamic
    self:addPrice(uinfo.price)
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


---@param txt string
function UpgradeDescription:addText(txt)
    local stripped = richtext.stripEffects(txt)
    local fw, lines = self.font:getWrap(stripped, UPGRADE_DESC_MAX_WIDTH)
    local fh = self.font:getHeight() * #lines

    return self:addBox(fw, fh, function(x,y,w,h)
        richtext.printRich(txt, self.font, x,y, w, "center")
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
function UpgradeDescription:addTextImageGrid(imagefirst, defs)
    local rows = math.ceil(#defs / 2)
    local minwidth = self.boxWidth

    for i = 1, #defs, 2 do
        local width = computeWidthOfImageText(self.font, defs[i][1], defs[i][2])

        if defs[i + 1] then
            width = width + 8 + computeWidthOfImageText(self.font, defs[i + 1][1], defs[i + 1][2])
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
            local cellR = rowsR[math.floor(i / 2)][(i - 1) % 2 + 1]
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
    -- adds the price at the bottom
    local prices = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        if bundle[resId] then
            prices[#prices+1] = {g.getResourceInfo(resId).image, g.formatNumber(bundle[resId])}
        end
    end
    self:addTextImageGrid(true, prices)
end


---@param x number
---@param y number
function UpgradeDescription:draw(x, y)
    
end

function UpgradeDescription:getDimensions()
    local width, height = self.boxWidth, 0

    for _, elem in ipairs(self.elements) do
        if elem.width then
            width = math.max(width, elem.width)
        end
        height = math.max(height, elem.height)
    end

    return width, height
end


return UpgradeDescription
