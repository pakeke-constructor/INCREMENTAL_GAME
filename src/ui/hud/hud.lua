local objects = require("src.modules.objects.objects")
local Resources = require(".ResourcesHUD")
local Profile = require(".ProfileHUD")


local SIDEBAR_COLOR = objects.Color("#".."FF14A0CD")
local SIDEBAR_STRIP = objects.Color("#".."FFFF8CC8")
-- TODO: Make this auto-computable?
local SIDEBAR_WIDTH = 86
local REWARD_CELL_SIZE = 24

local DESC_BACKGROUND_GRADIENT = helper.newGradientMesh(
    "horizontal",
    objects.Color("#".."FF14465A"),
    objects.Color("#".."ff191e3c")
)
local DESC_TEXT_MAX_WIDTH = 200


---@class g.HUD: objects.Class
---@field resourceHUD g.hud.Resources
---@field profileHUD g.hud.Profile
---@field freeArea kirigami.Region
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.sidebarR = Kirigami(0, 0, 1, 1)
    self.xpBarR = Kirigami(0, 0, 0, 0)
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
    self.sidebarR = self.sidebarR:set(0, 0, SIDEBAR_WIDTH, h)
    self.resourceHUD:update(dt)
    self.profileHUD:update(dt)
end


local XP_BAR_GRADIENT = {
    objects.Color("#".."FF41D7D7"),
    objects.Color("#".."FFFF8CC8"),
}

---@param xpBarBaseR kirigami.Region
local function drawExperienceBar(xpBarBaseR)
    local sn = g.getSn()

    -- Draw XP bar background
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", xpBarBaseR:get())

    -- Draw XP bar
    -- Fancier and efficient way to do this is to use helper.newGradientMesh + stencil for rounded rectangle
    -- but this does the job for now.
    local targXP = helper.clamp(sn.xp/sn.xpRequirement, 0, 1)
    local targColor = XP_BAR_GRADIENT[1]:lerp(XP_BAR_GRADIENT[2], targXP) -- FIXME: Do interpolation in Oklab?
    local xpBarR = xpBarBaseR:padUnit(2)
    xpBarR = xpBarR:set(nil, nil, xpBarR.w * targXP)
    if sn.xp >= sn.xpRequirement then
        -- Draw rainbow effect
        local t = love.timer.getTime()
        local r,g,b = objects.Color.HSVtoRGB((t * 90) % 360, 1, 1)
        lg.setColor(r,g,b)
        lg.rectangle("fill", xpBarR:get())
    else
        lg.setColor(1, 1, 1)
        helper.gradientRect("horizontal", XP_BAR_GRADIENT[1], targColor, xpBarR:get())
    end
end



---@param upg g.Tree.Upgrade
---@param x number
---@param y number
local function drawRewardsUI(upg, x, y)
    local font = g.getSmallFont(16)
    local uinfo = g.getUpgradeInfo(upg.id)

    local desc = g.getUpgradeDescription(uinfo, upg.level, false)
    local width, lines = font:getWrap(richtext.stripEffects(desc), DESC_TEXT_MAX_WIDTH)

    local boxR = Kirigami(0, 0, width, #lines * font:getHeight())
    local boxBaseR = boxR:padUnit(-12):set(x, y)
    boxR = boxR:center(boxBaseR)

    -- Draw gradient background
    do
        love.graphics.setColor(1, 1, 1)
        local a, b, c, d = boxBaseR:padUnit(3):get()
        love.graphics.draw(DESC_BACKGROUND_GRADIENT, a, b, 0, c, d)
    end
    love.graphics.setColor(SIDEBAR_COLOR)
    ui.drawPanel(boxBaseR:get())

    love.graphics.setColor(1, 1, 1)
    richtext.printRich(desc, font, boxR.x, boxR.y, boxR.w, "center")
end

local REWARDS_TEXT = assert(richtext.parseRichText(
    "{o}"..loc("Rewards:", nil, {context = "A list of permanent buff that were given to players."}).."{/o}"
))

---@param show {resource:boolean?,profile:boolean?,xpbar:boolean?}?
function HUD:draw(show)
    prof_push("HUD:draw")

    show = show or {}
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())

    -- Draw sidebar
    -- love.graphics.setColor(SIDEBAR_COLOR)
    helper.gradientRect("vertical", SIDEBAR_COLOR, objects.Color.BLUE, self.sidebarR:get())
    --love.graphics.rectangle("fill", self.sidebar:get())
    love.graphics.setColor(SIDEBAR_STRIP)
    love.graphics.rectangle("fill", self.sidebarR.x + self.sidebarR.w, 0, 2, self.sidebarR.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", self.sidebarR.x + self.sidebarR.w + 2, 0, 2, self.sidebarR.h)

    -- Draw resource HUD
    local resHudY = self.resourceHUD:draw(show.resource == false)

    -- Draw reward HUD
    local rewards = g.getUpgTree():getUnboundUpgrades()
    if #rewards > 0 then
        love.graphics.setColor(1, 1, 1)
        richtext.printRich(REWARDS_TEXT, g.getSmallFont(16), 0, resHudY - 2, self.sidebarR.w, "center")

        local rows = math.ceil(#rewards / 3)
        local gridBaseR = Kirigami(0, resHudY + 16, REWARD_CELL_SIZE * 3, REWARD_CELL_SIZE * rows)
            :centerX(self.sidebarR)
        local grid = gridBaseR:grid(3, rows)

        love.graphics.setColor(0, 0, 0, 0.3)
        do
            local x, y, w, h = gridBaseR:get()
            love.graphics.rectangle("fill", x, y, w, h, 4, 4)
        end

        -- Draw each permanent reward
        local hovered = nil
        local levelFont = g.getBigFont(16)
        for i, v in ipairs(rewards) do
            local gridR = grid[i]:padUnit(1)
            local uinfo = g.getUpgradeInfo(v.id)
            local cx, cy = gridR:getCenter()
            love.graphics.setColor(1, 1, 1)
            g.drawImage(uinfo.image, cx, cy)
            richtext.printRich("{o}"..v.level.."{/o}", levelFont, gridR.x, cy, gridR.w, "center")

            if iml.isHovered(gridR:get()) then
                -- Draw tooltip later
                hovered = v
            end
        end

        if hovered then
            local mx, my = ui.getMouse()
            drawRewardsUI(hovered, mx + 14, my - 3)
        end
    end

    -- Draw profile HUD
    love.graphics.setColor(1, 1, 1)
    self.profileHUD:draw(SIDEBAR_WIDTH, show.profile == false)

    if show.xpbar then
        local sidebarWidth = self.sidebarR.x + self.sidebarR.w + 4
        self.xpBarR = Kirigami(sidebarWidth, 0, r.w - sidebarWidth, 8)
        drawExperienceBar(self.xpBarR)
    end

    prof_pop() -- prof_push("HUD:draw")
end

function HUD:getSafeArea()
    local w, h = ui.getScaledUIDimensions()
    local x2 = self.sidebarR.x + self.sidebarR.w
    return Kirigami(x2, self.xpBarR.h, w - x2, h - self.xpBarR.h)
        :intersection(self.profileHUD:getSafeArea())
end

function HUD:getXPBarStartPos()
    local x, y = 0, 0

    if g.hasSession() then
        local sn = g.getSn()
        local targXP = helper.clamp(sn.xp/sn.xpRequirement, 0, 1)
        x = self.xpBarR.x + self.xpBarR.w * targXP
        y = self.xpBarR.y + self.xpBarR.h / 2
    end

    return x, y
end

return HUD
