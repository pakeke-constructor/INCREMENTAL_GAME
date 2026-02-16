
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

---@type table<string, boolean?>
local missingKeys = {}

---@class localization.Metadata
---@field public context string? Additional context to be added to translation key.

---@class localization.InterpolatorObject: objects.Class
local Interpolator = objects.Class("localization:Interpolator")

---@param key string
---@param metadata localization.Metadata?
local function getTranslationKey(key, metadata)
    local context = metadata and metadata.context or ""
    if #context > 0 then
        key = key.."\0"..context
    end
    return key, context
end

---@param text string
---@param metadata localization.Metadata?
function Interpolator:init(text, metadata)
    if text:sub(1, 1) == "\0" then
        self.text = text:sub(2)
    else
        local key, context = getTranslationKey(text, metadata)

        if translatedKeys[key] then
            self.text = translatedKeys[key]
        else
            local lang = settings.getLanguage()
            if not missingKeys[key] and lang ~= "en" then
                if #context > 0 then
                    log.warn(string.format("Missing %s translation key of %q (%q)", lang, text, context))
                else
                    log.warn(string.format("Missing %s translation key of %q", lang, text))
                end
                missingKeys[key] = true
            end
            self.text = text
        end

        stringsToLocalize[key] = text
    end
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
    local key = getTranslationKey(text, metadata)
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



---Load localization data (callable only during initialization).
---@param strings table<string, string>
function localization.load(strings)
    assert(isLoadTime(), "this can only be called at load-time")

    for k, v in pairs(strings) do
        translatedKeys[k] = v
    end
end


-- Dump list of strings to be translated.
---@return table<string, string>
function localization.dump()
    local strings = {}

    for k, v in pairs(stringsToLocalize) do
        strings[k] = v
    end

    return strings
end


return localization
