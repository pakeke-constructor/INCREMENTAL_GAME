local objects = require("src.modules.objects.objects")
local Resources = require("src.ui.hud.ResourcesHUD")

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.resourceHUD = Resources()
    self.freeArea = Kirigami(0, 0, ui.getScaledUIDimensions())
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
---@param show {resource:boolean?,profile:boolean?}?
function HUD:draw(camera, show)
    show = show or {}
    local r = Kirigami(0,0,ui.getScaledUIDimensions())
    local leftR = r:splitHorizontal(1, 1, 1, 1, 1)
    local profileR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(r):moveRatio(0, -1):padRatio(0.05)
    local hideResource = show.resource == false
    local hideProfile = show.profile == false

    if not hideProfile then
        -- Draw dummy profile picture
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", profileR:get())
        local x,y,w,h = profileR:get()
        love.graphics.setColor(1,1,1)
        local SCALE=4
        g.drawImage("happy_cat",x+w/2,y+h/2, 0, -SCALE,SCALE)
        love.graphics.setColor(1, 0, 0)
        local lw = love.graphics.getLineWidth()
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", profileR:get())
        love.graphics.setLineWidth(lw)
    end

    self.resourceHUD:draw(camera, hideResource)
    self.freeArea = r:padUnit(profileR.x + profileR.w, 0, 0, 0)
end

---@param kind g.ResourceType
---@param x number Position of the token in world-space.
---@param y number Position of the token in world-space.
---@param amount number Amount to add to the display once it's done.
function HUD:spawnResourceParticle(kind, x, y, amount)
    return self.resourceHUD:spawnParticle(kind, x, y, amount)
end

function HUD:getSafeArea()
    return self.freeArea:intersection(self.resourceHUD:getSafeArea())
end

return HUD
