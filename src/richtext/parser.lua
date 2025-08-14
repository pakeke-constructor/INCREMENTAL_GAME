local stopErr = require(".error_handling")

---@param char integer
local function isCharDrawable(char)
    return (char >= 32 and char ~= 127) or char == 0xa or char == 9
end

---@param char integer
local function isValidVariableCharacter(char, excludenum)
    if excludenum then
        return char == 95 or (char >= 65 and char <= 90) or (char >= 97 and char <= 122)
    else
        return (char >= 48 and char <= 58) or char == 46 or isValidVariableCharacter(char, true)
    end
end

---@param t string[]
local function concatAndClean(t)
    local result = table.concat(t)
    table.clear(t)
    return result
end

---@alias text.ParsedText ({[1]:string,[string]:number}|string)[]

---@param s string
local function rep2(s)
    return s:rep(2)
end

---Escape effect tag and string interpolation in the text.
---@param txt string
local function escape(txt)
    return (txt:gsub("[{|}]", rep2))
end

---@param parsed text.ParsedText|string
local function parsedTextToString(parsed)
    if type(parsed) == "string" then
        return parsed
    end

    local result = {}
    for _, data in ipairs(parsed) do
        local t = type(data)

        if t == "string" then
            result[#result+1] = escape(data)
        elseif t == "table" then
            local effectName = data[1]
            if effectName:sub(1, 1) == "/" then
                -- End of effect
                result[#result+1] = "{"..effectName.."}"
            else
                local effectData = {data[1]}

                for k, v in pairs(data) do
                    if type(k) == "string" then
                        effectData[#effectData+1] = string.format("%s=%.14g", k, v)
                    end
                end

                result[#result+1] = "{"..table.concat(effectData, " ").."}"
            end
        end
    end

    return table.concat(result)
end

local parsedTextMt = {__tostring = parsedTextToString}

---@param txt string
---@return text.ParsedText?,string?
local function parse(txt)
    local maybeOpeningBracket = false
    local maybeClosingBracket = false
    local openingBracket = false
    local endOfEffect = false
    local effectName = nil
    local effectKey = nil
    local i = 1 -- Character position index when parsing, in UTF-8 text
    local buffer = {}
    local currentEffectData = nil
    local result = setmetatable({}, parsedTextMt)

    for _, c in utf8.codes(txt) do
        local char = utf8.char(c)

        if openingBracket then
            if endOfEffect then
                -- Currently specifying end of effect name
                if char == "}" then
                    -- Load end of effect
                    -- Case: {/effect}
                    --               ^ = i
                    local found = false
                    local ename = concatAndClean(buffer)

                    for k = #result, 1, -1 do
                        local data = result[k]
                        if type(data) == "table" and data[1] == ename then
                            found = true
                            break
                        end
                    end

                    if not found then
                        return stopErr(txt, "col %d: found no opening %q effect tag", i - #ename, ename)
                    end

                    result[#result+1] = {"/"..ename}
                    currentEffectData = nil
                    endOfEffect = false
                    openingBracket = false
                elseif isValidVariableCharacter(c, #buffer == 0) then
                    -- Case: {/effect}
                    --         ^^^^^^ = i
                    buffer[#buffer+1] = char
                else
                    return stopErr(txt, "col %d: invalid identifier character %q when specifying effect name", i, char)
                end
            -- The rest of this must be specifying effect right now
            elseif char == "}" then
                -- End of effect define
                if effectKey then
                    -- End of specifying effect value
                    -- Case: {effect key=value}
                    --                        ^ = i
                    if #buffer == 0 then
                        return stopErr(txt, "col %d: effect value is empty", i - 1)
                    end

                    local effectValueStr = concatAndClean(buffer)
                    local effectValue = tonumber(effectValueStr)
                    if effectValue == nil then
                        return stopErr(txt, "col %d: effect value %q cannot be converted to number", i - #effectValue, effectValue)
                    end

                    currentEffectData[effectKey] = effectValue
                    result[#result+1] = currentEffectData
                elseif effectName then
                    -- Incomplete effect key
                    return stopErr(txt, "col %d: effect key is incomplete", i)
                else
                    -- Case: {effect}
                    --              ^ = i
                    -- Make effect
                    effectName = concatAndClean(buffer)
                    currentEffectData = {effectName}
                    result[#result+1] = currentEffectData
                end

                effectName = nil
                effectKey = nil
                openingBracket = false
            elseif char == " " then
                -- Indicate starting new effect parameter
                if not effectName then
                    -- Make effect
                    effectName = concatAndClean(buffer)
                    currentEffectData = {effectName}
                elseif effectKey then
                    -- TODO: Deduplicate
                    if #buffer == 0 then
                        return stopErr(txt, "col %d: effect value is empty", i - 1)
                    end

                    local effectValueStr = concatAndClean(buffer)
                    local effectValue = tonumber(effectValueStr)
                    if effectValue == nil then
                        return stopErr(txt, "col %d: effect value `%s` cannot be converted to number", i, effectValueStr)
                    end

                    currentEffectData[effectKey] = effectValue
                    effectKey = nil
                end
                -- Don't error because we need to allow as many spaces
            elseif char == "=" and effectName then
                effectKey = concatAndClean(buffer)
                -- Case: {effect key=value}
                --                  ^ = i
            elseif isValidVariableCharacter(c, #buffer == 0) or effectKey then
                -- Either specifying effect name, effect key, or effect value
                -- Case: {effect key=value}
                --        ^^^^^^ ^^^ ^^^^^ = i
                buffer[#buffer+1] = char
            else
                if effectName then
                    return stopErr(txt, "col %d: invalid character %q when specifying effect key", i, char)
                else
                    return stopErr(txt, "col %d: invalid character %q when specifying effect name", i, char)
                end
            end
        elseif maybeOpeningBracket then
            -- Previous character is opening bracket
            if char == "{" then
                -- Escape the tag
                -- Case: {{effect}}
                --       ?^ = i
                buffer[#buffer+1] = char
                maybeOpeningBracket = false
            else
                if #buffer > 0 then
                    result[#result+1] = concatAndClean(buffer)
                end

                openingBracket = true

                if char == "/" then
                    -- End of an effect
                    endOfEffect = true
                elseif isValidVariableCharacter(c, true) then
                    -- New effect
                    buffer[#buffer+1] = char
                else
                    return stopErr(txt, "col %d: invalid character %q when specifying effect name", i, char)
                end

                maybeOpeningBracket = false
            end
        elseif maybeClosingBracket then
            if char == "}" then
                -- Case: {{effect}}
                --               ?^ = i
                buffer[#buffer+1] = char
                maybeClosingBracket = false
            else
                buffer[#buffer+1] = "}"..char -- handle it gracefully because this case is easy
                --return stopErr(txt, "col %d: unexpected character %q while parsing", i, char)
            end
        elseif char == "{" then
            maybeOpeningBracket = true
        elseif char == "}" then
            maybeClosingBracket = true
        elseif isCharDrawable(c) then
            buffer[#buffer+1] = char
        end

        i = i + 1
    end

    -- Flush
    if #buffer > 0 then
        result[#result+1] = concatAndClean(buffer)
    end

    return result
end


---@param txt text.ParsedText|string
local function ensureParsedText(txt)
    if type(txt) == "table" then
        return txt
    else
        local result, msg = parse(txt)
        if not result then
            return stopErr(txt, "%s", msg)
        end

        return result
    end
end

return {
    parse = parse,
    ensure = ensureParsedText,
    tostring = parsedTextToString,
    escape = escape
}
