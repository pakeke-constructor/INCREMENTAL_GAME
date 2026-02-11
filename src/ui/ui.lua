
local n9slice = require("src.modules.n9slice.n9slice")

---@class ui
local ui = {}

local lg = love.graphics


ui.upgradeDescriptionUI = require(".upgrades.upgrade_description_ui")



do


---@param richTxt string
---@param col1 number[]|objects.ColorObject
---@param col2 number[]|objects.ColorObject
---@param region kirigami.Region
---@return boolean
function ui.Button(richTxt, col1,col2, region)
	return ui.CustomButton(function (xx,yy,ww,hh)
		local font = g.getSmallFont(16)
    	richtext.printRichContained(richTxt, font, xx,yy,ww,hh)
	end, col1,col2, region)
end



---@param richTxt string
---@param region kirigami.Region
---@return boolean
function ui.DefaultButton(richTxt, region)
	local c = g.COLORS
	return ui.CustomButton(function (xx,yy,ww,hh)
		local font = g.getSmallFont(16)
    	richtext.printRichContained(richTxt, font, xx,yy,ww,hh)
	end, c.BUTTON_FADE_1, c.BUTTON_FADE_2, region)
end




---@param drawLabel fun(x:number,y:number,w:number,h:number)
---@param col1 objects.Color
---@param col2 objects.Color
---@param region kirigami.Region
function ui.CustomButton(drawLabel, col1, col2, region)
	ui.assertUIStarted()

	love.graphics.setColor(1,1,1)
	if iml.isHovered(region:get()) then
		helper.gradientRect("horizontal", col1,col1, region:padUnit(4):get())
	else
		helper.gradientRect("horizontal", col1,col2, region:padUnit(4):get())
	end

	if iml.wasJustHovered(region:get()) then
		g.playUISound("ui_tick", 1.6,0.35, 0,0)
	end

	ui.drawPanel(region:get())
	drawLabel(region:padRatio(0.4,0.2):get())
	if iml.wasJustClicked(region:get()) then
		g.playUISound("ui_click_basic", 1.4,0.8)
		return true
	end
	return false
end





end





---@param value number
---@param qpx integer
local function quantize(value, qpx)
	if value > 0 then
		return math.floor((value + 0.5) / qpx) * qpx
	else
		return math.floor((value - 0.5) / qpx) * qpx
	end
end

---@param x number
---@param y number
---@param r number
---@param a1 number
---@param a2 number
---@param q integer?
local function quantizedArc(x, y, r, a1, a2, q)
	q = q or 1
	local hash = {} -- coords, to prevent dupes
	local vertices = {}
	local targetAngle = (a2 - a1)
	local segments = math.floor(r * math.deg(targetAngle))

	for i = 0, segments do
		local a = a1 + i * targetAngle / segments
		local px = quantize(x + math.cos(a) * r, q)
		local py = quantize(y + math.sin(a) * r, q)
		local hpos = string.format("%d|%d", px, py)

		if not hash[hpos] then
			vertices[#vertices+1] = px
			vertices[#vertices+1] = py
			hash[hpos] = true
		end
	end

	return vertices
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param radius number?
---@param q integer?
---@param exttab number[]?
local function jaggedRectangleVerts(x, y, w, h, radius, q, exttab)
	local r = radius or 0
	q = q or 1
	if r == 0 then
		return {
			x, y,
			x + w, y,
			x + w, y + h,
			x, y + h
		}
	end

	local arc = quantizedArc(0, 0, r, -math.pi, -math.pi/2, q)
	local vertices = exttab or {}
	-- Top left corner
	for i = 1, #arc, 2 do
		vertices[#vertices+1] = arc[i] + x + r + q
		vertices[#vertices+1] = arc[i + 1] + y + r + q
	end
	-- Top right corner
	for i = #arc - 1, 1, -2 do
		-- Flip the arc along the x axis
		vertices[#vertices+1] = -arc[i] + x + w - r - q
		vertices[#vertices+1] = arc[i + 1] + y + r + q
	end
	-- Bottom right corner
	for i = 1, #arc, 2 do
		-- Flip the arc along the x and y axis
		vertices[#vertices+1] = -arc[i] + x + w - r - q
		vertices[#vertices+1] = -arc[i + 1] + y + h - r - q
	end
	-- Bottom left corner
	for i = #arc - 1, 1, -2 do
		-- Flip the arc along the y axis
		vertices[#vertices+1] = arc[i] + x + r + q
		vertices[#vertices+1] = -arc[i + 1] + y + h - r - q
	end
	return vertices
end



---@param mode love.DrawMode
---@param x number
---@param y number
---@param w number
---@param h number
---@param radius number?
function ui.jaggedRectangle(mode, radius, x,y,w,h)
	-- local quantize = 4
	local verts = jaggedRectangleVerts(x,y,w,h,radius, 2)
	lg.polygon(mode, verts)
end


---For debugging purpose only
---@param region kirigami.Region
---@param mode love.DrawMode?
function ui.debugRegion(region, mode)
	lg.rectangle(mode or "line", region:get())
end


local singleColorPanel = nil
---@param x number
---@param y number
---@param w number
---@param h number
function ui.drawSingleColorPanel(x, y, w, h)
	singleColorPanel = singleColorPanel or n9slice.new {
		image = g.getAtlas(),
		padding = 4,
		quad = g.getImageQuad("single_color_ui_panel")
	}
	return singleColorPanel:draw(x, y, w, h)
end


local simpleUIPanel = nil
---@param x number
---@param y number
---@param w number
---@param h number
function ui.drawPanel(x, y, w, h)
	simpleUIPanel = simpleUIPanel or n9slice.new {
		image = g.getAtlas(),
		padding = 9,
		quad = g.getImageQuad("simple_ui_panel")
	}
	return simpleUIPanel:draw(x, y, w, h)
end


---@param col objects.Color
---@param val number Value multiplier for HSV
local function multiplyHSVValue(col, val)
	local a = select(4, col:getRGBA())
	local h, s, v = col:getHSV()
	local nr, ng, nb = objects.Color.HSVtoRGB(h, s, v * val)
	return objects.Color(nr, ng, nb, a)
end

---@param key string
---@param direction "horizontal"|"vertical"
---@param slidercol objects.Color
---@param currentsegment integer Current value of the slider (from 1 to `segments` inclusive)
---@param segments integer Max value of the sliders (inclusive).
---@param slidersize number|nil (1 = max size, 0 is not valid, nil = `1 / segments`)
---@param reg kirigami.Region
---@return integer currentsegment Current segment (1 to `segments` both inclusive)
function ui.Slider(key, direction, slidercol, currentsegment, segments, slidersize, reg)
	assert(currentsegment >= 1, "invalid current segment value")
	assert(segments > 0, "invalid segment count")
	slidersize = slidersize or (1 / segments)
	assert(slidersize > 0 and slidersize <= 1, "invalid slider size")

	local x, y, w, h = reg:get()
	local mousepos = nil
	local drag = iml.consumeDrag(key, x, y, w, h, 1)
	if drag then
		mousepos = {drag.endX, drag.endY}
	elseif iml.isClicked(x, y, w, h, 1, key) then
		mousepos = {iml.getTransformedPointer()}
	end
	local s = helper.clamp(currentsegment, 1, segments)

	-- Select slider color and handle drags
	local curslidercol = slidercol
	if mousepos then
		curslidercol = multiplyHSVValue(slidercol, 0.5)
		local mx, my = mousepos[1], mousepos[2]

		if direction == "horizontal" then
			local pos = helper.clamp(mx - x, 0, w)
			local segmentsize = w / segments
			s = helper.clamp(math.floor(pos / segmentsize), 0, segments - 1) + 1
		elseif direction == "vertical" then
			local pos = helper.clamp(my - y, 0, h)
			local segmentsize = h / segments
			s = helper.clamp(math.floor(pos / segmentsize), 0, segments - 1) + 1
		end
	elseif iml.isHovered(x, y, w, h, key) then
		curslidercol = multiplyHSVValue(slidercol, 0.75)
	end

	-- Draw slider handle
	love.graphics.setColor(curslidercol)
	if direction == "horizontal" then
		local sliderwidth = w * slidersize
		local slideroff = segments > 1 and ((s - 1) * (w - sliderwidth) / (segments - 1)) or 0
		love.graphics.rectangle("fill", x + slideroff, y, w * slidersize, h)
	elseif direction == "vertical" then
		local sliderheight = h * slidersize
		local slideroff = segments > 1 and ((s - 1) * (h - sliderheight) / (segments - 1)) or 0
		love.graphics.rectangle("fill", x, y + slideroff, w, sliderheight)
	end

	return s
end


---@param color objects.Color
---@param region kirigami.Region
---@param checked boolean
function ui.Checkbox(color, region, checked)
	local x, y, w, h = region:get()

	if iml.isClicked(x, y, w, h) then
		color = multiplyHSVValue(color, 0.5)
	elseif iml.isHovered(x, y, w, h) then
		color = multiplyHSVValue(color, 0.75)
	end


	love.graphics.setColor(color)
	love.graphics.rectangle("fill", x, y, w, h)

	if iml.wasJustClicked(x, y, w, h) then
		checked = not checked
	end

	if checked then
		love.graphics.setColor(0, 0, 0, color[4])
		-- Draw cross
		love.graphics.line(x + 1, y + 1, x + w - 2, y + h - 2)
		love.graphics.line(x + w - 2, y + 1, x + 1, y + h - 2)
	end

	return checked
end



---@class ui.TextBox: objects.Class
---@field txt string
---@field isFocused boolean
local TextBox = objects.Class("ui:TextBox")

function TextBox:init(text, isFocused)
	self.txt = text or ""
	self.isFocused = not not isFocused
end

function TextBox:reset()
	self.txt = ""
end

---@param reg kirigami.Region
function TextBox:draw(reg)
	if self.isFocused then
		if love.keyboard.isDown("return") then
			self.isFocused = false
		else
			local txt = (iml.consumeText() or "")
			self.txt = self.txt .. txt
		end
	end
	if iml.wasJustClicked(reg:get()) then
		self.isFocused = not self.isFocused
		if self.isFocused then
			self.txt = ""
		end
	end
	if self.isFocused then
		if math.floor(love.timer.getTime()*2)%2==0 then
			lg.setColor(1,0.9,0.8)
		else
			lg.setColor(0.8,0.7,0.6)
		end
	else
		lg.setColor(1,0.9,0.8)
	end
	lg.rectangle("fill", reg:get())
	lg.setColor(0,0,0)
	lg.rectangle("line", reg:get())
	local font=g.getSmallFont(16)
	lg.setColor(0,0,0)
	richtext.printRichContained(self.txt,font,reg:get())
	lg.setColor(1,1,1)
end

---@return ui.TextBox
function ui.newTextBox()
	return TextBox()
end


-- For UI global scaling
do

local GLOBAL_SCALE_INCREMENT = 0.25
local globalScaleTransform = love.math.newTransform()
local globalScale = 1
local gx, gy, gw, gh = 0, 0, 1, 1
local rootKirigami = Kirigami(gx, gy, gw, gh)
local rootKirigamiUnsafe = Kirigami(gx, gy, gw, gh)

local function getUIScaledSafeArea()
	gx, gy, gw, gh = love.window.getSafeArea()
	return gx / globalScale, gy / globalScale, gw / globalScale, gh / globalScale
end

local function recalculateEverything()
	local w,h = lg.getDimensions()
	local wscale = w / 600
	local hscale = h / 400
	local scale = math.min(wscale, hscale)
	local gscale = math.floor(scale / GLOBAL_SCALE_INCREMENT + 0.5) * GLOBAL_SCALE_INCREMENT
	globalScale = math.max(gscale, 1)
	globalScaleTransform:reset():scale(globalScale)

	-- Recalculate region
	gx, gy, gw, gh = love.window.getSafeArea()
	rootKirigamiUnsafe = Kirigami(0, 0, w / globalScale, h / globalScale)
	rootKirigami = Kirigami(getUIScaledSafeArea())
end


local function updateGlobalScaleAutomatic()
	local x, y, w, h = love.window.getSafeArea()
	if x ~= gx or y ~= gy or w ~= gw or h ~= gh then
		recalculateEverything()
	end
end


local function ensureRootKirigamiCorrect()
	updateGlobalScaleAutomatic()
	local x, y, w, h = getUIScaledSafeArea()
	local fw, fh = ui.getScaledUIDimensions()
	if
		rootKirigami.x ~= x or
		rootKirigami.y ~= y or
		rootKirigami.w ~= w or
		rootKirigami.h ~= h or
		rootKirigamiUnsafe.x ~= 0 or
		rootKirigamiUnsafe.y ~= 0 or
		rootKirigamiUnsafe.w ~= fw or
		rootKirigamiUnsafe.h ~= fh
	then
		-- oops, its invalid somehow! recalculate
		recalculateEverything()
	end
end

function ui.getUIScaling()
	updateGlobalScaleAutomatic()
	return globalScale
end

---Note: If you want to use this for UI placement, you may want `ui.getScreenRegion` instead.
function ui.getScaledUIDimensions()
	local w, h = lg.getDimensions()
	local s = ui.getUIScaling()
	return w / s, h / s
end

function ui.getUIScalingTransform()
	updateGlobalScaleAutomatic()
    return globalScaleTransform
end

---Return whole safe area, scaled by UI. Meant to be used in UI drawing code.
function ui.getScreenRegion()
	ensureRootKirigamiCorrect()
	return rootKirigami
end

---Return whole screen dimensions, scaled by UI. Meant to be used in UI drawing code where
---using safe area is insufficient.
function ui.getFullScreenRegion()
	return rootKirigamiUnsafe
end

---@return number
---@return number
function ui.getMouse()
    return globalScaleTransform:inverseTransformPoint(love.mouse.getPosition())
end

---@param reg kirigami.Region
function ui.regionToScreenspace(reg)
	local x, y, w, h = reg:get()
	local x2, y2 = x + w, y + h
	local px1, py1 = globalScaleTransform:transformPoint(x, y)
	local px2, py2 = globalScaleTransform:transformPoint(x2, y2)
	return px1, py1, px2 - px1, py2 - py1
end

end


local uiPushed = false

function ui.startUI()
	assert(not uiPushed, "attempt to call startUI twice")
	prof_push("ui")
	uiPushed = true
	lg.push()
	local t = ui.getUIScalingTransform()
	lg.replaceTransform(t)
	iml.pushTransform(t)
end

local simulatedSafeArea = pcall(string.dump, love.window.getSafeArea)

function ui.endUI()
	assert(uiPushed, "attempt to call endUI before startUI")
	uiPushed = false

    if simulatedSafeArea then
        ui.debugRegion(ui.getScreenRegion())
    end

	iml.popTransform()
	lg.pop()
	prof_pop() -- prof_push("ui")
end

function ui.assertUIStarted()
	if not uiPushed then
		error("Not in UI context!", 2)
	end
end

return ui
