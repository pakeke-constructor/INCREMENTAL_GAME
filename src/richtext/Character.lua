---@class text.Character: objects.Class
local Character = objects.Class("text:Character")

---@param font love.Font
---@param char string
---@param start integer
function Character:init(font, char, start)
    self.font = font
    self.char = char
    self.start = start
    self.length = utf8.len(char)
    self.width = font:getWidth(char)
    self.height = font:getHeight()
    self:reset()
end

---Reset the subtext changes from previous effects.
function Character:reset()
    self.color = objects.Color.WHITE
    self.x = 0
    self.y = 0
    self.ox = 0
    self.oy = 0
    self.x = 0
    self.y = 0
    self.r = 0
    self.sx = 1
    self.sy = 1
    self.kx = 0
    self.ky = 0
end

---Return the character(s) in this subtext.
---@return string char The character(s) in this subtext.
function Character:getChar()
    return self.char
end

---Return the length of character(s) in this subtext.
---
---The returned length is Unicode-aware, which may not same as `#Character:getChar()`.
---@return integer length Length of the character(s).
function Character:getLength()
    return self.length
end

---Get the index of the current character(s) relative to the parent Text object.
---@return integer index Index of the starting string relative to the parent Text object.
function Character:getIndex()
    return self.start
end

---Retrieve the text color.
---@return objects.Color
function Character:getColor()
    return self.color
end

---@param r number
---@param g number
---@param b number
---@param a number
---@diagnostic disable-next-line: duplicate-set-field
function Character:setColor(r, g, b, a) end

---@param hex string|integer
---@diagnostic disable-next-line: duplicate-set-field
function Character:setColor(hex) end

---@param color objects.Color
---@diagnostic disable-next-line: duplicate-set-field
function Character:setColor(color) end

---@param color number[]
---@diagnostic disable-next-line: duplicate-set-field
function Character:setColor(color) end

---@diagnostic disable-next-line: duplicate-set-field
function Character:setColor(...)
    if objects.Color.isColor(select(1, ...)) then
        self.color = select(1, ...)
    else
        self.color = objects.Color(...)
    end
end

---Get the text position.
---@return number,number @The text offset position.
function Character:getPosition()
    return self.x, self.y
end

---Set the text position.
---@param x number X position of the text.
---@param y number Y position of the text.
function Character:setPosition(x, y)
    self.x, self.y = x, y
end

function Character:getOffset()
    return self.ox, self.oy
end

---Get the text offset.
---@param ox number X offset of the text.
---@param oy number Y offset of the text.
function Character:setOffset(ox, oy)
    self.ox, self.oy = ox, oy
end

---Get the text dimensions (width and height).
function Character:getDimensions()
    return self.width, self.height
end

---@return number
function Character:getRotation()
    return self.r
end

---@param r number
function Character:setRotation(r)
    self.r = r
end

function Character:getScale()
    return self.sx, self.sy
end

---@param sx number
---@param sy number
function Character:setScale(sx, sy)
    self.sx, self.sy = sx, sy
end

function Character:getShear()
    return self.kx, self.ky
end

---@param kx number
---@param ky number
function Character:setShear(kx, ky)
    self.kx, self.ky = kx, ky
end

function Character:getFont()
    return self.font
end

---Changes the font used for rendering.
---
---Caveat: Spacing calculation and kerning uses the Text font.
---@param font love.Font
function Character:setFont(font)
    self.font = font
    self.width = font:getWidth(self.char)
    self.height = font:getHeight()
end

---Draw the character with specified color.
---
---The color will be multiplied with the assigned character color. If in doubt, just pass 1 for all.
---@param r number
---@param g number
---@param b number
---@param a number
---@param overridecolor boolean? Should the specified color override the character color?
function Character:draw(r, g, b, a, overridecolor)
    if overridecolor then
        love.graphics.setColor(r, g, b, a)
    else
        local c1, c2, c3, c4 = self:getColor():getRGBA()
        love.graphics.setColor(r * c1, g * c2, b * c3, a * c4)
    end
    love.graphics.print(
        self.char,
        self.font,
        self.x, self.y, self.r,
        self.sx, self.sy,
        self.ox, self.oy,
        self.kx, self.ky
    )
end

if false then
    ---@param font love.Font
    ---@param char string
    ---@param start integer
    ---@return text.Character
    ---@nodiscard
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Character(font, char, start) end
end

return Character
