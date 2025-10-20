local objects = require("src.modules.objects.objects")
local Resources = require(".ResourcesHUD")
local Profile = require(".ProfileHUD")

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.resourceHUD = Resources()
    self.profileHUD = Profile()
    self.freeArea = Kirigami(0, 0, ui.getScaledUIDimensions())
end

if false then
    ---@return g.HUD
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function HUD() end
end

---@param dt number
function HUD:update(dt)
    self.resourceHUD:update(dt)
    self.profileHUD:update(dt)
end

---@param camera Camera
---@param show {resource:boolean?,profile:boolean?}?
function HUD:draw(camera, show)
    show = show or {}
    self.resourceHUD:draw(camera, show.resource == false)
    self.profileHUD:draw(camera, show.profile == false)
end

---@param kind g.ResourceType
---@param x number Position of the token in world-space.
---@param y number Position of the token in world-space.
---@param amount number Amount to add to the display once it's done.
function HUD:spawnResourceParticle(kind, x, y, amount)
    return self.resourceHUD:spawnParticle(kind, x, y, amount)
end

function HUD:getSafeArea()
    return Kirigami(0, 0, ui.getScaledUIDimensions())
        :intersection(self.resourceHUD:getSafeArea())
        :intersection(self.profileHUD:getSafeArea())
end

return HUD
