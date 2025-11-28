local FreeCameraScene = require("src.scenes.FreeCameraScene")
local sceneManager = require("src.scenes.sceneManager")

local titleBackground = require("src.titleBackground")
local sfx = require("src.sound.sfx")


local SLIDER_BACKGROUND = objects.Color.BLACK
local SLIDER_COLOR = objects.Color.WHITE


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

-- Keep this in-sync with the setting.init
local settingData = {
    sfxVolume = 100,
    bgmVolume = 50,
}

function setting:init()
    if love.filesystem.getInfo("setting.json", "file") then
        local success, sdata = pcall(function()
            local settingDataJSON = love.filesystem.read("setting.json")
            local settingDataTable = json.decode(settingDataJSON)
            return {
                sfxVolume = assert(tonumber(settingDataTable.sfxVolume)),
                bgmVolume = assert(tonumber(settingDataTable.bgmVolume)),
            }
        end)
        if success then
            settingData = sdata
        end
    end

    sfx.setVolume(settingData.sfxVolume)
    -- TODO: bgm.setVolume here

    -- TODO: Wire this up to settings once we have proper localization
    self.languages = love.system.getPreferredLocales()
    if #self.languages == 0 then
        -- Ensure there's at least one option
        self.languages[#self.languages+1] = "en_US"
    end
    self.languageIndex = 1
    self.showLanguagePopup = false
end

function setting:leave()
    local settingDataJSON = json.encode(settingData)
    assert(love.filesystem.write("setting.json", settingDataJSON))
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
        SLIDER_COLOR,
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
    richtext.printRich("{w}{o thickness=2}Settings{/o}{/w}",  titleFont, titleTextR.x, titleTextR.y, w, "center")

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
    -- Language. Let's just make it a button that shows fullscreen panel later.
    local languageLabelR = Kirigami(0, 0, 240, font:getHeight())
        :centerX(titleTextR)
        :attachToBottomOf(musicVolumeSliderBaseR)
        :moveUnit(0, 8)
    local languageButtonR = Kirigami(0, 0, 144, 32)
        :attachToBottomOf(languageLabelR)
        :centerX(languageLabelR)
        :moveUnit(0, 8)

    -- Centerize layout in place
    makeInCenterInplace(contentR,
        effectVolumeLabelR,
        effectVolumeSliderBaseR,
        musicVolumeLabelR,
        musicVolumeSliderBaseR,
        languageLabelR,
        languageButtonR
    )

    -- Draw effect volume
    settingData.sfxVolume = drawVolume(settingData.sfxVolume, "Effect Volume", effectVolumeLabelR, effectVolumeSliderBaseR)
    sfx.setVolume(settingData.sfxVolume)
    -- Draw music volume
    settingData.bgmVolume = drawVolume(settingData.bgmVolume, "Music Volume", musicVolumeLabelR, musicVolumeSliderBaseR)
    -- Draw language button
    love.graphics.setColor(1, 1, 1)
    -- TODO: localize
    richtext.printRich(
        "{o}Language{/o}",
        g.getSmallFont(32),
        languageLabelR.x,
        languageLabelR.y,
        languageLabelR.w,
        "center"
    )
    if ui.Button(
        helper.wrapRichtextColor(objects.Color.BLACK, self.languages[self.languageIndex]),
        objects.Color.WHITE,
        objects.Color.GRAY,
        languageButtonR:get()
    ) then
        self.showLanguagePopup = true
    end

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

    if self.showLanguagePopup then
        self:_drawLanguageSelector()
    end

    ui.endUI()
end

function setting:_drawLanguageSelector()
    local SELECTION_BUTTON_SIZE = 40
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())
    local panelR = r
        :padRatio(0.1)
        :shrinkToMultipleOf(SELECTION_BUTTON_SIZE)
        :center(r)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", panelR:get())
    iml.isHovered(r:get()) -- Dummy panel to prevent input propagation to bottom

    local grid = panelR:grid(1, math.floor(panelR.h / SELECTION_BUTTON_SIZE))

    -- TODO: Slider
    local font = g.getSmallFont(32)
    for i, lang in ipairs(self.languages) do
        local buttonR = grid[i]:padUnit(4)
        local textR = buttonR
            :set(nil, nil, nil, font:getHeight())
            :centerY(buttonR)

        -- Draw button
        if iml.wasJustClicked(buttonR:get()) then
            self.languageIndex = i
            self.showLanguagePopup = false
            break
        elseif iml.isHovered(buttonR:get()) then
            love.graphics.setColor(0, 0, 0, 0.2)
            love.graphics.rectangle("fill", buttonR:get())
        end

        -- Add outline for current language selection
        if i == self.languageIndex then
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", buttonR:get())
        end

        -- Button text
            love.graphics.setColor(1, 1, 1)
        richtext.printRich("{o}"..lang.."{/o}", font, textR.x, textR.y, textR.w, "center")
    end
end

return setting
