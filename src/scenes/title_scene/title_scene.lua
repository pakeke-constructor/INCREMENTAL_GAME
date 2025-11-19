local FreeCameraScene = require("src.scenes.FreeCameraScene")

local TILE_SIZE = 64

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
local BACKGROUND = objects.Color("#".."FFB3F024")

---@class TitleScene: FreeCameraScene
local title = FreeCameraScene()

function title:init()
    self.progress = 0
    self.animatedTileCanvas = love.graphics.newCanvas(TILE_SIZE, TILE_SIZE)
end

---@param dt number
function title:update(dt)
    self.progress = (self.progress + dt * 0.2) % 1
    self:_updateAnimationTile()
end

function title:draw()
    ui.startUI()

    self:_drawBackground()

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


function title:_updateAnimationTile()
    love.graphics.push("all")

    love.graphics.origin()
    love.graphics.setCanvas(self.animatedTileCanvas)
    love.graphics.clear(1, 1, 1, 0)
    love.graphics.setColor(1, 1, 1)

    -- Draw cat
    local catX = (1 - self.progress) * TILE_SIZE
    local catY = (1 - self.progress) * TILE_SIZE
    -- This double loop emulates wrapping
    for oy = -1, 1 do
        for ox = -1, 1 do
            g.drawImage("happy_cat", catX + ox * TILE_SIZE, catY + oy * TILE_SIZE, -math.pi / 4, 1.5)
        end
    end

    -- Draw text "CaT"
    local text = "CaT"
    local font = g.getSmallFont(32)
    local tx = self.progress * TILE_SIZE
    local ty = (1 - self.progress) * TILE_SIZE
    local tw = font:getWidth(text)
    local th = font:getHeight()
    -- This double loop emulates wrapping
    for oy = -1, 1 do
        for ox = -1, 1 do
            -- Ok the previous dual loop is for the corners of the canvas.
            -- This one is to emulate "thick" text without {o} richtext.
            for offx = -1, 1, 1 do
                for offy = -1, 1, 1 do
                    love.graphics.print(
                        text,
                        font,
                        tx + ox * TILE_SIZE + offx,
                        ty + oy * TILE_SIZE + offy,
                        -math.pi / 4,
                        1, 1,
                        tw / 2, th / 2
                    )
                end
            end
        end
    end

    love.graphics.pop()
end

function title:_drawBackground()
    love.graphics.clear(BACKGROUND)
    --if true then return end

    -- Draw canvas tiles
    local uiW, uiH = ui.getScaledUIDimensions()
    local tileW = math.ceil(uiW / TILE_SIZE)
    local tileH = math.ceil(uiH / TILE_SIZE)
    local tileOffX = (tileW * TILE_SIZE - uiW) / 2
    local tileOffY = (tileH * TILE_SIZE - uiH) / 2

    love.graphics.setColor(0, 0, 0, 0.3)
    for y = 0, tileH - 1 do
        for x = 0, tileW - 1 do
            love.graphics.draw(self.animatedTileCanvas, x * TILE_SIZE - tileOffX, y * TILE_SIZE - tileOffY)
        end
    end
end

return title
