local objects = require("src.modules.objects.objects")
local Resources = require(".ResourcesHUD")
local Profile = require(".ProfileHUD")


local SIDEBAR_COLOR = objects.Color("#".."FF1F60BB")
local SIDEBAR_COLOR2 = objects.Color("#".."FF1444AA")

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

local STATS_PANEL_COLOR = objects.Color("#".."ffe3ae10")
local STATS_PANEL_HOVER_COLOR = objects.Color("#"..  "FFCD7306")
local STATS_PANEL_TEXT = "{o}"..loc("Stats", nil, {context = "area to hover to show game statistics"}).."{/o}"

local LEVEL_TEXT = interp("Level %{n}", {
    context = "As in, the current xp level of the player. Player earns XP to increase their level. e.g. 'Level 5'."
})



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
    self.freeArea = ui.getScreenRegion()
    self.statsWidth = 200 -- hardcode but harvest_scene needs this
end

if false then
    ---@return g.HUD
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function HUD() end
end

---@param dt number
function HUD:update(dt)
    local fullR = ui.getFullScreenRegion()
    self.sidebarR = ui.getScreenRegion():set(nil, nil, SIDEBAR_WIDTH, fullR.h)
    self.resourceHUD:update(dt)
    self.profileHUD:update(dt)
end


local XP_BAR_GRADIENT = {
    objects.Color("#".."FF4161D7"),
    objects.Color("#".."FFD773F6"),
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
    local xpBarR = xpBarBaseR:padUnit(0,2,2,2)
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
    local uinfo = g.getUpgradeInfo(upg.id)
    local desc = g.getUpgradeDescription(uinfo, upg.level, false)

    if #desc == 0 and uinfo.kind == "TOKEN" then
        local tinfo = g.getTokenInfo(uinfo.tokenType)
        desc = tinfo.description or ""
    end

    if #desc == 0 then
        desc = uinfo.name
    end

    return helper.tooltip(desc, x, y)
end

local REWARDS_TEXT = assert(richtext.parseRichText(
    "{o}"..loc("Rewards:", nil, {context = "A list of permanent buff that were given to players."}).."{/o}"
))

---@param show {resource:boolean?,profile:boolean?,xpbar:boolean?}?
function HUD:draw(show)
    prof_push("HUD:draw")

    show = show or {}
    local r = ui.getScreenRegion()

    -- Draw sidebar
    lg.setColor(1,1,1)
    helper.gradientRect("vertical", SIDEBAR_COLOR, SIDEBAR_COLOR2, self.sidebarR:padUnit(-r.x, -r.y, 0, 0):get())
    love.graphics.setColor(SIDEBAR_STRIP)
    love.graphics.rectangle("fill", self.sidebarR.x + self.sidebarR.w, 0, 2, self.sidebarR.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", self.sidebarR.x + self.sidebarR.w + 2, 0, 2, self.sidebarR.h)

    -- level {x} text
    do
    local LEVEL_TXT_H = 32
    lg.setColor(1,1,1)
    local lvRegion = self.sidebarR:set(nil,nil,nil,LEVEL_TXT_H):padRatio(0.15)
    local sn = g.getSn()
    local lvlText = "{wavy freq=0.3}{o}" .. LEVEL_TEXT({n = g.getSn().totalLevel})
    if sn.xp >= sn.xpRequirement then
        lvlText = "{rainbow}" .. lvlText
    end
    richtext.printRichContained(lvlText, g.getSmallFont(16), lvRegion:get())
    end

    -- Draw resource HUD
    local resHudY = self.resourceHUD:draw(show.resource == false)

    -- Draw reward HUD
    local rewards = g.getUpgTree():getUnboundUpgrades()
    if #rewards > 0 then
        love.graphics.setColor(1, 1, 1)
        richtext.printRich(REWARDS_TEXT, g.getSmallFont(16), self.sidebarR.x, self.sidebarR.y + resHudY - 2, self.sidebarR.w, "center")

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

            if uinfo.kind == "TOKEN" then
                local tinfo = g.getTokenInfo(uinfo.tokenType)
                g.drawTokenImage(tinfo, cx, cy)
            elseif uinfo.image then
                g.drawImage(uinfo.image, cx, cy)
            end

            if uinfo.drawUI then
                uinfo:drawUI(v.level, gridR:get())
            end

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
        --local sidebarWidth = self.sidebarR.x + self.sidebarR.w + 4
        --self.xpBarR = Kirigami(sidebarWidth, 0, r.w - sidebarWidth, 16)
        local sidebarWidth = r.w - self.sidebarR.w
        self.xpBarR = Kirigami(self.sidebarR.x + self.sidebarR.w + 4, 0, sidebarWidth - 4, 16)
        drawExperienceBar(self.xpBarR)
    end

    do
        local sidebarWithoutProfileR = self.sidebarR:set(nil, nil, nil, select(2, self.profileHUD:getStackTokenPos()) - 4)
        local sidebarHoverR = Kirigami(0, 0, 72, 24)
            :attachToBottomOf(sidebarWithoutProfileR)
            :centerX(sidebarWithoutProfileR)
            :moveRatio(0, -1)
            :moveUnit(0, -12)

        local isStatsHovered = iml.isHovered(sidebarHoverR:get())
        if isStatsHovered then
            love.graphics.setColor(STATS_PANEL_HOVER_COLOR)
        else
            love.graphics.setColor(STATS_PANEL_COLOR)
        end
        ui.drawSingleColorPanel(sidebarHoverR:get())

        love.graphics.setColor(1, 1, 1)
        richtext.printRichContained(STATS_PANEL_TEXT, g.getSmallFont(16), sidebarHoverR:get())
        if isStatsHovered then
            self:drawStatsAndTokenPool()
        end
    end

    prof_pop() -- prof_push("HUD:draw")
end

function HUD:getSafeArea()
    local result = ui.getScreenRegion()
    return result:padUnit(self.sidebarR.w + 4, self.xpBarR.y + self.xpBarR.h, 0, 0)
        :intersection(result)
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


local STATS_TO_SHOW = {"HitSpeed", "HitDamage", "HarvestArea"}
local STATS_TITLE_TEXT = "{o thickness=2}"..loc("Stats", nil, {context = "Place to show statistics of current game"}).."{/o}"
local CROPS_TITLE_TEXT = "{o thickness=2}"..loc("Crop List").."{/o}"
local TOKEN_IMAGE_SCALE = 1

local STATS_BACKGROUND = helper.newGradientMesh(
    "vertical",
    objects.Color("#".."ff02acc9"),
    objects.Color("#".."ffac02c9")
)

function HUD:drawStatsAndTokenPool()
    assert(g.hasSession())

    prof_push("HUD:drawStatsAndTokenPool()")

    local r = ui.getScreenRegion()
    local mainR = Kirigami(0, 0, self.statsWidth, r.h)
        :attachToRightOf(r)
        :moveRatio(-1, 0)
        :padUnit(8)

    local statsR, tokensR = mainR:padRatio(0.1):splitVertical(1, 1)
    local titleFont = g.getBigFont(32)

    love.graphics.setColor(1, 1, 1)
    do
        local x, y, w, h = mainR:padUnit(4):get()
        love.graphics.draw(STATS_BACKGROUND, x, y, 0, w, h)
    end
    ui.drawPanel(mainR:get())

    -- Do stats layout and drawing
    do
        local titleR = statsR:set(nil, nil, nil, titleFont:getHeight())
        local statFont = g.getSmallFont(16)
        local statBaseGridR = statsR:padUnit(4, titleFont:getHeight() + 8, 4, 8)
            :set(nil, nil, nil, (statFont:getHeight() + 2) * #STATS_TO_SHOW)
        local statGrid = statBaseGridR:grid(1, #STATS_TO_SHOW)

        richtext.printRichContainedNoWrap(STATS_TITLE_TEXT, titleFont, titleR:get())

        love.graphics.setColor(0, 0, 0, 0.3)
        helper.quickRoundedRectangle("fill", 4, statBaseGridR:padUnit(-4))
        love.graphics.setColor(1, 1, 1)

        local fh = statFont:getHeight() / 2
        for i, cellR in ipairs(statGrid) do
            local statName = g.VALID_STATS[STATS_TO_SHOW[i]].name
            local statValue = math.floor(g.stats[STATS_TO_SHOW[i]] * 100 + 0.5) / 100 -- rounding to 2 nearest decimal

            local x, y, w, h = cellR:get()
            y = y + h / 2
            love.graphics.print(statName, statFont, x, y, 0, 1, 1, 0, fh)
            love.graphics.printf(tostring(statValue), statFont, x, y, w, "right", 0, 1, 1, 0, fh)
        end
    end

    love.graphics.setColor(1, 1, 1)
    -- Do crop pool layout and drawing
    do
        local CELL_PADDING = 4

        local titleR = tokensR:set(nil, nil, nil, titleFont:getHeight())

        local tokenPoolInfo = {}
        local tokenPool = g.getMainWorld().tokenPool.tokens

        for _, toktype in ipairs(g.TOKEN_LIST) do
            local amount = tokenPool[toktype] or 0
            if amount > 0 then
                tokenPoolInfo[#tokenPoolInfo+1] = {toktype, amount}
            end
        end

        local cellSize = 16 * TOKEN_IMAGE_SCALE + CELL_PADDING * 2
        local tokenBaseGridR = tokensR:padUnit(0, titleFont:getHeight() + 8, 0, 8)
        local columns = math.floor(tokenBaseGridR.w / cellSize)
        local rows = math.ceil(#tokenPoolInfo / columns)
        local tokenPoolGridR = tokenBaseGridR:padUnit((tokenBaseGridR.w - columns * cellSize) / 2, 0)
            :set(nil, nil, nil, rows * cellSize)
        local tokenPoolGrid = tokenPoolGridR:grid(columns, rows)
        local amountFont = g.getSmallFont(16)

        love.graphics.setColor(0, 0, 0, 0.3)
        helper.quickRoundedRectangle("fill", 4, tokenPoolGridR:padUnit(-4))
        love.graphics.setColor(1, 1, 1)

        richtext.printRichContainedNoWrap(CROPS_TITLE_TEXT, titleFont, titleR:get())
        for i, tpi in ipairs(tokenPoolInfo) do
            local gridR = tokenPoolGrid[i]
            local x, y = gridR:getCenter()
            love.graphics.setColor(0, 0, 0, 0.3)
            helper.quickRoundedRectangle("fill", 2, gridR:padUnit(CELL_PADDING / 2))
            love.graphics.setColor(1, 1, 1)
            g.drawTokenIcon(tpi[1], x, y, 0, TOKEN_IMAGE_SCALE, TOKEN_IMAGE_SCALE)

            local amount = tostring(tpi[2])
            helper.printTextOutlineSimple(amount, amountFont, 1, gridR.x + gridR.w - amountFont:getWidth(amount), gridR.y + gridR.h - 12)
        end
    end

    prof_pop()
end

return HUD
