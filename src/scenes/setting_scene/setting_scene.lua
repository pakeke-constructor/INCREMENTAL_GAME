local FreeCameraScene = require("src.scenes.FreeCameraScene")
local sceneManager = require("src.scenes.sceneManager")

local titleBackground = require("src.scenes.titleBackground")
local sfx = require("src.sound.sfx")


local SLIDER_BACKGROUND = objects.Color.BLACK
local SLIDER_COLOR = objects.Color.WHITE

local TEXT = {
    SETTINGS = "{w}{o thickness=2}"..loc("Settings").."{/o}{/w}",
    EFFECT_VOLUME = loc("Effect Volume", nil, {context = "Slider to adjust the sound effect volume in-game"}),
    MUSIC_VOLUME = loc("Music Volume", nil, {context = "Slider to adjust the music volume in-game"}),
    LANGUAGE = loc("Language", nil, {context = "Button to select language for a videogame"}),
    REQUIRES_RESTART = loc("(requires restart)", nil, {context = "Shown on setting label that requires restart to take effect"}),
    FULLSCREEN = "{o}"..loc("Fullscreen", nil, {context = "Switching game from windowed to fullscreen,"}).."{/o}",
    CRT_EFFECT = "{o}"..loc("CRT Effect", nil, {context = "Option to emulate old-school CRT TV effects"}).."{/o}",
    DONE = loc("Done", nil, {context = "Button to apply changes as in a configuration or settings"})
}


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


---@param lang string
---@return string
---@return string|nil
local function extractLangRegCode(lang)
    local langcode, regcode = lang:lower():match("(%l%l)[_%-](.+)")
    if not langcode then
        return lang, nil
    end

    return langcode, regcode
end



---@class SettingScene: FreeCameraScene
local settingscene = FreeCameraScene()

function settingscene:init()
    sfx.setVolume(settings.getSFXVolume())

    -- key = language code, value = language name
    self.languages = getLanguageList()
    -- Interleaved
    ---@type [string,string][]
    self.languageListInterleaved = {}
    for k, v in pairs(self.languages) do
        self.languageListInterleaved[#self.languageListInterleaved+1] = {k, v}
    end
    self.languageListSlider = 1
    table.sort(self.languageListInterleaved, function (a, b) return a[1] < b[1] end)
    self.showLanguagePopup = false

    -- Ensure closest language match is selected
    do
        local lang = settings.getLanguage()
        if not self.languages[lang] then
            local langcode, regcode = extractLangRegCode(lang)
            local choice = nil
            for k in pairs(self.languages) do
                local lc, rc = extractLangRegCode(k)
                if lc == langcode then
                    if rc == regcode then
                        choice = k
                        break -- exact match, done
                    elseif not choice then
                        choice = k -- bare language fallback
                    end
                end
            end
            if choice then
                settings.setLanguage(choice)
            end
        end
    end
end

function settingscene:leave()
    settings.save()
end

---@param dt number
function settingscene:update(dt)
    g.requestBGM(g.BGMID.TITLE)
    titleBackground.update(dt)
end

---@param value integer
---@param label string
---@param labelR kirigami.Region
---@param sliderR kirigami.Region
local function drawVolume(value, label, labelR, sliderR)
    local valueR = Kirigami(0, 0, 100, 16)
        :centerY(sliderR)
        :attachToRightOf(sliderR)
        :padUnit(8, 0)

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
        "left"
    )
    return value
end

function settingscene:draw()
    ui.startUI()

    titleBackground.draw()

    -- Prep layout
    local w, h = ui.getScaledUIDimensions()
    local r = ui.getScreenRegion()
    local titleR, contentR, bottomR = r:splitVertical(72, h - 72 - 64, 64)

    -- Draw title
    local titleFont = g.getBigFont(48)
    local titleTextR = Kirigami(0, 0, w, titleFont:getHeight()):center(titleR)
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(TEXT.SETTINGS,  titleFont, titleTextR.x, titleTextR.y, w, "center")

    -- Setup settings layout
    local font = g.getSmallFont(32)
    local fontHeight = font:getHeight()
    local smallFont = g.getSmallFont(16)
    local smallFontHeight = smallFont:getHeight()

    -- Effects Volume
    local effectVolumeLabelR = Kirigami(0, 0, 240, fontHeight)
        :centerX(titleTextR)
    local effectVolumeSliderBaseR = Kirigami(0, 0, 240, smallFont:getHeight())
        :attachToBottomOf(effectVolumeLabelR)
        :centerX(effectVolumeLabelR)

    -- Music Volume
    local musicVolumeLabelR = Kirigami(0, 0, 240, fontHeight)
        :centerX(titleTextR)
        :attachToBottomOf(effectVolumeSliderBaseR)
        :moveUnit(0, 8)
    local musicVolumeSliderBaseR = Kirigami(0, 0, 240, smallFont:getHeight())
        :attachToBottomOf(musicVolumeLabelR)
        :centerX(musicVolumeLabelR)

    -- CRT toggle
    local crtTextWidth = richtext.getWidth(TEXT.CRT_EFFECT, font)
    local crtPlacementR = Kirigami(0, 0, crtTextWidth + fontHeight, fontHeight)
        :centerX(titleTextR)
        :attachToBottomOf(musicVolumeSliderBaseR)
        :moveUnit(0, 8)
    local crtLabelR, crtBoxR = crtPlacementR:splitHorizontal(crtTextWidth, fontHeight)
    crtBoxR = crtBoxR:padUnit(6)

    -- Fullscreen toggle
    local fsTextWidth = richtext.getWidth(TEXT.FULLSCREEN, font)
    local fsPlacementR = Kirigami(0, 0, fsTextWidth + fontHeight, fontHeight)
        :centerX(titleTextR)
        :attachToBottomOf(crtPlacementR)
        :moveUnit(0, 8)
    local fsLabelR, fsBoxR = fsPlacementR:splitHorizontal(fsTextWidth, fontHeight)
    fsBoxR = fsBoxR:padUnit(6)

    -- Language:
    local languageLabelR = Kirigami(0, 0, 240, font:getHeight() * 1.5)
        :centerX(titleTextR)
        :attachToBottomOf(fsPlacementR)
        :moveUnit(0, 8)
    local languageIconR = Kirigami(0, 0, 32, 32)
        :attachToTopOf(languageLabelR)
        :centerX(languageLabelR)
        :moveRatio(0, 1)
        :moveUnit(richtext.getWidth(TEXT.LANGUAGE, font) / 2 + 20, 0)
    local languageButtonR = Kirigami(0, 0, 144, 32)
        :attachToBottomOf(languageLabelR)
        :centerX(languageLabelR)

    -- Centerize layout in place
    makeInCenterInplace(contentR,
        effectVolumeLabelR,
        effectVolumeSliderBaseR,
        musicVolumeLabelR,
        musicVolumeSliderBaseR,
        crtLabelR,
        crtBoxR,
        fsLabelR,
        fsBoxR,
        languageLabelR,
        languageIconR,
        languageButtonR
    )

    -- Draw effect volume
    local sfxVolume = settings.getSFXVolume()
    sfxVolume = drawVolume(sfxVolume, TEXT.EFFECT_VOLUME, effectVolumeLabelR, effectVolumeSliderBaseR)
    settings.setSFXVolume(sfxVolume)
    sfx.setVolume(sfxVolume)

    -- Draw music volume
    local bgmVolume = settings.getBGMVolume()
    bgmVolume = drawVolume(bgmVolume, TEXT.MUSIC_VOLUME, musicVolumeLabelR, musicVolumeSliderBaseR)
    settings.setBGMVolume(bgmVolume)

    -- Draw CRT
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(TEXT.CRT_EFFECT, font, crtLabelR.x, crtLabelR.y, crtLabelR.w, "left")
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", crtBoxR:padUnit(-2):get())
    local crtState = ui.Checkbox(objects.Color.WHITE, crtBoxR, settings.isCRTActive())
    settings.setCRTActive(crtState)

    -- Draw Fullscreen
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(TEXT.FULLSCREEN, font, fsLabelR.x, fsLabelR.y, fsLabelR.w, "left")
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", fsBoxR:padUnit(-2):get())
    local fsState = ui.Checkbox(objects.Color.WHITE, fsBoxR, settings.isFullscreen())
    settings.setFullscreen(fsState)

    -- Draw language stuff
    local all = maxRegion(languageButtonR, languageIconR, languageLabelR)
    lg.setColor(0.4,0.5,0.75)
    ui.drawSingleColorPanel(all:get())
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(
        "{o}"..TEXT.LANGUAGE.."{/o}",
        g.getSmallFont(32),
        languageLabelR.x,
        languageLabelR.y,
        languageLabelR.w,
        "center"
    )
    do
        love.graphics.setColor(0, 0, 0)
        local lx, ly = languageIconR:getCenter()
        for dy = -1, 1, 2 do
            for dx = -1, 1, 2 do
                g.drawImage("localization_icon", lx + dx, ly + dy, 0, 0.75, 0.75)
            end
        end
        love.graphics.setColor(1, 1, 1)
        g.drawImage("localization_icon", lx, ly, 0, 0.75, 0.75)
    end
    richtext.printRich(
        "{o}"..TEXT.REQUIRES_RESTART.."{/o}",
        g.getSmallFont(16),
        languageLabelR.x,
        languageLabelR.y + 32,
        languageLabelR.w,
        "center"
    )
    local lang = settings.getLanguage()
    local langButtonText = self.languages[lang] or lang
    if ui.DefaultButton("{o}"..langButtonText.."{/o}", languageButtonR) and #self.languageListInterleaved > 0 then
        self.showLanguagePopup = true
    end

    -- Draw "Done" Button
    local doneButtonR = Kirigami(0, 0, 144, 40)
        :center(bottomR)

    love.graphics.setColor(1, 1, 1)
    if ui.Button(
        helper.wrapRichtextColor(objects.Color.BLACK, TEXT.DONE),
        objects.Color.WHITE,
        objects.Color.GRAY,
        doneButtonR
    ) then
        sceneManager.gotoLastScene()
    end

    if self.showLanguagePopup then
        self:_drawLanguageSelector()
    end

    ui.endUI()
end

function settingscene:_drawLanguageSelector()
    local SELECTION_BUTTON_SIZE = 40
    local r = ui.getScreenRegion()
    local panelR = r
        :padRatio(0.1)
        :shrinkToMultipleOf(SELECTION_BUTTON_SIZE)
        :center(r)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", panelR:get())
    iml.panel(r:get()) -- Prevent input propagation to bottom

    local gridBaseR, sliderR = panelR:splitHorizontal(panelR.w - 32, 32)
    local maxItems = math.floor(panelR.h / SELECTION_BUTTON_SIZE)
    local grid = gridBaseR:grid(1, maxItems)

    love.graphics.setColor(SLIDER_BACKGROUND)
    love.graphics.rectangle("fill", sliderR:get())
    self.languageListSlider = ui.Slider(
        "languageListSlider",
        "vertical",
        SLIDER_COLOR,
        self.languageListSlider,
        math.max(#self.languageListInterleaved - maxItems, 1),
        nil,
        sliderR:padUnit(2)
    )
    love.graphics.setColor(1, 1, 1)

    local font = g.getSmallFont(32)
    for i = 1, maxItems do
        local lang = self.languageListInterleaved[i + self.languageListSlider - 1]
        if not lang then
            break
        end

        local buttonR = grid[i]:padUnit(4)
        local textR = buttonR
            :set(nil, nil, nil, font:getHeight())
            :centerY(buttonR)

        -- Draw button
        if iml.wasJustClicked(buttonR:get()) then
            settings.setLanguage(lang[1])
            self.showLanguagePopup = false
            love.event.quit("restart")
        elseif iml.isHovered(buttonR:get()) then
            love.graphics.setColor(0, 0, 0, 0.2)
            love.graphics.rectangle("fill", buttonR:get())
        end

        -- Add outline for current language selection
        if lang[1] == settings.getLanguage() then
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", buttonR:get())
        end

        -- Button text
        love.graphics.setColor(1, 1, 1)
        richtext.printRich("{o}"..lang[2].."{/o}", font, textR.x, textR.y, textR.w, "center")
    end
end


function settingscene:keyreleased(_k, scancode)
    if scancode == "escape" then
        sceneManager.gotoLastScene()
    end
end


function settingscene:wheelmoved(_, dy)
    if self.showLanguagePopup then
        local dir = helper.sign(dy)
        self.languageListSlider = math.max(self.languageListSlider - dir, 1)
    end
end


return settingscene
