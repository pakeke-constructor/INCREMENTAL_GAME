---@class text.RichText: objects.Class
local RichText = objects.Class("text:RichText")

local defaultEffectGroup = require(".defaultEffectGroup")
local Character = require(".Character")

---@param text string
---@param args text.TextArgs?
function RichText:init(text, args)
    args = args or {}

    ---@type {call:boolean,effects:{inst:any,update:fun(self:any,subtext:text.Character[])}[],text:string?,evaltext:string?,subtexts:text.Character[]}[]
    self.evals = {}
    self.variables = args.variables or _G
    self.effectGroup = args.effectGroup or defaultEffectGroup

    self:_parse(text)
end

---@param char integer
local function isValidVariableCharacter(char, excludenum)
    if excludenum then
        return char == 95 or (char >= 65 and char <= 90) or (char >= 97 and char <= 122)
    else
        return (char >= 48 and char <= 57) or isValidVariableCharacter(char, true)
    end
end

local function isCharDrawable(char)
    return (char >= 32 and char ~= 127) or char == 0xa or char == 9
end

---@param text string
---@private
function RichText:_parse(text)
    ---@type string[]
    local tempchar = {} -- This keep all the raw characters.
    local activeEffects = {} -- This keep the list of effect instances.
    ---@type string[]
    local activeEffectNames = {} -- This keep the list of effect names. The indices matches the activeEffects table.

    local function flushTempChar()
        local result = table.concat(tempchar)
        table.clear(tempchar)
        return result
    end

    local function flush(hasInterp, interpCall)
        local concatText = flushTempChar()
        if #concatText == 0 then
            return
        end

        local interpText, evalText
        if hasInterp then
            interpText = concatText
        else
            evalText = concatText
        end

        self.evals[#self.evals+1] = {
            effects = activeEffects,
            text = interpText,
            evaltext = evalText,
            call = interpCall,
            subtexts = {}
        }
        table.clear(tempchar)
        activeEffects = table.shallowCopy(activeEffects)
    end

    local hasInterp = false
    local interpCall = false
    local interpCallConfirmed = false
    local maybeBracket = false
    local maybeClosingBracket = false
    local openingBracket = false
    local endOfEffect = false
    local effectName = nil
    local effectKey = nil
    local i = 1 -- Character position index, in UTF-8 text
    local effectArgs = {}

    table.clear(self.evals)

    for _, c in utf8.codes(text) do
        local char = utf8.char(c)

        if openingBracket then
            if hasInterp then
                -- Currently in string interpolation
                if interpCall and not interpCallConfirmed then
                    if char == ")" then
                        interpCallConfirmed = true
                    else
                        error(string.format("col %d: expected \")\" but got %q when specifying interpolation call modifier", i, char))
                    end
                elseif #tempchar == 0 then
                    if not isValidVariableCharacter(c, true) then
                        error(string.format("col %d: invalid character %q when specifying variable name", i, char))
                    end

                    tempchar[#tempchar+1] = char
                elseif char == "(" then
                    if #tempchar == 0 then
                        error(string.format("col %d: invalid character %q when expecting variable name", i, char))
                    end

                    interpCall = true
                elseif char == "}" then
                    if #tempchar == 0 then
                        error(string.format("col %d: invalid character %q when expecting variable name", i, char))
                    end

                    -- End of string interpolation
                    if interpCall and not interpCallConfirmed then
                        error(string.format("col %d: expected \")\" but got \"}\" when specifying interpolation call modifier", i))
                    end

                    flush(hasInterp, interpCall)
                    hasInterp = false
                    interpCall = false
                    interpCallConfirmed = false
                    openingBracket = false
                elseif isValidVariableCharacter(c, false) then
                    tempchar[#tempchar+1] = char
                else
                    error(string.format("col %d: invalid identifier character %q when specifying interpolation identifier", i, char))
                end
            elseif endOfEffect then
                -- Currently specifying end of effect name
                if char == "}" then
                    -- Load end of effect
                    -- Case: {/effect}
                    --               ^ = i
                    local found = false
                    local ename = flushTempChar()

                    for j = #activeEffectNames, 1, -1 do
                        if activeEffectNames[j] == ename then
                            -- Remove the effect out
                            table.remove(activeEffects, j)
                            table.remove(activeEffectNames, j)
                            found = true
                            break
                        end
                    end

                    if not found then
                        error(string.format("col %d: found no opening %q effect tag", i - #ename, ename))
                    end

                    endOfEffect = false
                    openingBracket = false
                elseif isValidVariableCharacter(c, #tempchar == 0) then
                    -- Case: {/effect}
                    --         ^^^^^^ = i
                    tempchar[#tempchar+1] = char
                else
                    error(string.format("col %d: invalid identifier character %q when specifying effect name", i, char))
                end
            -- The rest of this must be specifying effect right now
            elseif char == "}" then
                -- End of effect
                if effectKey then
                    -- End of specifying effect value
                    -- Case: {effect key=value}
                    --                        ^ = i
                    if #tempchar == 0 then
                        error(string.format("col %d: effect value is empty", i - 1))
                    end

                    local effectValueStr = flushTempChar()
                    local effectValue = tonumber(effectValueStr)
                    if effectValue == nil then
                        error(string.format("col %d: effect value %q cannot be converted to number", i - #effectValue, effectValue))
                    end

                    effectArgs[effectKey] = effectValue
                elseif effectName then
                    -- Incomplete effect key
                    error(string.format("col %d: effect key is incomplete", i))
                else
                    effectName = flushTempChar()
                end

                -- Make effect
                local effectFunc = self.effectGroup:getEffectInfo(effectName)
                if not effectFunc then
                    error(string.format("col %d: effect %q does not exist", i - #effectName, effectName))
                end

                activeEffects[#activeEffects+1] = {
                    inst = effectArgs,
                    update = effectFunc
                }
                activeEffectNames[#activeEffectNames+1] = effectName
                effectArgs = {} -- Note: cannot use table.clear here
                effectName = nil
                effectKey = nil
                openingBracket = false
            elseif char == " " then
                -- Indicate starting new effect parameter
                if not effectName then
                    effectName = flushTempChar()
                elseif effectKey then
                    -- TODO: Deduplicate
                    if #tempchar == 0 then
                        error(string.format("col %d: effect value is empty", i - 1))
                    end

                    local effectValueStr = flushTempChar()
                    local effectValue = tonumber(effectValueStr)
                    if effectValue == nil then
                        error(string.format("col %d: effect value %q cannot be converted to number", i - #effectValue, effectValue))
                    end

                    effectArgs[effectKey] = effectValue
                    effectKey = nil
                end
                -- Don't error because we need to allow as many spaces
            elseif char == "=" and effectName then
                effectKey = flushTempChar()
                -- Case: {effect key=value}
                --                  ^ = i
            elseif isValidVariableCharacter(c, #tempchar == 0) or effectKey then
                -- Either specifying effect name, effect key, or effect value
                -- Case: {effect key=value}
                --        ^^^^^^ ^^^ ^^^^^ = i
                tempchar[#tempchar+1] = char
            else
                if effectName then
                    error(string.format("col %d: invalid character %q when specifying effect key", i, char))
                else
                    error(string.format("col %d: invalid character %q when specifying effect name", i, char))
                end
            end
        elseif maybeBracket then
            -- Previous character is opening bracket
            if char == "{" then
                -- Escape the tag
                -- Case: {{effect}}
                --       ?^ = i
                tempchar[#tempchar+1] = "{"
                maybeBracket = false
            else
                flush(hasInterp, interpCall)
                openingBracket = true

                if char == "$" then
                    -- String interpolation
                    hasInterp = true
                elseif char == "/" then
                    -- End of an effect
                    endOfEffect = true
                elseif isValidVariableCharacter(c, true) then
                    -- New effect
                    tempchar[#tempchar+1] = char
                else
                    error(string.format("col %d: invalid character %q when specifying effect name", i, char))
                end

                maybeBracket = false
            end
        elseif maybeClosingBracket then
            if char == "}" then
                -- Case: {{effect}}
                --               ?^ = i
                tempchar[#tempchar+1] = "}"
                maybeClosingBracket = false
            else
                error(string.format("col %d: unexpected character %q while parsing", i, char))
            end
        elseif char == "{" then
            maybeBracket = true
        elseif char == "}" then
            maybeClosingBracket = true
        elseif isCharDrawable(c) then
            tempchar[#tempchar+1] = char
        end

        i = i + 1
    end

    flush(hasInterp, interpCall)
end

---@param font love.Font
---@param eval {call:boolean,effects:{inst:any,update:fun(self:any,subtext:text.Character?,dt:number)}[],text:string?,evaltext:string?,subtexts:text.Character[]}
---@param start integer
---@return integer
---@private
function RichText:_updateSubtext(font, eval, start)
    local i = 0
    for _, c in utf8.codes(eval.evaltext) do
        i = i + 1
        local char = utf8.char(c)
        local subtext

        if eval.subtexts[i] then
            subtext = eval.subtexts[i]
            -- This is quite hacky of calling :init() directly.
            subtext:init(font, char, start)
        else
            subtext = Character(font, char, start)
            eval.subtexts[#eval.subtexts+1] = subtext
        end

        start = start + 1
    end

    return start
end

---@generic T
---@param t T[]
---@param i integer?
---@return (fun(table: T[], i?: integer):integer, T), T, integer?
local function iterArraysWithOffset(t, i)
    -- This is hacky way to tell ipairs to start AFTER specific index.
    return ipairs(table), t, i
end

---This (re)build the subtexts.
---@param font love.Font
---@private
function RichText:_rebuildAllSubtextsOfEvals(font)
    local start = 1

    for _, eval in ipairs(self.evals) do
        if eval.text then
            -- Evaluate string interpolator
            local interpData
            if eval.call then
                interpData = tostring(self.variables[eval.text]())
            else
                interpData = tostring(self.variables[eval.text])
            end

            if interpData ~= eval.evaltext then
                eval.evaltext = interpData
                start = self:_updateSubtext(font, eval, start)
            end
        elseif #eval.subtexts == 0 then
            -- Only update subtext once
            start = self:_updateSubtext(font, eval, start)
        else
            start = start + #eval.subtexts
        end
    end
end

---This reset the previous effect subtext values.
---@private
function RichText:_resetSubtextEffects()
    for _, eval in ipairs(self.evals) do
        for i = 1, #eval.evaltext do
            eval.subtexts[i]:reset()
        end
    end
end

---Apply effects to the characters.
---@private
function RichText:_applyEffects()
    -- Stage 3: Update subtext effects
    ---@type text.Character[]
    local toEvaluate = {}
    for i, eval in ipairs(self.evals) do
        for _, effect in ipairs(eval.effects) do
            -- Copy current subtexts
            for _, st in ipairs(eval.subtexts) do
                toEvaluate[#toEvaluate+1] = st
            end

            -- Get next evals until no more intersection
            for _, e in iterArraysWithOffset(self.evals, i) do
                local hasEffect = false
                for _, ef in ipairs(e.effects) do
                    if ef == effect then
                        hasEffect = true
                        break
                    end
                end

                if hasEffect then
                    -- Copy the subtexts
                    for _, st in ipairs(e.subtexts) do
                        toEvaluate[#toEvaluate+1] = st
                    end
                else
                    -- Stop here, this effect no longer affect this (and subsequent) eval.
                    break
                end
            end

            effect.update(effect.inst, toEvaluate)
            table.clear(toEvaluate)
        end
    end
end

---@param subtexts text.Character[]
---@param x number
---@param y number
---@private
function RichText:_makeSubtextPositionAbsolute(subtexts, x, y)
    for _, subtext in ipairs(subtexts) do
        local tx, ty = subtext:getPosition()
        subtext:setPosition(x + tx, y + ty)

        -- Apply pre-effects
        self:effectCharacter(subtext)
    end
end

---This computes the text placement.
---@param font love.Font
---@param maxwidth number
---@private
function RichText:_computeTextPositions(font, maxwidth)
    ---@type text.Character[]
    local sentence = {}
    local sentenceWidth = 0
    ---@type text.Character?
    local lastSubtext = nil
    local line = 0
    local lineWidth = 0
    local hasDrawnCurrentLine = false
    local lastIsWhitespace = false
    local fontHeight = font:getHeight()

    for _, eval in ipairs(self.evals) do
        for i = 1, (eval.evaltext and #eval.evaltext or 0) do
            local subtext = eval.subtexts[i]
            local char = subtext:getChar()
            local width = subtext:getDimensions()
            local kerning = 0

            if lastSubtext then
                kerning = font:getKerning(lastSubtext:getChar(), subtext:getChar())
            end

            if char == "\n" then
                -- Flush current sentences
                self:_makeSubtextPositionAbsolute(sentence, lineWidth, line * fontHeight)
                table.clear(sentence)

                -- Move it to next line
                line = line + 1
                lineWidth = 0
                kerning = 0
                sentenceWidth = 0
                hasDrawnCurrentLine = false
                lastIsWhitespace = false
            elseif char == " " or char == "\t" then
                lastIsWhitespace = true
            elseif lastIsWhitespace then
                -- Flush current sentence
                self:_makeSubtextPositionAbsolute(sentence, lineWidth, line * fontHeight)
                table.clear(sentence)
                lineWidth = lineWidth + sentenceWidth
                sentenceWidth = 0
                hasDrawnCurrentLine = true
                lastIsWhitespace = false
                lastSubtext = nil
            elseif (lineWidth + sentenceWidth + width + kerning) > maxwidth then
                if (not hasDrawnCurrentLine) or lastIsWhitespace then
                    -- The whole sentence does not fit.
                    self:_makeSubtextPositionAbsolute(sentence, lineWidth, line * fontHeight)
                    table.clear(sentence)
                    sentenceWidth = 0
                end

                -- Move it to next line
                line = line + 1
                lineWidth = 0
                kerning = 0
                hasDrawnCurrentLine = false
                lastIsWhitespace = false
                lastSubtext = nil
            else
                lastIsWhitespace = false
            end

            local subx, suby = subtext:getPosition()
            subtext:setPosition(subx + sentenceWidth, suby)
            sentenceWidth = sentenceWidth + width + kerning
            sentence[#sentence+1] = subtext
        end
    end

    -- Update last sentence
    self:_makeSubtextPositionAbsolute(sentence, lineWidth, line * fontHeight)
end

---Draw the rich text effect.
---@private
function RichText:_draw()
    local r, g, b, a = love.graphics.getColor()

    for _, eval in ipairs(self.evals) do
        for i = 1, #eval.evaltext do
            eval.subtexts[i]:draw(r, g, b, a)
        end
    end
end

---@param obj any
---@param t string
---@return boolean
local function isLOVEType(obj, t)
    return type(obj) == "userdata" and obj.typeOf and obj:typeOf(t)
end

---Draw the rich text effect.
---@param font love.Font Font object to use.
---@param transform love.Transform Transformation matrix.
---@param maxwidth number? Maximum width the text can occupy before breaking sentence to next line.
---@diagnostic disable-next-line: duplicate-set-field
function RichText:draw(font, transform, maxwidth) end

---Draw the rich text effect.
---@param font love.Font Font object to use.
---@param x number X position
---@param y number Y position
---@param maxwidth number? Maximum width the text can occupy before breaking sentence to next line.
---@param rot number? Rotation
---@param sx number? X scale
---@param sy number? Y scale
---@param ox number? X origin
---@param oy number? Y origin
---@param kx number? X shear
---@param ky number? Y shear
---@diagnostic disable-next-line: duplicate-set-field
function RichText:draw(font, x, y, maxwidth, rot, sx, sy, ox, oy, kx, ky)
    if isLOVEType(x, "Transform") then
        maxwidth = y
    end

    self:_rebuildAllSubtextsOfEvals(font)
    self:_resetSubtextEffects()
    self:_computeTextPositions(font, maxwidth or math.huge)

    love.graphics.push("all")
    love.graphics.applyTransform(x, y, rot, sx, sy, ox, oy, kx, ky)

    local stackPushed = self:applyAdditionalTransform(font)

    self:_applyEffects()
    self:_draw()

    if stackPushed then
        love.graphics.pop()
    end

    love.graphics.pop()
end

---Called on every characters that will be drawn on screen.
---
---Can be overridden by user
---@param char text.Character
function RichText:effectCharacter(char)
end

---Called on every draw call.
---
---Can be overridden by user
---@param font love.Font Font object used.
---@return boolean stackpush Is new transformation stack is pushed?
function RichText:applyAdditionalTransform(font)
    return false
end

---Retrieve the unformatted string of this rich text effect.
---@param font love.Font?
---@return string string The plain text (without effect tags and with string interpolation value evaluated) in this string
function RichText:getString(font)
    self:_rebuildAllSubtextsOfEvals(font or love.graphics.getFont())
    local result = {}

    for _, eval in ipairs(self.evals) do
        result[#result+1] = eval.evaltext
    end

    return table.concat(result)
end
RichText.__tostring = RichText.getString

---Retrieve the list of texts in this Text object without all the effect text.
---@param maxwidth number Maximum width before word-wrapping.
---@param font? love.Font Font object to use.
---@return number maxwidth Maximum width that the text occupy.
---@return string[] strings List of lines.
function RichText:getWrap(maxwidth, font)
    local text = self:getString(font)
    local f = font or love.graphics.getFont()
    return f:getWrap(text, maxwidth)
end

---Reset derived class-specific data.
---
---By default, this function does nothing. Can be overridden by user
function RichText:reset()
end

if false then
    ---@param text string
    ---@param args text.TextArgs?
    ---@return text.RichText
    ---@diagnostic disable-next-line: missing-return, cast-local-type
    function RichText(text, args) end
end

return RichText
