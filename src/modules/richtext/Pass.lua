local Character = require(".Character")
local defaultEffectGroup = require(".defaultEffectGroup")

---@class text.Pass: objects.Class
local Pass = objects.Class("text:Pass")

---@alias text.PassEffectInfo {name:string,args:table,func:fun(args:table,character:text.Character)}

---@param font love.Font
---@param maxwidth number
---@param alignment love.AlignMode
---@param color number[]? pass nil to compute only max width and wrapping
function Pass:init(font, maxwidth, alignment, color)
    assert(alignment ~= "justify", "TODO justify support")
    self.color = color or objects.Color.WHITE
    self.font = font
    self.maxWidth = maxwidth
    self.align = alignment
    self.fontHeight = font and font:getHeight() or 0
    self.bufferedLineWidth = 0
    self.bufferedWordWidth = 0
    self.bufferingWhitespace = false
    self.maxPossibleWidth = 0
    self.addedCharacterIndex = 1 -- absolute
    self.currentLineStartIndex = 0 -- absolute
    self.currentLine = 0
    self.draw = not not color

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
        ---@type (string|{texture:love.Texture,quad?:love.Quad,scale?:number})[]
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

if false then
    ---@param font love.Font
    ---@param maxwidth number
    ---@param alignment love.AlignMode
    ---@param color number[]? pass nil to compute only max width and wrapping
    ---@return text.Pass
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Pass(font, maxwidth, alignment, color) end
end

---@param left string|{texture:love.Texture}
---@param right string|{texture:love.Texture}
function Pass:getKerning(left, right)
    if (type(left)== "table") or (type(right)=="table") then
        -- kerning between textures; return 0.
        return 0
    end

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



local function drawImageInline(x,y, fontH, tex, quad, scale)
    local _,w,h
    if quad then
        _,_,w,h = quad:getViewport()
    else
        w,h = tex:getDimensions()
    end

    local sc = (fontH / h)
    scale = (scale or 1) * sc

    local o = fontH/2
    if quad then
        love.graphics.draw(tex,quad,x+o,y+o,0,scale,scale,w/2,h/2)
    else
        love.graphics.draw(tex,x+o,y+o,0,scale,scale,w/2,h/2)
    end
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
                if type(char) == "string" and isWhitespace(char) then
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

            if type(char) == "string" then
                local kerning = 0
                if i > 1 then
                    kerning = self:getKerning(self.bufferedLine[i - 1], char)
                end
                self.character:init(self.font, char, absIndex)
                self.character:reset()
                self.character:setPosition(offsetX + prevX + kerning, offsetY)
                prevX = prevX + kerning + self:getCharacterWidth(char)

                if self.draw then
                    -- Apply effects
                    if self.lastEffectApplied then
                        for _, eff in ipairs(self.lastEffectApplied) do
                            eff.func(eff.args, self.character)
                        end
                    end

                    -- Draw character
                    self.character:draw(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
                end
            else -- if a table! (image)
                local scale = char.scale
                local width
                if char.quad then
                    width = select(3, char.quad:getViewport()) --[[@as number]]
                else
                    width = char.texture:getWidth()
                end

                if self.draw then
                    drawImageInline(prevX+offsetX, offsetY, self.fontHeight, char.texture, char.quad, scale)
                end
                prevX = prevX + width * (char.scale or 1)
            end
        end

        self.currentLineStartIndex = self.currentLineStartIndex + #self.bufferedLine
        self.maxPossibleWidth = math.max(self.maxPossibleWidth, prevX + self.bufferedLineWidth)
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



---@param texdata {texture:love.Texture, quad?:love.Quad}
function Pass:addImage(texdata, scale)
    --[[
    NOTE:
    This has been vibe-coded, and needs testing.
    ]]

    local imageWidth
    if texdata.quad then
        imageWidth = select(3, texdata.quad:getViewport()) --[[@as number]]
    else
        imageWidth = texdata.texture:getWidth()
    end
    imageWidth = imageWidth * (scale or 1)

    -- Check if we need to flush the current word first
    if #self.bufferedWord > 0 then
        self:flushWord()
    end

    -- Check if adding this image would exceed max width
    if self.bufferedLineWidth + imageWidth > self.maxWidth then
        if self.bufferedLineWidth > 0 then
            -- Flush current line first
            self:flushLine()
        end
    end

    -- Add the image to the buffered line
    self.bufferedLine[#self.bufferedLine + 1] = {
        texture = texdata.texture,
        quad = texdata.quad,
        scale = scale or 1
    }

    -- Update line width
    self.bufferedLineWidth = self.bufferedLineWidth + imageWidth
    -- Increment character index to maintain proper positioning
    self.addedCharacterIndex = self.addedCharacterIndex + 1

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
function Pass:addEffect(effectInfo)
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

---@return number, integer
function Pass:getWrap()
    return self.maxPossibleWidth, math.max(self.currentLine, 1)
end

return Pass
