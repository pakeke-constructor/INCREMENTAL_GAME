local objects = require("src.modules.objects.objects")
local Resources = require(".ResourcesHUD")
local Profile = require(".ProfileHUD")


local SIDEBAR_COLOR = objects.Color("#".."FF14A0CD")
local SIDEBAR_STRIP = objects.Color("#".."FFFF8CC8")
-- TODO: Make this auto-computable?
local SIDEBAR_WIDTH = 86



---@class g.HUD: objects.Class
---@field resourceHUD g.hud.Resources
---@field profileHUD g.hud.Profile
---@field freeArea kirigami.Region
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.sidebar = Kirigami(0, 0, 1, 1)
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
    local _, h = ui.getScaledUIDimensions()
    self.sidebar = self.sidebar:set(0, 0, SIDEBAR_WIDTH, h)
    self.resourceHUD:update(dt)
    self.profileHUD:update(dt)
end



---@param show {resource:boolean?,profile:boolean?,xpbar:boolean?}?
function HUD:draw(show)
    show = show or {}

    -- Draw sidebar
    love.graphics.setColor(SIDEBAR_COLOR)
    love.graphics.rectangle("fill", self.sidebar:get())
    love.graphics.setColor(SIDEBAR_STRIP)
    love.graphics.rectangle("fill", self.sidebar.x + self.sidebar.w, 0, 2, self.sidebar.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", self.sidebar.x + self.sidebar.w + 2, 0, 2, self.sidebar.h)

    -- Draw other HUDs
    self.resourceHUD:draw(show.resource == false)
    self.profileHUD:draw(SIDEBAR_WIDTH, show.profile == false, show.xpbar)
end

function HUD:getSafeArea()
    local w, h = ui.getScaledUIDimensions()
    local x2 = self.sidebar.x + self.sidebar.w
    return Kirigami(x2, 0, w - x2, h)
        :intersection(self.profileHUD:getSafeArea())
end

return HUD
