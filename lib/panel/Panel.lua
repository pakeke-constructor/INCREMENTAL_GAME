
---@class Panel
---@field children Panel[]
---@field isClicked boolean
---@field clickTime number
local Panel = {}
local Panel_mt = {__index = Panel}


local THRESHOLD = 1


---@return Panel
local function newPanel()
    return setmetatable({
        x=0,y=0, w=0,h=0,
        children = {},
        isClicked = false,
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
    if #self.children > 0 then
        -- Has children, propagate to children
        for _, p in ipairs(self.children) do
            if isContained(p, x,y) then
                p:mousepressed(m, x, y)
                return -- Only the first matching child gets the event
            end
        end
    else
        -- No children, handle press on self
        if isContained(self, x, y) then
            self.isClicked = true
            self.clickTime = love.timer.getTime()
        end
    end
end


---@param self Panel
local function timeSinceClick(self)
    local t = love.timer.getTime()
    return (t - (self.clickTime or 0))
end


function Panel:mousereleased(m, x, y)
    if #self.children > 0 then
        -- Has children, propagate to children
        for _, p in ipairs(self.children) do
            p:mousereleased(m, x, y)
        end
    else
        -- No children, handle release on self
        if self.isClicked and isContained(self, x, y) then
            if self.onClicked and (timeSinceClick(self) < THRESHOLD) then
                self:onClicked(m, x, y)
            end
        end
        self.isClicked = false
        self.clickTime = -100
    end
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

    self:onDraw(x,y,w,h)
end




return newPanel
