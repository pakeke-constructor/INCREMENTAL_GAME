local FreeCameraScene = require("src.scenes.FreeCameraScene")
local titleBackground = require("src.titleBackground")

local function init()
    g.gotoScene("map_scene")
end

local BUTTONS = {
    {"Play", init},
    {"Options", function() end},
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
    love.graphics.setColor(1, 1, 1)
    local titleFont = g.getBigFont(64)
    local titleAreaR = Kirigami(0, 0, r.w, titleFont:getHeight()):center(topR)
    richtext.printRich("{w}{o thickness=4}CaT x11{/o}{/w}", titleFont, titleAreaR.x, titleAreaR.y, titleAreaR.w, "center")

    -- Draw buttons
    local buttonR = Kirigami(0, 0, 144, 40)
        :attachToBottomOf(topR)
        :centerX(topR)
    for _, binfo in ipairs(BUTTONS) do
        local buttonPadR = buttonR:padUnit(4)
        love.graphics.setColor(0, 0, 0)

        if ui.Button(helper.wrapRichtextColor(objects.Color.BLACK, binfo[1]), BUTTON_MAIN_COL, BUTTON_BASE_COL, buttonPadR:get()) then
            binfo[2]()
        end

        buttonR = buttonR:moveRatio(0, 1)
    end

    ui.endUI()
end


return title
