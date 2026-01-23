---@class _setting
local setting = {}

-- Keep this in-sync with the setting.init
local settingData = {
    sfxVolume = 100,
    bgmVolume = 50,
    lang = love.system.getPreferredLocales()[1] or "en",
    crt = false,
    fullscreen = true,
}

-- Load setting
if love.filesystem.getInfo("setting.json", "file") then
    local settingDataJSON, err = love.filesystem.read("setting.json")
    if settingDataJSON then
        local ok, settingDataTable = pcall(json.decode, settingDataJSON)
        if ok then
            for k, v in pairs(settingData) do
                if type(v) == type(settingDataTable[k]) then
                    settingData[k] = settingDataTable[k]
                end
            end
        else
            log.error("Cannot JSON decode setting.json: "..settingDataTable)
        end
    else
        log.error("Cannot load setting.json: "..err)
    end
end



function setting.save()
    local settingDataJSON = json.encode(settingData)
    local status, err = love.filesystem.write("setting.json", settingDataJSON)
    if not status then
        log.error("Cannot save settings: "..err)
    end
end

function setting.getSFXVolume()
    return settingData.sfxVolume
end

---@param volume integer value range [0, 100]
function setting.setSFXVolume(volume)
    settingData.sfxVolume = helper.clamp(math.floor(volume), 0, 100)
end

function setting.getBGMVolume()
    return settingData.bgmVolume
end

---@param volume integer value range [0, 100]
function setting.setBGMVolume(volume)
    settingData.bgmVolume = helper.clamp(math.floor(volume), 0, 100)
end

function setting.getLanguage()
    return settingData.lang
end

---@param lang string
function setting.setLanguage(lang)
    settingData.lang = lang
end

function setting.isCRTActive()
    return settingData.crt
end

---@param active boolean
function setting.setCRTActive(active)
    settingData.crt = not not active
end

function setting.isFullscreen()
    return settingData.fullscreen
end

---@param fs boolean
function setting.setFullscreen(fs)
    settingData.fullscreen = fs
end

return setting
