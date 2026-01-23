local love = require("love")
local utf8 = require("utf8")

local RichText = {}
RichText.__index = RichText

---@alias richtext.EffectArgs table<string, number?>

---@class richtext.Context
---@field public font love.Font
---@field public textOrDrawable string|love.Texture
---@field public index number 1-based index in the whole parsed text
---@field public quad love.Quad?

---@alias richtext.NextFunc fun(textOrDrawable: string|love.Texture, x: number, y: number, quad: love.Quad?)
---@alias richtext.EffectFunc fun(args: richtext.EffectArgs, x: number, y: number, context: richtext.Context, next: richtext.NextFunc)

---@class richtext._EffectInfo
---@field package func richtext.EffectFunc
---@field package args richtext.EffectArgs
---@field package perCharacter boolean

---@type table<string, {render:richtext.EffectFunc,perCharacter:boolean}>
local effectsRegistry = {}
---@type table<string, {texture: love.Texture, quad: love.Quad?}>
local imagesRegistry = {}

local function ensureUnique(name)
	if effectsRegistry[name] then
		error("effect already defined "..name, 2)
	elseif imagesRegistry[name] then
		error("image already defined "..name, 2)
	end
end

---Register a new effect.
---@param name string
---@param renderFunc richtext.EffectFunc
---@param options {perCharacter: boolean}?
function RichText.registerEffect(name, renderFunc, options)
	ensureUnique(name)
	effectsRegistry[name] = {
		render = renderFunc,
		perCharacter = not not (options and options.perCharacter)
	}
end

---Register a new image.
---@param name string
---@param texture love.Texture
---@param quad love.Quad?
function RichText.registerImage(name, texture, quad)
	ensureUnique(name)
	imagesRegistry[name] = { texture = texture, quad = quad }
end

-- internal parser and layout objects
---@class richtext.ParsedText
---@field tokens richtext.ParsedToken[]
---@field origin string
local ParsedText = {}
ParsedText.__index = ParsedText


---@class richtext.TextLayout
---@field lines richtext._RichTextCurrentLineInfo[]
---@field width number
---@field height number
---@field lineCount number
---@field font love.Font
local TextLayout = {}
TextLayout.__index = TextLayout

---@class richtext.ParsedToken
---@field type "text"|"image"|"push"|"pop"
---@field content string?
---@field name string?
---@field args richtext.EffectArgs?
---@field scale number?
---@field index number?

---@param content string
---@param pos number
---@param tokens richtext.ParsedToken[]
---@param openEffects string[]
local function handleTag(content, pos, tokens, openEffects)
	if content:sub(1, 1) == "/" then
		local name = content:sub(2)
		local found = false
		for i = #openEffects, 1, -1 do
			if openEffects[i] == name then
				table.remove(openEffects, i)
				found = true
				break
			end
		end
		if not found then
			error("Closing unopened effect '" .. name .. "' at position " .. pos)
		end
		tokens[#tokens + 1] = { type = "pop", name = name }
	else
		local name, rest = content:match("^([%w_]+)(.*)$") --[[@as string?]]
		if not name then
			error("Invalid tag name at position " .. pos)
		end
		assert(rest)

		if imagesRegistry[name] then
			local scale = 1
			rest = rest:match("^%s*(.-)%s*$") --[[@as string]]
			if #rest > 0 then
				local v = rest:match("^scale=(%-?%d+%.?%d*)$") --[[@as string?]]
				if v then
					---@diagnostic disable-next-line: cast-local-type
					scale = tonumber(v)

					if not scale then
						error("Invalid scale argument at position " .. pos)
					end
				else
					error("Invalid image argument at position " .. pos)
				end
			end
			tokens[#tokens + 1] = { type = "image", name = name, scale = scale }
		elseif effectsRegistry[name] then
			local args = {}
			local p = 1
			while p <= #rest do
				local k, v, nextP = rest:match("^%s+([%w_]+)=(%-?%d+%.?%d*)()", p)
				---@cast nextP integer
				if k then
					args[k] = tonumber(v)
					p = nextP
				else
					local left = rest:sub(p):match("^%s*(.*)$")
					if #left > 0 then
						error("Invalid effect argument at position " .. pos)
					end
					break
				end
			end
			openEffects[#openEffects + 1] = name
			tokens[#tokens + 1] = { type = "push", name = name, args = args }
		else
			error("Unknown image or effect '" .. name .. "' at position " .. pos)
		end
	end
end

---Parse text into tokens.
---@param text string
---@return richtext.ParsedText
function RichText.parse(text)
	---@type richtext.ParsedToken[]
	local tokens = {}
	local pos = 1
	local len = #text
	---@type string[]
	local currentText = {}
	local openEffects = {}
	local currentIndex = 1

	local function flushText()
		if #currentText > 0 then
			local t = table.concat(currentText)
			tokens[#tokens + 1] = { type = "text", content = t, index = currentIndex }
			currentIndex = currentIndex + utf8.len(t)
			currentText = {}
		end
	end

	while pos <= len do
		local c = text:sub(pos, pos)
		if c == "{" then
			if text:sub(pos + 1, pos + 1) == "{" then
				currentText[#currentText + 1] = "{"
				pos = pos + 2
			else
				flushText()
				local closePos = text:find("}", pos + 1, true)
				if not closePos then
					error("Incomplete tag at position " .. pos)
				end

				local content = text:sub(pos + 1, closePos - 1)
				if #content == 0 then
					error("Empty tag at position " .. pos)
				end

				handleTag(content, pos, tokens, openEffects)
				if tokens[#tokens].type == "image" then
					tokens[#tokens].index = currentIndex
					currentIndex = currentIndex + 1
				end
				pos = closePos + 1
			end
		elseif c == "}" then
			if text:sub(pos + 1, pos + 1) == "}" then
				currentText[#currentText + 1] = "}"
				pos = pos + 2
			else
				currentText[#currentText + 1] = "}"
				pos = pos + 1
			end
		else
			currentText[#currentText + 1] = c
			pos = pos + 1
		end
	end
	flushText()

	-- Implicit close
	for i = #openEffects, 1, -1 do
		tokens[#tokens + 1] = { type = "pop", name = openEffects[i] }
	end

	return setmetatable({ tokens = tokens, origin = text }, ParsedText)
end

---@param text string
local function splitWords(text)
	---@type string[]
	local words = {}
	local last = 1
	for s, e in text:gmatch("()[%s]+()") do
		---@diagnostic disable-next-line: cast-type-mismatch
		---@cast s number
		---@cast e number
		if s > last then
			words[#words + 1] = text:sub(last, s - 1)
		end
		local sep = text:sub(s, e - 1)
		local p = 1
		while p <= #sep do
			local ns, ne = sep:find("\n", p, true)
			if ns then
				if ns > p then
					words[#words + 1] = sep:sub(p, ns - 1)
				end
				words[#words + 1] = "\n"
				p = ne + 1
			else
				words[#words + 1] = sep:sub(p)
				break
			end
		end
		last = e
	end
	if last <= #text then
		words[#words + 1] = text:sub(last)
	end
	return words
end

---Layout the parsed text.
---@param font love.Font
---@param maxWidth number?
---@param align "left"|"center"|"right"?
---@return richtext.TextLayout
function ParsedText:layout(font, maxWidth, align)
	align = align or "left"

	---@type richtext._RichTextCurrentLineInfo[]
	local lines = {}

	---@class richtext._RichTextCurrentLineInfo
	---@field package chunks richtext._RichTextChunkInfo[]
	---@field package width number
	---@field package height number
	local currentLine = {
		chunks = {},
		width = 0,
		height = font:getHeight()
	}
	local activeEffects = {}
	local totalWidth = 0
	local totalHeight = 0

	---@param force boolean?
	local function flushLine(force)
		if #currentLine.chunks > 0 or force then
			table.insert(lines, currentLine)
			totalWidth = math.max(totalWidth, currentLine.width)
			totalHeight = totalHeight + currentLine.height
		end
		currentLine = {
			chunks = {},
			width = 0,
			height = font:getHeight()
		}
	end

	---@class richtext._RichTextChunkInfo
	---@field package text string?
	---@field package image love.Texture?
	---@field package quad love.Quad?
	---@field package scale number?
	---@field package width number
	---@field package height number
	---@field package effects richtext._EffectInfo[]
	---@field package x number
	---@field package y number
	---@field package index integer

	---@param chunk richtext._RichTextChunkInfo
	local function addChunk(chunk)
		if maxWidth and currentLine.width + chunk.width > maxWidth and currentLine.width > 0 then
			-- If it's a space, don't start a new line with it
			if chunk.text and chunk.text:match("^%s+$") then
				return
			end
			flushLine()
		end

		chunk.x = currentLine.width
		table.insert(currentLine.chunks, chunk)
		currentLine.width = currentLine.width + chunk.width
		currentLine.height = math.max(currentLine.height, chunk.height)
	end

	for _, token in ipairs(self.tokens) do
		if token.type == "text" then
			local content = token.content ---@type string
			local words = splitWords(content)
			local wordOffset = 0
			for _, word in ipairs(words) do
				if word == "\n" then
					flushLine(true)
				else
					local w = font:getWidth(word)
					local h = font:getHeight()
					---@type richtext._EffectInfo[]
					local effects = {}
					for i, eff in ipairs(activeEffects) do
						effects[i] = {
							func = effectsRegistry[eff.name].render,
							args = eff.args,
							perCharacter =
								effectsRegistry[eff.name].perCharacter
						}
					end
					addChunk({
						text = word,
						width = w,
						height = h,
						effects = effects,
						index = token.index + wordOffset,
						x = 0,
						y = 0
					})
				end
				wordOffset = wordOffset + utf8.len(word)
			end
		elseif token.type == "image" then
			local imageName = assert(token.name)
			local scale = token.scale or 1
			local imgData = imagesRegistry[imageName]
			local img = imgData.texture
			local quad = imgData.quad
			local w, h
			if quad then
				w, h = select(3, quad:getViewport()) --[[@as number]]
			else
				w, h = img:getDimensions()
			end
			w, h = w * scale, h * scale

			local effects = {}
			for i, eff in ipairs(activeEffects) do
				effects[i] = {
					func = effectsRegistry[eff.name].render,
					args = eff.args,
					perCharacter = effectsRegistry
						[eff.name].perCharacter
				}
			end
			addChunk({
				image = img,
				quad = quad,
				scale = scale,
				width = w,
				height = h,
				effects = effects,
				index = token.index,
				x = 0,
				y = 0,
			})
		elseif token.type == "push" then
			table.insert(activeEffects, { name = token.name, args = token.args })
		elseif token.type == "pop" then
			for i = #activeEffects, 1, -1 do
				if activeEffects[i].name == token.name then
					table.remove(activeEffects, i)
					break
				end
			end
		end
	end
	flushLine()

	-- Final alignment and y positions
	local currentY = 0
	local realMaxWidth = maxWidth or totalWidth
	for _, line in ipairs(lines) do
		local offsetX = 0
		if align == "center" then
			offsetX = (realMaxWidth - line.width) / 2
		elseif align == "right" then
			offsetX = realMaxWidth - line.width
		end

		for _, chunk in ipairs(line.chunks) do
			chunk.x = chunk.x + offsetX
			-- Vertically center images only, text stays top-aligned
			if chunk.image then
				chunk.y = currentY + (line.height - chunk.height) / 2
			else
				chunk.y = currentY
			end
		end
		currentY = currentY + line.height
	end

	return setmetatable({
		lines = lines,
		width = totalWidth,
		height = totalHeight,
		lineCount = #lines,
		font = font -- Store font for drawing
	}, TextLayout)
end

---Get the width of the layout.
---@return number
function TextLayout:getWidth()
	return self.width
end

---Get the height of the layout.
---@return number
function TextLayout:getHeight()
	return self.height
end

---Get the wrap metrics.
---@return number, number
function TextLayout:getWrap()
	return self.width, self.lineCount
end

---@param textOrDrawable string|love.Texture
---@param font love.Font
---@param x number
---@param y number
---@param scale number
---@param quad love.Quad?
local function baseRenderer(textOrDrawable, font, x, y, scale, quad)
	if type(textOrDrawable) == "string" then
		love.graphics.print(textOrDrawable, font, x, y)
	elseif quad then
		love.graphics.draw(textOrDrawable, quad, x, y, 0, scale, scale)
	else
		love.graphics.draw(textOrDrawable, x, y, 0, scale, scale)
	end
end

---@param context richtext.Context
---@param effIdx integer
---@param tx number
---@param ty number
---@param ttextOrDrawable string|love.Texture
---@param index integer
---@param tquad love.Quad?
---@param font love.Font
---@param effects richtext._EffectInfo[]
---@param numEffects integer
---@param scale number
local function runEffectChain(context, effIdx, tx, ty, ttextOrDrawable, index, tquad, font, effects, numEffects, scale)
	if effIdx > numEffects then
		baseRenderer(ttextOrDrawable, font, tx, ty, scale, tquad)
	else
		local eff = effects[effIdx]
		context.font = font
		context.textOrDrawable = ttextOrDrawable
		context.index = index
		context.quad = tquad

		eff.func(eff.args, tx, ty, context, function(nt, nx, ny, nq)
			runEffectChain(context, effIdx + 1, nx, ny, nt, index, nq or tquad, font, effects, numEffects, scale)
		end)
	end
end

---Draw the layout.
---@param x number
---@param y number
function TextLayout:draw(x, y)
	---@type richtext.Context
	local sharedContext = {
		font = nil,
		textOrDrawable = "",
		index = 0,
		quad = nil
	}

	for _, line in ipairs(self.lines) do
		for _, chunk in ipairs(line.chunks) do
			local cx, cy = x + chunk.x, y + chunk.y

			local effects = chunk.effects
			local numEffects = #effects

			local hasPerChar = false
			for i = 1, numEffects do
				if effects[i].perCharacter then
					hasPerChar = true
					break
				end
			end

			if hasPerChar and chunk.text then
				local charX = cx
				local lastChar = nil
				local charCount = 0
				for _, code in utf8.codes(chunk.text) do
					local char = utf8.char(code)
					if lastChar then
						charX = charX + self.font:getKerning(lastChar, char)
					end
					runEffectChain(sharedContext, 1, charX, cy, char, chunk.index + charCount, nil, self.font, effects, numEffects, chunk.scale)
					charX = charX + self.font:getWidth(char)
					lastChar = char
					charCount = charCount + 1
				end
			else
				runEffectChain(sharedContext, 1, cx, cy, assert(chunk.text or chunk.image), chunk.index, chunk.quad, self.font, effects, numEffects, chunk.scale or 1)
			end
		end
	end
end

return RichText
