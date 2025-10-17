---@class g.FisherCat: objects.Class
---@field public image string (Read-only)
---@field public x number
---@field public y number
---@field public animationState "idle"|"throwing"|"fishing"|"reeling"|"pull" (Read-only)
local FisherCat = objects.Class("g:FisherCat")

---@param x number
---@param y number
---@param image string?
function FisherCat:init(x, y, image)
    self.x = x
    self.y = y
    self.image = image or "happy_cat"
    self.animationState = "idle"
end

if false then
    ---@param x number
    ---@param y number
    ---@param image string?
    ---@return g.FisherCat
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function FisherCat(x, y, image) end
end

---@param dt number
function FisherCat:update(dt)
end

function FisherCat:draw()
    -- TODO: Draw other fishing-related elements
    g.drawImage(self.image, self.x, self.y)
end


function FisherCat:cast()
end


function FisherCat:reset()
end


return FisherCat
