local richtext = require(".richtext")
local lru = require("lib.lru")

---@class text
local text = {}

local INVALID_CHARS = "%{}"
local function assertNameValid(name)
    for ci = 1,#INVALID_CHARS do
        local c = INVALID_CHARS:sub(ci,ci)
        if name:find(c, 1, true) then
            error("Invalid character in name:  " .. c, 3)
        end
    end
end

--- Define a new effect for rich text formatting 
---@generic T
---@param name string Effect name.
---@param effectupdate richtext.EffectFunc
---@param opts {perCharacter: boolean}?
function text.defineEffect(name, effectupdate, opts)
    assertNameValid(name)
    return richtext.registerEffect(name, effectupdate, opts)
end


--- Define a new effect for rich text formatting 
---@generic T
---@param name string Effect name.
---@param tex love.Texture
---@param quad love.Quad?
function text.defineImage(name, tex, quad)
    assertNameValid(name)
    return richtext.registerImage(name, tex, quad)
end



local strTc = typecheck.assert("string")

-- Make sure both values are same. 100 is default cache size.
local parsedCache = lru.new(100, 100)
local parsedLayout = lru.new(1000, 1000) -- key = ParsedText + maxwidth + font + align


---Parse rich text to a table of text and effects.
---Note that this only parses the rich text and does not applies effect.
---@param txt string Formatted rich text
---@return richtext.ParsedText
function text.parseRichText(txt)
    strTc(txt)
    local parsedData = parsedCache:get(txt) --[[@as richtext.ParsedText?]]
    if not parsedData then
        parsedData = assert(richtext.parse(txt))
        parsedCache:set(txt, parsedData, 1)
    end
    return parsedData
end



---@param txt string|richtext.ParsedText
local function ensureParsed(txt)
    if type(txt) == "string" then
        return text.parseRichText(txt)
    end
    return txt
end

---@param parsed richtext.ParsedText
---@param font love.Font
---@param maxwidth number?
---@param align love.AlignMode?
local function textGetLayout(parsed, font, maxwidth, align)
    local key = parsed.origin.."\0"..tostring(maxwidth)..tostring(font)..tostring(align or "left")
    local layout = parsedLayout:get(key) --[[@as richtext.TextLayout?]]
    if not layout then
        ---@diagnostic disable-next-line: param-type-mismatch
        layout = parsed:layout(font, maxwidth, align)
        parsedLayout:set(key, layout, 1)
    end
    return layout
end

---@param txt richtext.ParsedText|string Formatted rich text string or parsed rich text data.
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
---@overload fun(txt:richtext.ParsedText|string, font:love.Font, x:love.Transform, limit: number, align: love.AlignMode?)
function text.printRich(txt, font, x, y, limit, align, rot, sx, sy, ox, oy, kx, ky)
    prof_push("drawRichText")

    if typecheck.isType(x, "love:Transform") then
        align = limit
        limit = y
        y, rot = nil, nil
        sx, sy = nil, nil
        ox, oy = nil, nil
        kx, ky = nil, nil
    end

    local parsed = ensureParsed(txt)
    local layout = textGetLayout(parsed, font, limit, align)

    love.graphics.push()
    love.graphics.applyTransform(x, y, rot, sx, sy, ox, oy, kx, ky)
    layout:draw(0, 0)
    love.graphics.pop()

    prof_pop()
end

---@param txt richtext.ParsedText|string
---@param font love.Font
---@return number
function text.getWidth(txt, font)
    local parsed = ensureParsed(txt)
    local layout = textGetLayout(parsed, font)
    return layout:getWidth()
end

---@param txt richtext.ParsedText|string
---@param font love.Font
---@param maxwidth number
function text.getWrap(txt, font, maxwidth)
    local parsed = ensureParsed(txt)
    local layout = textGetLayout(parsed, font, maxwidth)
    return layout:getWrap()
end


---@param txt richtext.ParsedText|string
---@param font love.Font
---@param x number
---@param y number
---@param limit number
---@param align love.AlignMode (justify is not supported)
---@param rot number?
---@param sx number?
---@param sy number?
function text.printRichCentered(txt, font, x, y, limit, align, rot, sx, sy)
    local parsed = ensureParsed(txt)
    local width, wrap = text.getWrap(parsed, font, limit)

    local ox = width / 2
    local oy = wrap * font:getHeight() / 2
    return text.printRich(parsed, font, x, y, limit, align, rot, sx, sy, ox, oy)
end

---Prints rich text contained inside a x,y,w,h box
---@param txt string richtext
---@param font love.Font
---@param x number
---@param y number
---@param w number
---@param h number
function text.printRichContained(txt, font, x,y,w,h)
    local parsed = ensureParsed(txt)
    local tw, lines = text.getWrap(parsed, font, w)
    local th = lines * font:getHeight()

    local scale = math.min(w/tw, h/th)
    local drawX, drawY = math.floor(x+w/2), math.floor(y+h/2)

    return text.printRich(parsed, font, drawX, drawY, tw, "left", 0, scale, scale, tw / 2, th / 2)
end



---Prints rich text contained inside a x,y,w,h box, no wrapping
---@param txt string richtext
---@param font love.Font
---@param x number
---@param y number
---@param w number
---@param h number
function text.printRichContainedNoWrap(txt, font, x,y,w,h)
    local parsed = ensureParsed(txt)
    local tw = text.getWidth(parsed, font)
    local th = font:getHeight()

    local limit = w
    local scale = math.min(limit/tw, h/th)
    local drawX, drawY = math.floor(x+w/2), math.floor(y+h/2)

    -- HACK: 
    -- Without the +0.0001, text wraps when it shouldnt
    return text.printRich(parsed, font, drawX, drawY, limit/scale+0.0001, "left", 0, scale, scale, tw / 2, th / 2)
end



require(".default_effects")(text) -- Expose default effects

return text
