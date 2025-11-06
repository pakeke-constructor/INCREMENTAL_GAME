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

---@param show {resource:boolean?,profile:boolean?}?
function HUD:draw(show)
    show = show or {}
    self.resourceHUD:draw(show.resource == false)
    self.profileHUD:draw(show.profile == false)
end

function HUD:getSafeArea()
    return Kirigami(0, 0, ui.getScaledUIDimensions())
        :intersection(self.resourceHUD:getSafeArea())
        :intersection(self.profileHUD:getSafeArea())
end

return HUD
