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

-- Load language list

---@type table<string, string>
local languageList = {}

for _, file in ipairs(love.filesystem.getDirectoryItems("assets/localization")) do
    local lang, suffix, extension = file:match("([%w_%-]+)%.(%w+)%.(%w+)") --[[@as string?]]
    if not lang then
        lang, extension = file:match("([%w_%-]+)%.(%w+)") --[[@as string?]]
    end

    if lang and extension == "json" then
        local langdatajson = love.filesystem.read("assets/localization/"..file)
        local ok, langdata = pcall(json.decode, langdatajson)

        if ok then
            local langcode, regcode = extractLangRegCode(lang)
            if not languageList[lang] then
                languageList[lang] = langdata.name
            end
            languageList[langcode] = langdata.name
        end
    end
end


-- Language loader

---@param lang string
---@param suffix string?
local function loadLanguage(lang, suffix)
    local langfile
    if suffix then
        langfile = lang.."."..suffix..".json"
    else
        langfile = lang..".json"
    end

    local langdatajson, err = love.filesystem.read("assets/localization/"..langfile)
    if langdatajson then
        local ok, langdata = pcall(json.decode, langdatajson)
        if ok then
            localization.load(langdata.strings)
        else
            log.error("Unable to load "..langfile..": "..langdata)
        end
    end
end

---@param lang string
---@param suffix string?
local function loadLanguageWithRegcode(lang, suffix)
    -- Prioritize generic one then one with regcode
    local langcode, regcode = extractLangRegCode(lang)
    loadLanguage(langcode, suffix)

    if regcode then
        loadLanguage(lang, suffix)
    end
end

do
    local lang = settings.getLanguage()
    loadLanguageWithRegcode(lang) -- LLM
    loadLanguageWithRegcode(lang, "human") -- Human overrides
end



return {
    dump = function()
        local dumped = localization.dump()
        local f = love.filesystem.openFile("localization.json", "w")
        f:write(json.encode({name = "English", strings = dumped}))
        f:close()
    end,
    getLanguages = function()
        return languageList
    end
}
