


---@class g.CustomSelect: objects.Class
local CustomSelect = objects.Class("g:CustomSelect")


if false then
    ---@param items table
    ---@param onDraw fun(item, reg)
    ---@return g.CustomSelect
    function CustomSelect(items, onDraw) end ---@diagnostic disable-line: cast-local-type, missing-return
end



---@param items table
---@param onDraw fun(item, reg)
function CustomSelect:init(items, onDraw)
    self.items = items
    self.i = 1
    self.onDraw=onDraw
end


---@param items any[]
function CustomSelect:setItems(items)
    local selected = self:getSelected()
    self.items = items

    -- Update indices to new item indices
    for i, item in ipairs(items) do
        if item == selected then
            self:setSelectionIndex(i)
            break
        end
    end
    -- If there's no match, ensure index is clamped
    self:setSelectionIndex(self.i)
end


---Draws an arrow within a bounding box
---@param direction number -1 for left, 1 for right
---@param x number Top-left x
---@param y number Top-left y
---@param w number Width of the bounding box
---@param h number Height of the bounding box
local function drawArrow(direction, x, y, w, h)
    local r = Kirigami(x,y,w,h):padRatio(0.1)

    local color = objects.Color.WHITE
    if iml.isHovered(x,y,w,h) then
        color=objects.Color.GRAY
    end
    lg.setColor(color)

    if iml.wasJustHovered(x,y,w,h) then
		g.playUISound("ui_tick", 1.6,0.35, 0,0)
    end

    if direction == 1 then
        g.drawImageContained("button_right", x,y,w,h)
        --g.drawImage("button_right", x+w/2,y+h/2)
    else
        g.drawImageContained("button_left", x,y,w,h)
        --g.drawImage("button_left", x+w/2,y+h/2)
    end

    local pressed = iml.wasJustPressed(x,y,w,h)
    if pressed then
		g.playUISound("ui_click_basic", 1.4,0.8)
    end
    return pressed
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


local COL1 = objects.Color.DARK_BLUE
local COL2 = objects.Color("#".."FF530667")

---@param i integer
function CustomSelect:setSelectionIndex(i)
    self.i = helper.clamp(i, 1, #self.items)
end

---@param reg kirigami.Region
function CustomSelect:draw(reg)
    lg.setColor(1,1,1)
    local left,a0,a,b,c,d,e,e0,right = reg:splitHorizontal(1,1,1,1,1.5,1,1,1,1)
    local len = #self.items

    local PD=0.3
    local panelR = reg:padRatio(PD,0,PD,0)
    ui.drawPanel(panelR:get())
    helper.gradientRect("horizontal", COL1,COL2, panelR:padUnit(4):get())

    self.i = helper.clamp(self.i, 1,len)

    self:drawItem(self.i-3, a0:padRatio(0.4))
    self:drawItem(self.i+3, e0:padRatio(0.4))
    self:drawItem(self.i-2, a:padRatio(0.3))
    self:drawItem(self.i+2, e:padRatio(0.3))
    self:drawItem(self.i-1, b:padRatio(0.2))
    self:drawItem(self.i+1, d:padRatio(0.2))
    c = c:padUnit(-4, -1)
    ui.drawPanel(c:get())
    --helper.gradientRect("horizontal", COL2,COL1, c:padUnit(4):get())
    self:drawItem(self.i, c:padRatio(0.2))

    if drawArrow(-1, left:moveRatio(0.3,0):get()) then
        self:setSelectionIndex(self.i - 1)
    end

    if drawArrow(1, right:moveRatio(-0.3,0):get()) then
        self:setSelectionIndex(self.i + 1)
    end
end



return CustomSelect


