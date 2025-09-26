

---@class ui
local ui = {}


---@param richText string
---@param x number
---@param y number
---@param w number
---@param h number
function ui.Button(richText, x,y,w,h)
    love.graphics.setColor(1,1,1)
    if iml.isHovered(x,y,w,h) then
        love.graphics.setColor(0.8,0.8,0.8)
    end
    love.graphics.rectangle("fill", x,y,w,h)
    love.graphics.setColor(0,0,0)
    richtext.printRichContained(richText, love.graphics.getFont(), x,y,w,h)
    return iml.wasJustClicked(x,y,w,h)
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
---@param r number?
---@param q integer?
---@param exttab number[]?
function ui.jaggedRectangle(x, y, w, h, r, q, exttab)
	r = r or 0
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


return ui
