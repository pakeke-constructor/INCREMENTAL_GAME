local Character = require(".Character")
local defaultEffectGroup = require(".defaultEffectGroup")

---@class text.Pass: objects.Class
local Pass = objects.Class("text:Pass")

---@alias text.PassEffectInfo {name:string,args:table,func:fun(args:table,character:text.Character)}

---@param font love.Font
---@param maxwidth number
---@param alignment love.AlignMode
---@param color number[]
function Pass:init(font, maxwidth, alignment, color)
    assert(alignment ~= "justify", "TODO justify support")
    self.color = color
    self.font = font
    self.maxWidth = maxwidth
    self.align = alignment
    self.fontHeight = font and font:getHeight() or 0
    self.bufferedLineWidth = 0
    self.bufferedWordWidth = 0
    self.bufferingWhitespace = false
    self.addedCharacterIndex = 1 -- absolute
    self.currentLineStartIndex = 0 -- absolute
    self.currentLine = 0

    if self.kerningCache then
        table.clear(self.kerningCache)
    else
        ---@type table<string, number>
        self.kerningCache = {}
    end

    if self.widthCache then
        table.clear(self.widthCache)
    else
        ---@type table<string, number>
        self.widthCache = {}
    end

    if not self.character then
        self.character = Character(font, " ", 0)
    end

    if self.bufferedLine then
        table.clear(self.bufferedLine)
    else
        ---@type string[]
        self.bufferedLine = {}
    end

    if self.bufferedWord then
        table.clear(self.bufferedWord)
    else
        ---@type string[]
        self.bufferedWord = {}
    end

    if self.effectChangeIndex then
        table.clear(self.effectChangeIndex)
    else
        self.effectChangeIndex = {} ---@type table<integer, text.PassEffectInfo[]>
    end
    self.lastEffectApplied = nil
    self.lastEffectIndexAt = 0
end

---@param left string
---@param right string
function Pass:getKerning(left, right)
    local key = left..right
    local value = self.kerningCache[key]
    if not value then
        value = self.font:getKerning(left, right)
        self.kerningCache[key] = value
    end

    return value
end

---@param char string
function Pass:getCharacterWidth(char)
    local value = self.widthCache[char]
    if not value then
        value = self.font:getWidth(char)
        self.widthCache[char] = value
    end

    return value
end

---@param char string
local function isWhitespace(char)
    return char == " " or char == "\t"
end

function Pass:flushLine()
    if #self.bufferedLine > 0 then
        local offsetX = 0
        local offsetY = self.currentLine * self.fontHeight

        if self.align ~= "left" then
            offsetX = self.maxWidth - self.bufferedLineWidth

            -- Don't take whitespace width at the end of line into account.
            for i = #self.bufferedLine, 1, -1 do
                local char = self.bufferedLine[i]
                if isWhitespace(char) then
                    local kerning = self:getKerning(self.bufferedLine[i - 1] or " ", char)
                    offsetX = offsetX + kerning + self:getCharacterWidth(char)
                else
                    break
                end
            end

            if self.align == "center" then
                offsetX = offsetX / 2
            end
        end

        -- Draw current line
        local prevX = 0
        for i, char in ipairs(self.bufferedLine) do
            local absIndex = self.currentLineStartIndex + i

            if self.effectChangeIndex[absIndex] then
                -- Change effect application first before drawing the text
                self.lastEffectApplied = self.effectChangeIndex[absIndex]
            end

            local kerning = 0
            if i > 1 then
                kerning = self:getKerning(self.bufferedLine[i - 1], char)
            end
            self.character:init(self.font, char, absIndex)
            self.character:reset()
            self.character:setPosition(offsetX + prevX + kerning, offsetY)
            prevX = prevX + kerning + self:getCharacterWidth(char)

            -- Apply effects
            if self.lastEffectApplied then
                for _, eff in ipairs(self.lastEffectApplied) do
                    eff.func(eff.args, self.character)
                end
            end

            -- Draw character
            self.character:draw(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
        end

        self.currentLineStartIndex = self.currentLineStartIndex + #self.bufferedLine
        self.bufferedLineWidth = 0
        table.clear(self.bufferedLine)
    end

    self.currentLine = self.currentLine + 1
end

function Pass:flushWordNow()
    if #self.bufferedWord > 0 then
        for _, char in ipairs(self.bufferedWord) do
            self:addDirect(char)
        end

        table.clear(self.bufferedWord)
        self.bufferedWordWidth = 0
    end
end

function Pass:flushWord()
    if self.bufferingWhitespace or (self.bufferedLineWidth + self.bufferedWordWidth) <= self.maxWidth then
        -- Add it regardless
        return self:flushWordNow()
    else
        -- Flush to newline
        if self.bufferedLineWidth > 0 then
            -- Existing word has been added. Flush current line then the word.
            self:flushLine()
            self:flushWordNow()
        else
            -- No existing word. Flush word then current line.
            self:flushWordNow()
            self:flushLine()
        end
    end
end


local function shallowCopy(t)
    local result = {}
    for k,v in pairs(t)do
        result[k]=v
    end
    return result
end


---@param char string
function Pass:addWord(char)
    local kerning = 0
    if #self.bufferedWord > 0 then
        kerning = self:getKerning(self.bufferedWord[#self.bufferedWord], char)
    end

    self.bufferedWord[#self.bufferedWord+1] = char
    self.bufferedWordWidth = self.bufferedWordWidth + kerning + self:getCharacterWidth(char)
end

---@param char string
function Pass:addDirect(char)
    local kerning = 0
    if #self.bufferedLine > 0 then
        kerning = self:getKerning(self.bufferedLine[#self.bufferedLine], char)
    end

    self.bufferedLine[#self.bufferedLine+1] = char
    self.bufferedLineWidth = self.bufferedLineWidth + kerning + self:getCharacterWidth(char)
end

---@param char string|nil UTF-8 character
function Pass:add(char)
    -- Newline
    if char == nil or char == "\n" then
        self:flushWord()
        self:flushLine()
    elseif isWhitespace(char) then
        -- Whitespace
        if not self.bufferingWhitespace then
            self:flushWord()
            self.bufferingWhitespace = true
        end

        self:addWord(char)
        self.addedCharacterIndex = self.addedCharacterIndex + 1
    elseif string.byte(char) > 32 then
        -- Normal character
        if self.bufferingWhitespace then
            self:flushWord()
            self.bufferingWhitespace = false
        end

        if self.bufferedWordWidth > self.maxWidth and self.bufferedLineWidth == 0 then
            -- Line doesn't fit the max width. Flush immediately
            self:flushWord()
        end

        self:addWord(char)
        self.addedCharacterIndex = self.addedCharacterIndex + 1
    end
end

---@param effectInfo {[1]:string,[string]:number}
function Pass:updateEffect(effectInfo)
    local name = effectInfo[1]

    if name:sub(1, 1) == "/" then
        -- Removing effect. This won't complain if the effect doesn't exist
        name = name:sub(2)

        local effectList = self.effectChangeIndex[self.lastEffectIndexAt]
        if effectList then
            for i = #effectList, 1, -1 do
                if effectList[i].name == name then
                    -- Make a copy
                    if self.addedCharacterIndex ~= self.lastEffectIndexAt then
                        local newEffects = shallowCopy(effectList)
                        self.effectChangeIndex[self.addedCharacterIndex] = newEffects
                        effectList = newEffects
                    end

                    -- Remove effect
                    table.remove(effectList, i)
                    self.lastEffectIndexAt = self.addedCharacterIndex
                    return
                end
            end
        end
    else
        -- Adding effect
        local effectList = self.effectChangeIndex[self.lastEffectIndexAt]
        if not effectList then
            effectList = {}
        end

        local effectFunc = defaultEffectGroup:getEffectInfo(effectInfo[1])
        if effectFunc then
            -- Copy effect
            if self.addedCharacterIndex ~= self.lastEffectIndexAt then
                local newEffects = shallowCopy(effectList)
                self.effectChangeIndex[self.addedCharacterIndex] = newEffects
                effectList = newEffects
            end

            -- Add effect
            effectList[#effectList+1] = {
                name = effectInfo[1],
                args = effectInfo,
                func = effectFunc,
            }
            self.lastEffectIndexAt = self.addedCharacterIndex
        end
    end
end

return Pass
