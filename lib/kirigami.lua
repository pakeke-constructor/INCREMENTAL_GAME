--[[
Kirigami Library
https://github.com/pakeke-constructor/Kirigami

MIT LICENSE
Copyright (c) Oliver Garrett (pakeke-constructor)
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

---@class layout.Region
---@field x number
---@field y number
---@field w number
---@field h number
local Region = {}

local Region_mt = {__index = Region}



local function getXYWH(x,y,w,h)
    -- allows for passing in a region as first argument.
    -- if a region is passed in, takes x,y,w,h from the region.
    if type(x) == "number" then
        return x,y,w,h
    else
        assert(type(x) == "table", "Expected x,y,w,h numbers")
        local region = x
        return region:get()
    end
end


local function max0(v)
    return math.max(v,0)
end

local function getWH(w,h)
    -- allows for passing in a region as first argument.
    -- if a region is passed in, takes w,h from the region.
    if type(w) == "number" then
        return max0(w), max0(h)
    else
        assert(type(w) == "table", "Expected w,h numbers")
        local region = w
        local _,_, ww,hh = region:get()
        return ww,hh
    end
end



--- Creates a new region
---@param x number?
---@param y number?
---@param w number?
---@param h number?
---@return layout.Region
local function newRegion(x,y,w,h)
    if not x then
        -- default region is empty
        x,y,w,h = 0,0,0,0
    end
    x,y,w,h = getXYWH(x,y,w,h)
    return setmetatable({
        x = x,
        y = y,
        w = math.max(w, 0),
        h = math.max(h, 0)
    }, Region_mt)
end



local unpack = unpack or table.unpack
-- other lua version compat ^^^






local function getRatios(...)
    -- gets ratios from a vararg-list of numbers
    local ratios = {...}
    local len = #ratios
    local sum = 0
    if len <= 0 then
        error("No numbers passed in!")
    end

	for _, v in ipairs(ratios) do
        -- collect ratios
        assert(type(v) == "number", "Arguments need to be numbers")
        sum = sum + v
	end

    for i=1, len do
        -- normalize region ratios:
        ratios[i] = ratios[i] / sum
    end
    return ratios
end

--- Splits a region vertically
---@param ... number
---@return layout.Region ...
function Region:splitVertical(...)
    --[[
        splits a region vertically.
        For example:  

        region:splitVertical(0.1, 0.9)

        This code ^^^ splits a region into two horizontally-lying
        rectangles; one at the top, taking up 10%, and one at bottom taking 90%.
    ]]
    local regions = getRatios(...)
    local accumY = self.y
    for i=1, #regions do
        local ratio = regions[i]
        local y, h = accumY, self.h*ratio
        regions[i] = newRegion(self.x, y, self.w, h)
        accumY = accumY + h
    end
    return unpack(regions)
end


--- Splits a region vertically
---@param ... number
---@return layout.Region ...
function Region:splitHorizontal(...)
    --[[
        Same as vertical, but in other direction
    ]]
    local regions = getRatios(...)
    -- 0.1  0.8  0.1
    -- |.|........|.|
    local accumX = self.x
    for i=1, #regions do
        local ratio = regions[i]
        local x, w = accumX, self.w*ratio
        regions[i] = newRegion(x, self.y, w, self.h)
        accumX = accumX + w
    end
    return unpack(regions)
end




--- Splits a region into a grid
---@param width number
---@param height number
---@return layout.Region[]
function Region:grid(width, height)
    local w, h = self.w/width, self.h/height
    local regions = {}

    for iy=0, height-1 do
        for ix=0, width-1 do
            local x = self.x + w*ix
            local y = self.y + h*iy
            local r = newRegion(x,y,w,h)
            table.insert(regions, r)
        end
    end

    return regions
end


--- Splits a region into rows
---@param rows number
---@return layout.Region
function Region:rows(rows)
  return self:grid(rows, 1)
end


--- Splits a region into columns
---@param columns number
---@return layout.Region
function Region:columns(columns)
  return self:grid(1, columns)
end


local function pad(self, top, left, bot, right)
    local dw = left + right
    local dh = top + bot

    return newRegion(
        self.x + left,
        self.y + top,
        self.w - dw,
        self.h - dh
    )
end



--- Returns a new padded region; padded by direct numbers
---@param left number
---@param top number
---@param right number
---@param bot number
---@overload fun(self:layout.Region, horz:number, vert:number):layout.Region
---@overload fun(self:layout.Region, unit:number):layout.Region
---@return layout.Region
function Region:padUnit(left, top, right, bot)
    --[[
        Creates an inner region, with padding on sides.

        :padUnit(v) -- pads all sides by v.
        :padUnit(a,b) -- pads  by `a`, and y-sides by `b`.
        :padUnit(top,left,bot,right) -- pads all sides independently
    ]]
    assert(type(left) == "number", "need a number for padding")
    top = top or left -- If top not specified, defaults to left.
    bot = bot or top -- defaults to top
    right = right or left -- defaults to left
    return pad(self, top, left, bot, right)
end


local function max1(x)
    return math.min(1, x)
end

--- Returns a new padded region; padded by ratio
--- For example, :padRatio(0.1) will give 10% padding to ALL sides; 
--- (picking the smallest side as a padder)
--- :padRatio(1) will give 100% padding, and make the region disappear.
--- :padRatio(0.2, 0.5) gives 20% padding to left/right, 50% padding to top/bot
---@param left number
---@param top number
---@param right number
---@param bot number
---@overload fun(self:layout.Region,pad:number):layout.Region
---@return layout.Region
function Region:padRatio(left, top, right, bot)
    --[[
        Pads a region, percentage wise.
        For example, :padRatio(0.1) will give 10% padding to ALL sides.
    ]]
    assert(type(left) == "number", "need a number for padding")
    local minWH = math.min(self.w, self.h)
    local ratioH = ((top or bot) and self.h) or minWH
    local ratioW = (right and self.w) or minWH
    left = max1(left)
    top = max1(top or left)
    bot = max1(bot or top)
    right = max1(right or left)

    left, right = left*ratioW/2, right*ratioW/2
    top, bot = top*ratioH/2, bot*ratioH/2

    return pad(self, top, left, bot, right)
end




--[[
    shrinks a region to width/height
]]
---@param width number
---@param height number
function Region:shrinkTo(width, height)
    width, height = getWH(width, height)
    local w = math.min(width, self.w)
    local h = math.min(height, self.h)
    if w ~= self.w or h ~= self.h then
        return newRegion(self.x,self.y, w,h)
    end
    return self
end



--- Gets the scale such that a region fits (width, height) bounds.
---@param width number
---@param height number
---@overload fun(self:layout.Region,region:layout.Region):number
---@return number
function Region:getScaleToFit(width, height)
    --[[
    ]]
    width, height = getWH(width, height)
    local w, h = self.w, self.h
    local scaleX = width / w
    local scaleY = height / h

    -- we scale by the smallest value.
    -- this ensures that the result fits within the bounds
    local scale = math.min(scaleX, scaleY)
    return scale
end



--- Shrinks a region, reducing its width XOR height 
--- such that it fits a given ratio
---@param ratioW number
---@param ratioH number
---@return layout.Region
function Region:shrinkToAspectRatio(ratioW, ratioH)
    local ratioRegion = newRegion(0,0, ratioW, ratioH)
    ratioRegion = ratioRegion:scaleToFit(self.w, self.h)
    return ratioRegion:center(self)
end




--- Returns a new region that is scaled to fit certain boundaries
---@param width number
---@param height number
---@return layout.Region, number
function Region:scaleToFit(width, height)
    local scale = self:getScaleToFit(width, height)
    local w, h = self.w, self.h
    return newRegion(self.x, self.y, w*scale, h*scale), scale
end



--- Returns a new scaled region
---@param sx number
---@param sy? number
---@return layout.Region
function Region:scale(sx, sy)
    sx = sx
    sy = sy or sx
    return newRegion(self.x, self.y, self.w*sx, self.h*sy)
end

--- Directly sets the view of a region
---@param x? number
---@param y? number
---@param w? number
---@param h? number
---@return layout.Region
function Region:set(x,y,w,h)
    return newRegion(
        x or self.x,
        y or self.y,
        w or self.w,
        h or self.h
    )
end




function Region:centerX(other)
    --[[
        centers a region horizontally w.r.t other
    ]]
    local targX, _ = self:getCenter()
    local currX, _ = other:getCenter()
    local dx = currX - targX
    
    return newRegion(self.x+dx, self.y, self.w, self.h)
end


function Region:centerY(other)
    --[[
        centers a region vertically w.r.t other
    ]]
    local _, targY = self:getCenter()
    local _, currY = other:getCenter()
    local dy = currY - targY
    
    return newRegion(self.x, self.y+dy, self.w, self.h)
end


function Region:center(other)
    return self
        :centerX(other)
        :centerY(other)
end


local function isDifferent(self, x,y,w,h)
    -- check for efficiency reasons
    return self.x ~= x
        or self.y ~= y
        or self.w ~= w
        or self.h ~= h
end


local function getEnd(self)
    return self.x+self.w, self.y+self.h
end


--- Intersects 2 regions.
--- opposite of `union`.
--- useful for putting a MAXIMUM on region size
---@param other any
---@return layout.Region
function Region:intersection(other)
    --[[
    
        :intersection is useful for putting a MAXIMUM on region size
    ]]
    local x,y,endX,endY
    x = math.max(other.x, self.x)
    y = math.max(other.y, self.y)
    endX, endY = getEnd(self)
    local endX2, endY2 = getEnd(other)
    endX = math.min(endX, endX2)
    endY = math.min(endY, endY2)
    local w, h = math.max(0,endX-x), math.max(endY-y,0)

    if isDifferent(self, x,y,w,h) then
        return newRegion(x,y,w,h)
    end
    return self
end


--- Takes the union between 2 regions
--- opposite of `intersection`
--- :union is useful for putting a MINIMUM on region size.
--- @param other layout.Region
--- @return layout.Region
function Region:union(other)
    --[[
        Takes the union between 2 regions
        opposite of `intersection`

        :union is useful for putting a MINIMUM on region size.
    ]]
    local x,y,endX,endY
    x = math.min(other.x, self.x)
    y = math.min(other.y, self.y)
    endX, endY = getEnd(self)
    local endX2, endY2 = getEnd(other)
    endX = math.max(endX, endX2)
    endY = math.max(endY, endY2)
    local w, h = math.max(0,endX-x), math.max(endY-y,0)

    if isDifferent(self, x,y,w,h) then
        return newRegion(x,y,w,h)
    end
    return self
end


function Region:clampInside(other)
    --[[
        moves a region position such that it resides
        inside of `other`.
        Does not change the w,h values.
    ]]
    local x,y
    x, y = self.x, self.y
    local endX2, endY2 = getEnd(other)
    x = math.min(x, endX2 - self.w)
    y = math.min(y, endY2 - self.h)
    x = math.max(other.x, x)
    y = math.max(other.y, y)
    return newRegion(x,y,self.w,self.h)
end








function Region:moveUnit(ox, oy)
    ox = ox or 0
    oy = oy or 0
    if ox ~= 0 or oy ~= 0 then
        return newRegion(self.x+ox, self.y+oy, self.w, self.h)
    end
    return self
end

function Region:moveRatio(ratioX, ratioY)
    local w,h = self:size()
    local ox = (ratioX or 0) * w
    local oy = (ratioY or 0) * h
    return self:moveUnit(ox, oy)
end


---@param r2 layout.Region 
---@return layout.Region
function Region:attachToTopOf(r2)
    local top = r2.y
    local top_minus_h = top - self.h
    return self:set(nil, top_minus_h, nil, nil)
end

---@param r2 layout.Region 
---@return layout.Region
function Region:attachToBottomOf(r2)
    local bottom = r2.y + r2.h
    return self:set(nil, bottom, nil, nil)
end


---@param r2 layout.Region 
---@return layout.Region
function Region:attachToLeftOf(r2)
    local left = r2.x
    local left_minus_w = left - self.w
    return self:set(left_minus_w, nil, nil, nil)
end


---@param r2 layout.Region 
---@return layout.Region
function Region:attachToRightOf(r2)
    local right = r2.x + r2.w
    return self:set(right, nil, nil, nil)
end





function Region:exists()
    -- returns true if a region exists
    -- (ie its height and width are > 0)
    return self.w > 0 and self.h > 0 
end



---@return number,number
function Region:getCenter()
    -- returns (x,y) position of center of region
    return (self.x + self.w/2), (self.y + self.h/2)
end

---@return number,number,number,number
function Region:get()
    return self.x,self.y, self.w,self.h
end

---@return number,number
function Region:size()
    return self.w,self.h
end


function Region:containsCoords(xx,yy)
    local x,y,w,h = self:get()
    return x<=xx and y<=yy and xx<=(x+w) and yy<=(y+h)
end


return newRegion



