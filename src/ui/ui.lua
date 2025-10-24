

---@class ui
local ui = {}



ui.upgradeBoxUI = require(".upgrades.upgrade_box_ui")
ui.upgradeDescriptionUI = require(".upgrades.upgrade_description_ui")



do
local CLICK_BUTTON = 1

---@param richText string
---@param color? objects.Color
---@param x number
---@param y number
---@param w number
---@param h number
function ui.Button(richText, color, x,y,w,h)
	ui.assertUIStarted()
    love.graphics.setColor(1,1,1)

	color = color or objects.Color.WHITE
    if iml.isHovered(x,y,w,h) then
        color:setHSL(color.h,color.s,color.v*0.9)
    end

	local dh = math.floor(h/10)

	-- draw button base:
	local baseCol = objects.Color(color)
	local hue,s,l = baseCol:getHSL()
	baseCol = baseCol:setHSV(hue,s,l*0.7)
	love.graphics.setColor(baseCol)
    ui.jaggedRectangle("fill", 8, x,y+dh,w,h-dh)

	-- draw main button part:
	local dy = 0
	if iml.isClicked(x,y,w,h, CLICK_BUTTON) then
		dy = dh
	end
	love.graphics.setColor(color)
    ui.jaggedRectangle("fill", 4, x,y+dy,w,h-dh)

    love.graphics.setColor(0,0,0)
    richtext.printRichContained(richText, love.graphics.getFont(), x,y+dy,w,h-dh-dy)

    return iml.wasJustClicked(x,y,w,h, CLICK_BUTTON)
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
	love.graphics.polygon(mode, verts)
end


---For debugging purpose only
---@param region layout.Region
---@param mode love.DrawMode?
function ui.debugRegion(region, mode)
	love.graphics.rectangle(mode or "line", region:get())
end



-- For UI global scaling
do

local GLOBAL_SCALE_INCREMENT = 0.25
local globalScaleTransform = love.math.newTransform()
local globalScale = 1
local gw, gh = 800, 600

local function updateGlobalScaleAutomatic()
	local w, h = love.graphics.getDimensions()
	if w ~= gw or h ~= gh then
		local wscale = w / 600
		local hscale = h / 400
		local scale = math.min(wscale, hscale)
		local gscale = math.floor(scale / GLOBAL_SCALE_INCREMENT + 0.5) * GLOBAL_SCALE_INCREMENT
		globalScale = math.max(gscale, 1)
		globalScaleTransform:reset():scale(globalScale)
		gw = w
		gh = h
	end
end

function ui.getUIScaling()
	updateGlobalScaleAutomatic()
	return globalScale
end

function ui.getScaledUIDimensions()
	local w, h = love.graphics.getDimensions()
	local s = ui.getUIScaling()
	return w / s, h / s
end

function ui.getUIScalingTransform()
	updateGlobalScaleAutomatic()
    return globalScaleTransform
end

---@return number
---@return number
function ui.getMouse()
    return globalScaleTransform:inverseTransformPoint(love.mouse.getPosition())
end

end


local uiPushed = false

function ui.startUI()
	assert(not uiPushed, "attempt to call startUI twice")
	uiPushed = true
	love.graphics.push()
	local t = ui.getUIScalingTransform()
	love.graphics.replaceTransform(t)
	iml.pushTransform(t)
end

function ui.endUI()
	assert(uiPushed, "attempt to call endUI before startUI")
	uiPushed = false
	iml.popTransform()
	love.graphics.pop()
end

function ui.assertUIStarted()
	if not uiPushed then
		error("Not in UI context!", 2)
	end
end

return ui
