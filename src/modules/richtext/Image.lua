
---@class richtext.Image: objects.Class
local Image = objects.Class("text:Image")


---@param start integer
---@param font love.Font
---@param image love.Texture
---@param quad love.Quad?
---@param extraScale number?
function Image:init(start, font, image, quad, extraScale)
    self.image = image
    self.quad = quad
    self.start = start

    self.font = font

    local w,h
    if quad then
        _,_,w,h = self.quad:getViewport()
    else
        w,h = self.image:getDimensions()
    end
    assert(w == h, "All images must be square")

    local fontH = font:getHeight()
    local sc = (fontH / h)
    self.scale = sc * (extraScale or 1)
    self.w, self.h = w,h
end


---Reset the changes from previous effects.
function Image:reset()
    --[[
    TODO:
    do we want to have all these properties here?
    ]]
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


---Return the amount of horizontal-space the image takes
---@return integer length Length of the Image(s).
function Image:getLength()
    return self.w
end


---Get the index of the current Image(s) relative to the parent Text object.
---@return integer index Index of the starting string relative to the parent Text object.
function Image:getIndex()
    return self.start
end

---Retrieve the text color.
---@return objects.Color
function Image:getColor()
    return self.color
end

---@param r number
---@param g number
---@param b number
---@param a number
---@diagnostic disable-next-line: duplicate-set-field
function Image:setColor(r, g, b, a) end

---@param hex string|integer
---@diagnostic disable-next-line: duplicate-set-field
function Image:setColor(hex) end

---@param color objects.Color
---@diagnostic disable-next-line: duplicate-set-field
function Image:setColor(color) end

---@param color number[]
---@diagnostic disable-next-line: duplicate-set-field
function Image:setColor(color) end

---@diagnostic disable-next-line: duplicate-set-field
function Image:setColor(...)
    if objects.Color.isColor(select(1, ...)) then
        self.color = select(1, ...)
    else
        self.color = objects.Color(...)
    end
end

---Get the image position.
---@return number,number @The image offset position.
function Image:getPosition()
    return self.x, self.y
end

---Set the image position.
---@param x number X position of the image.
---@param y number Y position of the image.
function Image:setPosition(x, y)
    self.x, self.y = x, y
end

function Image:getOffset()
    return self.ox, self.oy
end

---Get the text offset.
---@param ox number X offset of the image.
---@param oy number Y offset of the image.
function Image:setOffset(ox, oy)
    self.ox, self.oy = ox, oy
end

---Get the text dimensions (width and height).
---@return number,number
function Image:getDimensions()
    return self.w, self.h
end

---@return number
function Image:getRotation()
    return self.r
end

---@param r number
function Image:setRotation(r)
    self.r = r
end

function Image:getScale()
    return self.sx, self.sy
end

---@param sx number
---@param sy number
function Image:setScale(sx, sy)
    self.sx, self.sy = sx, sy
end

function Image:getShear()
    return self.kx, self.ky
end

---@param kx number
---@param ky number
function Image:setShear(kx, ky)
    self.kx, self.ky = kx, ky
end


function Image:draw()
    love.graphics.draw(
        self.image,
        self.quad,
        self.x, self.y, self.r,
        self.sx, self.sy,
        self.ox, self.oy,
        self.kx, self.ky
    )
end

if false then
    ---@return richtext.Image
    ---@nodiscard
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Image(font, char, start) end
end

return Image
