local FreeCameraScene = require("src.scenes.FreeCameraScene")
local titleBackground = require("src.titleBackground")

local TITLE_TEXT = assert(richtext.parseRichText("{w}{o thickness=2}CaT CaT CaT CaT CaT CaT CaT CaT CaT CaT CaT{/o}{/w}"))

local function init()
    local shouldLoad = not (consts.DEV_MODE and love.keyboard.isDown("lshift", "rshift"))
    if shouldLoad and love.filesystem.getInfo("saves/save1.json", "file") and arg[1] ~= "--simulate" then
        g.loadSession("saves/save1.json")
    else
        g.newSession()
    end

    g.gotoScene("map_scene")
end

local BUTTON_BASE_COL = objects.Color("#" .. "FF9F14F6")
local BUTTON_MAIN_COL = objects.Color("#" .. "FF3B12A4")
local PLAYB_BASE_COL = objects.Color("#" .. "FFE0AC35")
local PLAYB_MAIN_COL = objects.Color("#" .. "FF5E4200")
local SECONDARY_BUTTONS = {
    {
        loc"Settings",
        BUTTON_BASE_COL,
        BUTTON_MAIN_COL,
        function() g.gotoScene("setting_scene") end
    },
    {
        loc"Stats",
        BUTTON_BASE_COL,
        BUTTON_MAIN_COL,
        function() end
    },
    {
        loc"Quit",
        objects.Color("#".."FFF26957"),
        objects.Color("#".."FF4E0E05"),
        love.event.quit
    },
}

local text = {
    play = "{w amp=0.5 freq=0.7}{o thickness=0.5}"..loc("Play").."{/o}{/w}"
}

---@class TitleScene: FreeCameraScene
local title = FreeCameraScene()

function title:init()
    self.progress = 0
end

---@param dt number
function title:update(dt)
    self.progress = (self.progress + dt * 0.2) % 1
    titleBackground.update(dt)
end

local PRIMARY_BUTTON_SIZE = {200, 80}
local SECONDARY_BUTTON_SIZE = {144, 40}
local BUTTON_PAD = 4

function title:draw()
    ui.startUI()

    titleBackground.draw()

    -- Prepare layout
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())
    local topR, bottomR = r:splitVertical(1, 1)

    -- Draw title text
    -- love.graphics.setColor(1, 1, 1)
    -- local titleFont = g.getBigFont(48)
    -- local titleAreaR = Kirigami(0, 0, r.w, titleFont:getHeight()):center(topR)
    -- local width, lines = titleFont:getWrap(richtext.stripEffects(TITLE_TEXT), titleAreaR.w)
    -- local height = #lines * titleFont:getHeight()
    -- titleAreaR = titleAreaR:set(nil, nil, width, height):center(topR)
    -- richtext.printRich(TITLE_TEXT, titleFont, titleAreaR.x, titleAreaR.y, titleAreaR.w, "center")

    -- Calculate button layout size
    local buttonHeights = PRIMARY_BUTTON_SIZE[2] + SECONDARY_BUTTON_SIZE[2] * #SECONDARY_BUTTONS
    local maxButtonR = Kirigami(0, 0, ui.getScaledUIDimensions(), buttonHeights)
        :center(r)

    -- Prep button layouts
    local playButtonR = Kirigami(0, 0, unpack(PRIMARY_BUTTON_SIZE))
        :centerX(maxButtonR)
        :attachToTopOf(maxButtonR)
        :moveRatio(0, 1)
    local secondaryButtonGrid = Kirigami(0, 0, SECONDARY_BUTTON_SIZE[1], SECONDARY_BUTTON_SIZE[2] * #SECONDARY_BUTTONS)
        :attachToBottomOf(playButtonR)
        :centerX(playButtonR)
        :grid(1, #SECONDARY_BUTTONS)

    -- Draw play button
    do
        local cx,cy = playButtonR:getCenter()
        local t = love.timer.getTime()
        godrays.drawRays(cx,cy, t, {
            rayCount = 6,
            divisions=30,
            color = objects.Color.GOLD:clone():multiply(objects.Color({1,1,1,0.5})),
            startWidth=10,
            length=200,
            fadeTo=0,
            growRate=2.6,
        })
        godrays.drawRays(cx,cy, t*-1, {
            rayCount = 5,
            divisions=30,
            color = objects.Color.YELLOW:clone():multiply(objects.Color({1,1,1,0.6})),
            startWidth=10,
            length=300,
            fadeTo=0,
            growRate=2.6,
        })

        if ui.Button(text.play, PLAYB_BASE_COL, PLAYB_MAIN_COL, playButtonR:padUnit(BUTTON_PAD)) then
            init()
        end
    end

    for i, binfo in ipairs(SECONDARY_BUTTONS) do
        local buttonPadR = secondaryButtonGrid[i]:padUnit(4)
        love.graphics.setColor(0, 0, 0)

        if ui.Button(helper.wrapRichtextColor(objects.Color.WHITE, binfo[1]), binfo[2], binfo[3], buttonPadR) then
            binfo[4]()
        end
    end

    ui.endUI()
end


return title
