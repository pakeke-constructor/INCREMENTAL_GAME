local objects = require("src.modules.objects.objects")
local Resources = require("src.ui.hud.resource")

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.resourceHUD = Resources()
end

if false then
    ---@return g.HUD
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function HUD() end
end

---@param dt number
function HUD:update(dt)
    return self.resourceHUD:update(dt)
end

---@param camera Camera
function HUD:draw(camera)
    local r = Kirigami(0,0,ui.getScaledUIDimensions())
    local leftR = r:splitHorizontal(1, 1, 1, 1, 1)
    local profileR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(r):moveRatio(0, -1):padRatio(0.05)

    -- Draw dummy profile picture
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", profileR:get())
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("line", profileR:get())

    return self:drawResourceHUD(camera)
end

---@param camera Camera
function HUD:drawResourceHUD(camera)
    return self.resourceHUD:draw(camera)
end

---@param kind g.ResourceType
---@param x number Position of the token in world-space.
---@param y number Position of the token in world-space.
---@param amount number Amount to add to the display once it's done.
function HUD:spawnResourceParticle(kind, x, y, amount)
    return self.resourceHUD:spawnParticle(kind, x, y, amount)
end

return HUD
