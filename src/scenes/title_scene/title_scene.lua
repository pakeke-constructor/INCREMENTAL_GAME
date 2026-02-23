local FreeCameraScene = require("src.scenes.FreeCameraScene")
local titleBackground = require("src.scenes.titleBackground")
local InteractiveCat = require(".interactive_cat")

local TITLE_TEXT = assert(richtext.parseRichText("{w}{o thickness=2}CAT CAT CAT CAT CAT CAT CAT CAT CAT CAT CAT{/o}{/w}"))

local function init()
    local shouldLoad = not (consts.DEV_MODE and love.keyboard.isDown("lshift", "rshift"))
    if shouldLoad and love.filesystem.getInfo("saves/save1.json", "file") and arg[1] ~= "--simulate" then
        g.loadSession("saves/save1.json")
    else
        local sn = g.newSession()
        sn.tree = g.loadPrestigeTree(0)
    end

    analytics.send("start")

    if g.getSn().showTutorials.harvest then
        g.gotoSceneViaMap("harvest_scene")
    else
        g.gotoScene("map_scene")
    end
end

local BUTTON_BASE_COL = objects.Color("#" .. "FF7B0BC0")
local BUTTON_MAIN_COL = objects.Color("#" .. "FF3B12A4")
local PLAYB_BASE_COL = objects.Color("#" .. "FFE0AC35")
local PLAYB_MAIN_COL = objects.Color("#" .. "FFD78F0A")
local DISCORD_BASE_COL = objects.Color("#" .. "FF9C91FF")
local DISCORD_MAIN_COL = objects.Color("#" .. "FF2C1CC0")
local SECONDARY_BUTTONS = {
    {
        loc("Settings", nil, {context = "Button to open game settings"}),
        BUTTON_BASE_COL,
        BUTTON_MAIN_COL,
        function() g.gotoScene("setting_scene") end
    },
    {
        loc("Credits", nil, {context = "Button to show game credits"}),
        BUTTON_BASE_COL,
        BUTTON_MAIN_COL,
        function() g.gotoScene("credits_scene") end
    },
}
-- iOS App Store does not allow adding "Quit" button to UI.
if love.system.getOS() ~= "iOS" then
    SECONDARY_BUTTONS[#SECONDARY_BUTTONS+1] = {
        loc("Quit", nil, {context = "Button to exit the game"}),
        objects.Color("#".."FFF26957"),
        objects.Color("#".."FF4E0E05"),
        love.event.quit
    }
end

local text = {
    play = "{w amp=0.5 freq=0.7}{o thickness=0.5}"..loc("Play", nil, {context = "Button to start the game"}).."{/o}{/w}",
    wishlist = "{o thickness=0.75}"..loc("Wishlist!", nil, {context = "Button to add the game to their wishlist"}).."{/o}",
    discord = "{o thickness=0.75}"..loc("Discord", nil, {context = "Button that opens the Discord server in browser"}).."{/o}",
}

---@class TitleScene: FreeCameraScene
local title = FreeCameraScene()

function title:init()
    self.progress = 0
    self.catLeft = InteractiveCat({flip=false})
    self.catRight = InteractiveCat({flip=true})
end

function title:enter()
    return g.saveAndInvalidateSession()
end

---@param dt number
function title:update(dt)
    g.requestBGM(g.BGMID.TITLE)

    self.progress = (self.progress + dt * 0.2) % 1
    titleBackground.update(dt)
    self.catLeft:update(dt)
    self.catRight:update(dt)
end

local PRIMARY_BUTTON_SIZE = {200, 80}
local SECONDARY_BUTTON_SIZE = {144, 40}
local BUTTON_PAD = 4

local RAY_COLOR = objects.Color("#".."FFEFC52C")

function title:draw()
    ui.startUI()

    titleBackground.draw()

    -- Prepare layout
    local r = ui.getScreenRegion()
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
    local wishlistButtonR = Kirigami(0, 0, 80, 24)
        :attachToLeftOf(r)
        :attachToBottomOf(r)
        :moveRatio(1, -1)
        :moveUnit(4, -4)
    local discordButtonR = Kirigami(0, 0, 80, 24)
        :attachToLeftOf(r)
        :attachToTopOf(wishlistButtonR)
        :moveRatio(1, 0)
        :moveUnit(4, -4)
    local catWidths = (maxButtonR.w - PRIMARY_BUTTON_SIZE[1])
    local iCatLeftR, _, iCatRightR = maxButtonR:splitHorizontal(catWidths, PRIMARY_BUTTON_SIZE[1], catWidths)

    -- Draw play button
    do
        local cx,cy = playButtonR:getCenter()
        local t = love.timer.getTime()/2

        godrays.drawRays(cx,cy, t/2.5, {
            rayCount = 3,
            divisions=100,
            color = RAY_COLOR,
            startWidth=8,
            length=600,
            fadeTo=0,
            growRate=0.6,
        })

        godrays.drawRays(cx,cy, -t/1.5, {
            rayCount = 5,
            divisions=100,
            color = RAY_COLOR,
            startWidth=9,
            length=150,
            fadeTo=0,
            growRate=1.6,
        })

        godrays.drawRays(cx,cy, t, {
            rayCount = 6,
            divisions=100,
            color = RAY_COLOR,
            startWidth=10,
            length=200,
            fadeTo=0,
            growRate=2.6,
        })

        godrays.drawRays(cx,cy, t*-1, {
            rayCount = 5,
            divisions=100,
            color = RAY_COLOR,
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
        love.graphics.setColor(1, 1, 1)

        if ui.Button("{o thickness=0.5}"..binfo[1].."{/o}", binfo[2], binfo[3], buttonPadR) then
            binfo[4]()
        end
    end

    -- Draw cats
    do
    local t = love.timer.getTime()
    self.catLeft:draw(iCatLeftR:moveUnit(0,10*math.sin(t)))
    self.catRight:draw(iCatRightR:moveUnit(0,10*math.cos(t)))
    end

    -- Draw other buttons
    -- if ui.Button(text.wishlist, objects.Color.GREEN, objects.Color.BLACK, wishlistButtonR) then
    --     print("TODO Steam link")
    -- end
    if ui.Button(text.discord, DISCORD_BASE_COL, DISCORD_MAIN_COL, wishlistButtonR) then
        print("TODO Discord link")
    end

    ui.endUI()
end


return title
