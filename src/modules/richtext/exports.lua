---Availability: **Client**
---@class text
local text = {}

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
    defaultEffectGroup.effectList[name] = effectupdate
end


--- Define a new effect for rich text formatting 
---@generic T
---@param name string Effect name.
---@param tex love.Texture
---@param quad love.Quad?
function text.defineImage(name, tex, quad)
    assertNameValid(name)
    defaultEffectGroup:defineImage(name, tex, quad)
end



local strTc = typecheck.assert("string")


---Duplicate the default effect group, inheriting all the added effects in the default effect group to new independent
---effect group.
---@return text.EffectGroup effectgroup The new effect group.
function text.cloneDefaultEffectGroup()
    return defaultEffectGroup:clone()
end

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

local drawRichText = require(".draw_rich_text")
text.printRich = drawRichText.draw
text.getWidth = drawRichText.getWidth
text.getWrap = drawRichText.getWrap

---Clear tags on rich text.
---@param txt text.ParsedText|string
---@deprecated use `richtext.getWidth` or `richtext.getWrap` instead!
function text.stripEffects(txt)
    local parsed = assert(parser.ensure(txt))
    return drawRichText.strip(parsed)
end

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
    local width, wrap = text.getWrap(txt, font, limit)

    local ox = width / 2
    local oy = wrap * font:getHeight() / 2
    return drawRichText.draw(parsed, font, x, y, limit, align, rot, sx, sy, ox, oy)
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
    local strippedTxt = text.stripEffects(parsed)

    local tw, th = getTextSize(font, assert(strippedTxt))

    local scale = math.min(w/tw, h/th)
    local drawX, drawY = math.floor(x+w/2), math.floor(y+h/2)

    drawRichText.draw(parsed, font, drawX, drawY, tw, "left", 0, scale, scale, tw / 2, th / 2)
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
    local stripped = drawRichText.strip(parsed)
    local tw = font:getWidth(stripped)
    --local tw = text.getWidth(parsed, font)
    local th = font:getHeight()

    local limit = w
    local scale = math.min(limit/tw, h/th)
    local drawX, drawY = math.floor(x+w/2), math.floor(y+h/2)

    -- HACK: 
    -- Without the +0.0001, text wraps when it shouldnt
    drawRichText.draw(parsed, font, drawX, drawY, limit/scale+0.0001, "left", 0, scale, scale, tw / 2, th / 2)

    -- (old code ==>) drawRichText.draw(parsed, font, drawX, drawY, limit/scale, "left", 0, scale, scale, tw / 2, th / 2)
end




require(".default_effects")(text) -- Expose default effects

return text
