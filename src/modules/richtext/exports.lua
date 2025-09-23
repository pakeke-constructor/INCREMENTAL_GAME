---Availability: **Client**
---@class text
local text = {}
if false then
    _G.text = text
end

text.EffectGroup = require(".EffectGroup")
text.RichText = require(".Text")

---@class text.TextArgs
---@field public variables? table<string, any> Variable store to use (defaults to _G).
---@field public effectGroup? text.EffectGroup Effect group to use (defaults to default effect group).

local defaultEffectGroup = require(".defaultEffectGroup")

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
---@param effectupdate fun(context:T,characters:text.Character) Function that apply the effect to subtext.
function text.defineEffect(name, effectupdate)
    assertNameValid(name)
    return defaultEffectGroup:addEffect(name, effectupdate)
end

local strTc = typecheck.assert("string")

---Remove the effect from the default effect group.
---@param name string Effect name.
function text.removeEffect(name)
    strTc(name)
    return defaultEffectGroup:removeEffect(name)
end

---Duplicate the default effect group, inheriting all the added effects in the default effect group to new independent
---effect group.
---@return text.EffectGroup effectgroup The new effect group.
function text.cloneDefaultEffectGroup()
    return defaultEffectGroup:clone()
end

---@module "client.parser"
local parser = require(".parser")

---Parse rich text to a table of text and effects.
---Note that this only parses the rich text and does not applies effect.
---@param txt string Formatted rich text
---@return text.ParsedText?,string?
function text.parseRichText(txt)
    strTc(txt)
    return parser.ensure(txt)
end

text.parsedToString = parser.tostring
text.escapeRichTextSyntax = parser.escape

---Clear tags on rich text.
---@param txt text.ParsedText|string
---@return string
function text.stripEffects(txt)
    strTc(txt)
    local parsed = assert(parser.ensure(txt))
    local result = {}

    for _, data in ipairs(parsed) do
        if type(data) == "string" then
            result[#result+1] = data
        end
    end

    return table.concat(result)
end

local drawRichText = require(".draw_rich_text")
text.printRich = drawRichText

---@param txt text.ParsedText|string
---@param font love.Font
---@param x number
---@param y number
---@param limit number
---@param align love.AlignMode (justify is not supported)
---@param rot number?
---@param sx number?
---@param sy number?
function text.printRichCentered(txt, font, x, y, limit, align, rot, sx, sy)
    strTc(txt)
    local parsed = assert(parser.ensure(txt))
    local clear = text.stripEffects(txt)
    local width, wrap = font:getWrap(clear, limit)

    local ox = width / 2
    local oy = #wrap * font:getHeight() / 2
    return drawRichText(parsed, font, x, y, limit, align, rot, sx, sy, ox, oy)
end


---@param font love.Font
---@param txt string
---@param wrap number?
---@return number,number
local function getTextSize(font, txt, wrap)
    local width, lines = font:getWrap(txt, wrap or 2147483647)
    return width, #lines * font:getHeight()
end


---Prints rich text contained inside a x,y,w,h box
---@param txt string richtext
---@param font love.Font
---@param x number
---@param y number
---@param w number
---@param h number
function text.printRichContained(txt, font, x,y,w,h)
    strTc(txt)
    local parsed = assert(parser.ensure(txt))
    local strippedTxt = text.stripEffects(txt)

    local tw, th = getTextSize(font, assert(strippedTxt), w)

    local limit = w
    local scale = math.min(limit/tw, h/th)
    local drawX, drawY = math.floor(x+w/2), math.floor(y+h/2)

    drawRichText(parsed, font, drawX, drawY, limit, "left", 0, scale, scale, tw / 2, th / 2)
end



---Prints rich text contained inside a x,y,w,h box, no wrapping
---@param txt string richtext
---@param font love.Font
---@param x number
---@param y number
---@param w number
---@param h number
function text.printRichContainedNoWrap(txt, font, x,y,w,h)
    strTc(txt)
    local parsed = assert(parser.ensure(txt))
    local strippedTxt = text.stripEffects(txt)

    local tw, th = font:getWidth(strippedTxt), font:getHeight()

    local limit = w
    local scale = math.min(limit/tw, h/th)
    local drawX, drawY = math.floor(x+w/2), math.floor(y+h/2)

    drawRichText(parsed, font, drawX, drawY, limit/scale, "left", 0, scale, scale, tw / 2, th / 2)
end




require(".default_effects")(text) -- Expose default effects

return text
