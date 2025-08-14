
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



---@type table<string, table<string, string>>
local stringsToLocalize = {}
---@type table<string, localization.Interpolator>
local interpolators = {}
local EXPORT_ON_EXIT = true


---@type table<string, table<string, string>>
local translatedKeys = {}


---@class localization.InterpolatorObject: objects.Class
local Interpolator = objects.Class("localization:Interpolator")

---@param modname string
---@param text string
function Interpolator:init(modname, text, context)
    self.modname = modname

    if translatedKeys[modname] and translatedKeys[modname][text] then
        self.text = translatedKeys[modname][text]
    else
        self.text = text
    end

    --[[
    dummy for now.
    In future, add proper translation
    ]]
    if not stringsToLocalize[modname] then
        stringsToLocalize[modname] = {}
    end

    stringsToLocalize[modname][text] = text
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
---@param context table? Reserved for future use
---@return localization.Interpolator
function localization.newInterpolator(text, context)
    strTc(text)
    local loadingContext = assert(g.getLoadingContext(), "this can only be called at load-time")
    local key = loadingContext.modname.."\0"..text
    local interpolator = interpolators[key]

    if not interpolator then
        interpolator = Interpolator(loadingContext.modname, text)
        interpolators[key] = interpolator
    end

    return interpolator
end


---Translates a string.
---
---Availability: Client and Server
---@param text string String to translate
---@param variables table<string, any>? Variable to interpolate
---@param context table? Reserved for future use
---@return string
function localization.localize(text, variables, context)
    return localization.newInterpolator(text, context)(variables)
end


---@param modname string
---@param fsysobj love.filesystem.
---@param path string
local function tryLoad(modname, fsysobj, path)
    if fsysobj:exists(path) then
        local locData, err = fsysobj:read(path)
        if locData then
            local status, locs = pcall(json.decode, locData)
            if status then
                if not translatedKeys[modname] then
                    translatedKeys[modname] = {}
                end

                -- TODO: Handle pluralization
                for k, v in pairs(locs) do
                    translatedKeys[modname][k] = v
                end
            else
                log.error("unable to load localization for mod '"..modname.."': "..locs)
            end
        else
            log.error("unable to load localization for mod '"..modname.."': "..err)
        end
    end
end

---Load localization data from filesystem object (callable only during initialization).
---
---Note: This currently does nothing server-side.
---
---Availability: Client and Server
---@param fsysobj umg.FilesystemObject
function localization.load()
    local loadingContext = assert(g.getLoadingContext(), "this can only be called at load-time")
    local lang = love.system.getPreferredLocales()[1]

    -- Localization file without country-specific code has lower priority.
    local countryCodeOnly = lang:match("(%l%l)_%u%u")
    if countryCodeOnly then
        tryLoad(loadingContext.modname, fsysobj, countryCodeOnly..".json")
    end

    tryLoad(loadingContext.modname, fsysobj, lang..".json")
end


if EXPORT_ON_EXIT then

local jsondata = love.filesystem.read("localization.json")
local strings = {}

if jsondata then
    local res, strs = pcall(json.decode, jsondata)
    if res then
        strings = strs
    end
end

for modname, stringlist in pairs(stringsToLocalize) do
    if not strings[modname] then
        strings[modname] = {}
    end

    for k, v in pairs(stringlist) do
        strings[modname][k] = v
    end
end

jsondata = json.encode(strings)
love.filesystem.write("localization.json", jsondata)
end



return localization


