local Pass = require(".Pass")
local parser = require(".parser")
local defaultEffectGroup = require(".defaultEffectGroup")

---@param pass text.Pass
---@param txt text.ParsedText
local function insertToTextPass(pass, txt)
    for _, data in ipairs(txt) do
        if type(data) == "table" then
            local effectName = data[1]
            local isImage = defaultEffectGroup:getType(effectName) == "IMAGE"
            if isImage then
                pass:addImage(defaultEffectGroup:getImageInfo(effectName), data.scale)
            else
                pass:addEffect(data)
            end
        else
            for _, c in utf8.codes(data) do
                pass:add(utf8.char(c))
            end
        end
    end

    pass:add(nil) -- flush
end

-- ---@type text.Pass
-- local pass = Pass(nil, 0, "left", nil)
local drawRichText

---Draw rich text.
---@param txt text.ParsedText|string Formatted rich text string or parsed rich text data.
---@param font love.Font Font object to use
---@param limit number Maximum width before word-wrapping.
---@param align love.AlignMode (justify is not supported)
---@param transform love.Transform Transformation stack to apply.
---@return boolean,(string|nil)
---@diagnostic disable-next-line: missing-return
function drawRichText(txt, font, transform, limit, align) end

---Draw rich text directly without state.
---@param txt text.ParsedText|string Formatted rich text string or parsed rich text data.
---@param font love.Font Font object to use
---@param x number
---@param y number
---@param limit number Maximum width before word-wrapping.
---@param align love.AlignMode (justify is not supported)
---@param rot number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
---@param kx number?
---@param ky number?
---@return boolean,(string|nil)
function drawRichText(txt, font, x, y, limit, align, rot, sx, sy, ox, oy, kx, ky)
    if typecheck.isType(x, "love:Transform") then
        align = limit
        limit = y
        y, rot = nil, nil
        sx, sy = nil, nil
        ox, oy = nil, nil
        kx, ky = nil, nil
    end

    love.graphics.push("all")
    love.graphics.applyTransform(x, y, rot, sx, sy, ox, oy, kx, ky)

    local r, g, b, a = love.graphics.getColor()
    local pass = Pass(font, limit, align, {r, g, b, a})
    insertToTextPass(pass, assert(parser.ensure(txt)))

    love.graphics.pop()
    return true
end

---@param txt text.ParsedText
local function stripEffects(txt)
    local result = {}

    for _, data in ipairs(txt) do
        if type(data) == "string" then
            result[#result+1] = data
        end
    end

    return table.concat(result)
end

---@param txt text.ParsedText
local function hasImageInParsed(txt)
    for _, data in ipairs(txt) do
        if type(data) == "table" then
            local effectName = data[1]
            if defaultEffectGroup:getType(effectName) == "IMAGE" then
                return true
            end
        end
    end

    return false
end

---@param text string|text.ParsedText
---@param font love.Font
---@param maxwidth number
local function getWrap(text, font, maxwidth)
    local parsed = assert(parser.ensure(text))
    if hasImageInParsed(parsed) then
        local pass = Pass(font, maxwidth, "left", nil)
        insertToTextPass(pass, assert(parser.ensure(text)))
        return pass:getWrap()
    else
        local unparsed = stripEffects(parsed)
        local width, lines = font:getWrap(unparsed, maxwidth)
        return width, #lines
    end
end

---@param text string|text.ParsedText
---@param font love.Font
local function getWidth(text, font)
    return (getWrap(text, font, 2147483647))
end

return {
    draw = drawRichText,
    getWrap = getWrap,
    getWidth = getWidth,
    strip = stripEffects,
}