


---@class Panel
---@field children Panel[]
---@field clickedChild Panel
---@field clickTime number
local Panel = {}
local Panel_mt = {__index = Panel}


local THRESHOLD = 1


---@return Panel
local function newPanel()
    return setmetatable({
        x=0,y=0, w=0,h=0,
        children = {},
        clickedChild = nil,
        clickTime = -100, -- when was the press 
    }, Panel_mt)
end



function Panel:addChild(p)
    table.insert(self.children, p)
end


local function isContained(p, x,y)
    return x >= p.x and x <= p.x + p.w and y >= p.y and y <= p.y + p.h
end



---@param x number
---@param y number
---@param dx number
---@param dy number
function Panel:onDragged(x,y,dx,dy)
    -- override me.
end


---@param m number
---@param x number
---@param y number
function Panel:onClicked(m,x,y)
    -- override me.
end


function Panel:onDraw()
    -- override me.
end





function Panel:mousepressed(m, x, y)
    for _, p in ipairs(self.children) do
        if isContained(p, x,y) then
            self.clickedChild = p
            self.clickTime = love.timer.getTime()
            break
        end
    end
end


---@param self Panel
local function timeSinceClick(self)
    local t = love.timer.getTime()
    return (t - (self.clickTime or 0))
end


function Panel:mousereleased(m, x, y)
    local p = self.clickedChild
    if p and isContained(p, x,y) then
        if p.onClicked and (timeSinceClick(self) < THRESHOLD) then
            p:onClicked(m, x,y)
        end
    end
    self.clickedChild = nil
    self.clickTime = -100
end



---@param x number
---@param y number
---@param dx number
---@param dy number
function Panel:mousemoved(x,y, dx,dy)
    if timeSinceClick(self) > THRESHOLD then
        -- its a drag!
        self:onDragged(x,y, dx,dy)
    end
end



---@param x number
---@param y number
---@param w number
---@param h number
function Panel:draw(x,y, w,h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h

    self:onDraw()
end




return newPanel

