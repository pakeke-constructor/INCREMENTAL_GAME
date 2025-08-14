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




--[[

Define default effects:

]]


local function wavyEffect(args, char)
    local f = args.freq or 1
    local amp = args.amp or 1
    local k = args.k or 1 -- `k` determines how "different" the letter are.
    -- k = 0 indicates all letters bob up and down, in sync.
    local offset = (char:getIndex()-1) * k
    local dy = math.sin(2 * math.pi * f * love.timer.getTime() + offset) * amp
    char:setOffset(0, dy)
end

text.defineEffect("wavy", wavyEffect)
text.defineEffect("w", wavyEffect)



text.defineEffect("u", function(_, char)
    local r, g, b, a = love.graphics.getColor()
    local c1, c2, c3, c4 = char:getColor():getRGBA()
    local x, y = char:getPosition()
    local w, h = char:getDimensions()
    love.graphics.setColor(r * c1, g * c2, b * c3, a * c4)
    love.graphics.line(x, y + h - 0.5, x + w, y + h - 0.5)
    love.graphics.setColor(r, g, b, a)
end)




local function outlineEffect(args,char)
    local thickness = args.thickness or 1
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(0, 0, 0, a)

    local ox, oy = char:getOffset()

    -- Draw outline
    for i = 0, 8 do
        if i ~= 4 then -- Don't draw the center
            local ooy = (math.floor(i / 3) - 1) * thickness
            local oox = (i % 3 - 1) * thickness
            char:setOffset(ox + oox, oy + ooy)
            char:draw(0, 0, 0, a, true)
        end
    end
    char:setOffset(ox, oy)

    love.graphics.setColor(r, g, b, a)
end

text.defineEffect("o", outlineEffect)
text.defineEffect("outline", outlineEffect)



local function colorEffect(args, char)
    local color = objects.Color(args.r or 1, args.g or 1, args.b or 1, args.a or 1)
    char:setColor(color)
end
text.defineEffect("color", colorEffect)
text.defineEffect("c", colorEffect)

text.defineEffect("i", function(args, char)
    local skewness = args.skew or 1
    char:setShear(-skewness / 4, 0)
end)


require(".default_effects")(text) -- Expose default effects

return text
