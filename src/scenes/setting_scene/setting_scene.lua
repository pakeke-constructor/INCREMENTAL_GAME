local FreeCameraScene = require("src.scenes.FreeCameraScene")
local titleBackground = require("src.titleBackground")


local SLIDER_BACKGROUND = objects.Color.BLACK
local SLIDER_NORMAL = objects.Color.WHITE
local SLIDER_HOVER = objects.Color("#".."FFC0C0C0")
local SLIDER_PRESSED = objects.Color.GRAY


---@param reg kirigami.Region
---@param ... kirigami.Region
local function maxRegion(reg, ...)
    local x1, y1 = reg.x, reg.y
    local x2, y2 = x1 + reg.w, y1 + reg.h

    for i = 1, select("#", ...) do
        local r = select(i, ...)
        x1 = math.min(x1, r.x)
        y1 = math.min(y1, r.y)
        x2 = math.max(x2, r.x + r.w)
        y2 = math.max(y2, r.y + r.h)
    end

    return Kirigami(x1, y1, x2 - x1, y2 - y1)
end

---@param dx number
---@param dy number
---@param ... kirigami.Region
local function moveRegionInplace(dx, dy, ...)
    for i = 1, select("#", ...) do
        local r = select(i, ...)
        r.x = r.x + dx
        r.y = r.y + dy
    end
end

---@param baseR kirigami.Region
---@param ... kirigami.Region
local function makeInCenterInplace(baseR, ...)
    local centerizer = maxRegion(...)
    local centered = centerizer:center(baseR)
    moveRegionInplace(centered.x - centerizer.x, centered.y - centerizer.y, ...)
end



---@class SettingScene: FreeCameraScene
local setting = FreeCameraScene()

function setting:init()
    self.effectVolume = 50
    self.bgmVolume = 50
end

---@param dt number
function setting:update(dt)
    titleBackground.update(dt)
end

---@param value integer
---@param label string
---@param labelR kirigami.Region
---@param sliderBaseR kirigami.Region
local function drawVolume(value, label, labelR, sliderBaseR)
    local sliderR, valueR = sliderBaseR:splitHorizontal(10, 1)

    love.graphics.setColor(1, 1, 1)
    richtext.printRich("{o}"..label.."{/o}", g.getSmallFont(32), labelR.x, labelR.y, labelR.w, "center")
    love.graphics.setColor(SLIDER_BACKGROUND)
    love.graphics.rectangle("fill", sliderR:get())
    value = ui.Slider(
        "setting:"..label,
        "horizontal",
        objects.Color.TRANSPARENT,
        SLIDER_NORMAL,
        SLIDER_HOVER,
        SLIDER_PRESSED,
        value + 1,
        101, -- 0 to 100 both inclusive is 101
        0.1,
        sliderR:padUnit(1)
    ) - 1
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(
        "{o}"..value.."{/o}",
        g.getSmallFont(16),
        valueR.x,
        valueR.y,
        valueR.w,
        "right"
    )
    return value
end

function setting:draw()
    -- FIXME: This sucks. This should NEVER be done. Either fix scene manager or do something else
    -- This was done because cyclic require ugh.
    local sceneManager = require("src.scenes.sceneManager")

    ui.startUI()

    titleBackground.draw()

    -- Prep layout
    local w, h = ui.getScaledUIDimensions()
    local r = Kirigami(0, 0, w, h)
    local titleR, contentR, bottomR = r:splitVertical(72, h - 72 - 64, 64)

    -- Draw title
    local titleFont = g.getBigFont(48)
    local titleTextR = Kirigami(0, 0, w, titleFont:getHeight()):center(titleR)
    love.graphics.setColor(1, 1, 1)
    richtext.printRich("{w}{o}Settings{/o}{/w}",  titleFont, titleTextR.x, titleTextR.y, w, "center")

    -- Setup settings layout
    local font = g.getSmallFont(32)
    local smallFont = g.getSmallFont(16)
    -- Effects Volume
    local effectVolumeLabelR = Kirigami(0, 0, 240, font:getHeight())
        :centerX(titleTextR)
    local effectVolumeSliderBaseR = Kirigami(0, 0, 240, smallFont:getHeight())
        :attachToBottomOf(effectVolumeLabelR)
        :centerX(effectVolumeLabelR)
        :moveUnit(0, 8)
    -- Music Volume
    local musicVolumeLabelR = Kirigami(0, 0, 240, font:getHeight())
        :centerX(titleTextR)
        :attachToBottomOf(effectVolumeSliderBaseR)
        :moveUnit(0, 8)
    local musicVolumeSliderBaseR = Kirigami(0, 0, 240, smallFont:getHeight())
        :attachToBottomOf(musicVolumeLabelR)
        :centerX(musicVolumeLabelR)
        :moveUnit(0, 8)
    -- TODO: Language (I don't know how to create dropdown with iml)

    -- Centerize layout in place
    makeInCenterInplace(contentR,
        effectVolumeLabelR,
        effectVolumeSliderBaseR,
        musicVolumeLabelR,
        musicVolumeSliderBaseR
    )

    -- Draw effect volume
    self.effectVolume = drawVolume(self.effectVolume, "Effect Volume", effectVolumeLabelR, effectVolumeSliderBaseR)
    -- Draw music volume
    self.bgmVolume = drawVolume(self.bgmVolume, "Music Volume", musicVolumeLabelR, musicVolumeSliderBaseR)

    -- Draw "Done" Button
    local doneButtonR = Kirigami(0, 0, 144, 40)
        :center(bottomR)

    love.graphics.setColor(1, 1, 1)
    if ui.Button(
        helper.wrapRichtextColor(objects.Color.BLACK, "Done"),
        objects.Color.WHITE,
        objects.Color.GRAY,
        doneButtonR:get()
    ) then
        sceneManager.gotoLastScene()
    end

    ui.endUI()
end

return setting
