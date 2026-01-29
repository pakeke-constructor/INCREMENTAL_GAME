


---@class g.CustomSelect: objects.Class
local CustomSelect = objects.Class("g:CustomSelect")


---@param items table
---@param onDraw fun(item, reg)
function CustomSelect:init(items, onDraw)
    self.items = items
    self.i = 1
    self.onDraw=onDraw
end


function CustomSelect:setItems(items)
    self.items = items
end


---Draws an arrow within a bounding box
---@param direction number -1 for left, 1 for right
---@param x number Top-left x
---@param y number Top-left y
---@param w number Width of the bounding box
---@param h number Height of the bounding box
local function drawArrow(direction, x, y, w, h)
    local tipX, baseX
    local color = objects.Color.WHITE
    if iml.isHovered(x,y,w,h) then
        color=objects.Color.GRAY
    end
    lg.setColor(color)

    if direction == 1 then
        -- Pointing Right: Tip is at the right edge, base is at the left
        tipX = x + w
        baseX = x
    else
        -- Pointing Left: Tip is at the left edge, base is at the right
        tipX = x
        baseX = x + w
    end
    love.graphics.polygon('fill',
        tipX,  y + h / 2,  -- The Tip (centered vertically)
        baseX, y,          -- Top corner of the base
        baseX, y + h       -- Bottom corner of the base
    )

    return iml.wasJustPressed(x,y,w,h)
end


function CustomSelect:getSelected()
    return self.items[self.i]
end


---@param reg kirigami.Region
function CustomSelect:drawItem(i, reg)
    if i > #self.items then return end
    if i < 1 then return end

    self.onDraw(self.items[i], reg)
end


---@param reg kirigami.Region
function CustomSelect:draw(reg)
    local left,a,b,c,d,e,right = reg:splitHorizontal(1,1,1,1.5,1,1,1)
    local len = #self.items

    self.i = helper.clamp(self.i, 1,len)

    self:drawItem(self.i-2, a)
    self:drawItem(self.i+2, e)
    self:drawItem(self.i-1, b)
    self:drawItem(self.i+1, d)
    self:drawItem(self.i, c)

    if drawArrow(-1, left:get()) then
        self.i = helper.clamp(self.i - 1, 1,len)
    end

    if drawArrow(1, right:get()) then
        self.i = helper.clamp(self.i + 1, 1,len)
    end
end



return CustomSelect


