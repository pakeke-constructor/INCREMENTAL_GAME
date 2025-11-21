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

local BUTTONS = {
    {"Play", init},
    {"Settings", function() g.gotoScene("setting_scene") end},
    {"Stats", function() end},
    {"Quit", love.event.quit},
}
local BUTTON_BASE_COL = objects.Color.GRAY
local BUTTON_MAIN_COL = objects.Color.WHITE

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

    -- Draw buttons
    local buttonGrid = Kirigami(0, 0, 144, 40 * #BUTTONS)
        :center(r)
        :grid(1, #BUTTONS)
    for i, binfo in ipairs(BUTTONS) do
        local buttonPadR = buttonGrid[i]:padUnit(4)
        love.graphics.setColor(0, 0, 0)

        if ui.Button(helper.wrapRichtextColor(objects.Color.BLACK, binfo[1]), BUTTON_MAIN_COL, BUTTON_BASE_COL, buttonPadR:get()) then
            binfo[2]()
        end
    end

    ui.endUI()
end


return title
