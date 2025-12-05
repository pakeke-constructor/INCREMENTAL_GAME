
--[[

==============================
Localization and i18n infra
==============================

]]


---@class localization
local localization = {}


---@param text string
---@param vars table<string, any>
local function interpolate(text, vars)
    ---@param str string
    local interpolated = text:gsub("(%%+{[^}]+})", function(str)
        local percentages = 0

        for i = 1, #str do
            if str:sub(i, i) == "%" then
                percentages = percentages + 1
            else
                break
            end
        end

        assert(percentages > 0)
        local result = str:sub(percentages + 1)
        if percentages % 2 == 1 then
            -- We're interpolating
            local variableData = str:sub(percentages + 2, -2)
            local variable, format = variableData:match("([^:]+):?(.*)")

            local value = vars[variable]
            if #format > 0 then
                result = string.format("%"..format, value)
            elseif value == nil then
                --[[
                the reason we do this is to signal to other systems 
                that the {} should be ignored.
                (double {{ implies an ESCAPED bracket sequence.)
                ]]
                result = "%{{"..variable.."}}"
            else
                result = tostring(value)
            end
        end

        return string.rep("%", percentages / 2)..result
    end)
    return interpolated
end



-- List of strings to be translated
---@type table<string, string>
local stringsToLocalize = {}
-- List of interpolators
---@type table<string, localization.Interpolator>
local interpolators = {}
-- List of available languages, key is language code, value is localized name
---@type table<string, string>
local languageList = {}


---@type table<string, string>
local translatedKeys = {}

---@class localization.Metadata
---@field public context string? Additional context to be added to translation key.

---@class localization.InterpolatorObject: objects.Class
local Interpolator = objects.Class("localization:Interpolator")

---@param text string
---@param metadata localization.Metadata?
function Interpolator:init(text, metadata)
    local key = text
    local context = metadata and metadata.context or ""
    if #context > 0 then
        key = key.."\0"..context
    end

    if translatedKeys[key] then
        self.text = translatedKeys[key]
    else
        -- TODO: Add warn that localization not found
        self.text = text
    end

    --[[
    dummy for now.
    In future, add proper translation
    ]]
    stringsToLocalize[key] = text
end

---Availability: Client and Server
---@param variables table<string, any>? Variable to interpolate
function Interpolator:__call(variables)
    return variables and interpolate(self.text, variables) or self.text
end

---Availability: Client and Server
function Interpolator:__tostring()
    return string.format("localization:Interpolator %p: %s", self, self.text)
end


local strTc = typecheck.assert("string")

---@alias localization.Interpolator localization.InterpolatorObject|fun(variables:table<string,any>?):string

---Create new interpolator that translates and interpolates based on variables, taking pluralization into account.
---
---Availability: Client and Server
---@param text string String to translate
---@param metadata localization.Metadata? Additional metadata
---@return localization.Interpolator
function localization.newInterpolator(text, metadata)
    strTc(text)
    assert(isLoadTime(), "this can only be called at load-time")
    local key = text
    local interpolator = interpolators[key]

    if not interpolator then
        interpolator = Interpolator(text, metadata)
        interpolators[key] = interpolator
    end

    return interpolator
end

---Translates a string.
---
---Availability: Client and Server
---@param text string String to translate
---@param variables table<string, any>? Variable to interpolate
---@param metadata localization.Metadata? Additional metadata
---@return string
function localization.localize(text, variables, metadata)
    return localization.newInterpolator(text, metadata)(variables)
end



---@param lang string
---@return string
---@return string|nil
local function extractLangRegCode(lang)
    local langcode, regcode = lang:match("(%l%l)_(%u%u)")
    if not langcode then
        return lang, nil
    end

    return langcode, regcode
end

---Load localization data (callable only during initialization).
---@param targetLang string
function localization.load(targetLang)
    local loadingContext = assert(isLoadTime(), "this can only be called at load-time")
    local langcode, regcode = extractLangRegCode(targetLang)
    local stringsWithRegCode = nil
    local stringsWithoutRegCode = nil

    -- Load all localization
    for _, lang in ipairs(love.filesystem.getDirectoryItems("assets/localization")) do
        if lang:lower():sub(-5) == ".json" then
            local contents = assert(love.filesystem.read("assets/localization/"..lang))
            local ok, jsondata = pcall(json.decode, contents)

            if ok then
                local langname = lang:sub(1, -6)
                languageList[langname] = helper.assert(jsondata.name, "missing name from", lang)
                local strings = helper.assert(jsondata.strings, "missing strings from", lang)

                if targetLang == langname then
                    if regcode then
                        stringsWithRegCode = strings
                    else
                        stringsWithoutRegCode = strings
                    end
                elseif langcode == langname then
                    stringsWithoutRegCode = strings
                end
            else
                log.error("unable to load localization from '"..lang.."': "..jsondata)
            end
        end
    end

    -- Localization file with country-specific code has higher priority.
    -- so load non-region strings first
    if stringsWithoutRegCode then
        for k, v in pairs(stringsWithoutRegCode) do
            translatedKeys[k] = v
        end
    end
    -- now load with region code
    if stringsWithRegCode then
        for k, v in pairs(stringsWithRegCode) do
            translatedKeys[k] = v
        end
    end
end


-- Dump list of strings to be translated.
function localization.dump()
    local jsondata = love.filesystem.read("localization.json")
    local strings = {}

    if jsondata then
        local res, strs = pcall(json.decode, jsondata)
        if res then
            strings = strs.strings or {}
        end
    end

    for k, v in pairs(stringsToLocalize) do
        strings[k] = v
    end

    jsondata = json.encode({name = "", strings = strings})
    love.filesystem.write("localization.json", jsondata)
end



function localization.getLanguages()
    return languageList
end



return localization
