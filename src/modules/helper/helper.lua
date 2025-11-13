

---@class _g.helper
local helper = {}




---@param a number
---@param b number
---@param t number
---@return number
function helper.lerp(a, b, t)
    return (1 - t) * a + t * b
end



---@generic n:number
---@param val n
---@param min n
---@param max n
---@return n
function helper.clamp(val, min, max)
    min, max = math.min(min, max), math.max(min, max)
    return math.min(math.max(val, min), max)
end




---@param x table
---@return table
function helper.shallowCopy(x)
    local res = {}
    for k,v in pairs(x) do
        res[k]=v
    end
    return res
end




---@param t any[]
function helper.shuffle(t)
    for i=#t,2,-1 do
        local j = love.math.random(i)
        t[i],t[j] = t[j],t[i]
    end
end



---Randomly picks an item from the list.
---If you don't need weighted pick, consider using `helper.choice` instead.
---@generic T
---@param itemsAndWeights {[1]:T,[2]:number}[] List of items and its weights.
---@param rng love.RandomGenerator? Random number generator to use.
---@return T
function helper.pickWeighted(itemsAndWeights, rng)
    local weightSum = 0

    for _, itemAndWeight in ipairs(itemsAndWeights) do
        assert(itemAndWeight[2] > 0, "weight must be positive larger than 0")
        weightSum = weightSum + itemAndWeight[2]
    end

    local number
    if rng then
        number = rng:random()
    else
        number = math.random()
    end
    number = number * weightSum

    for _, itemAndWeight in ipairs(itemsAndWeights) do
        number = number - itemAndWeight[2]
        if number <= 0 then
            return itemAndWeight[1]
        end
    end

    error("internal error")
end

---@generic T
---@param tab T[] Table to pick elements of.
---@param rng (fun(max:integer):integer)? Function that returns random integer from 1 to `max` both inclusive.
---@return T
function helper.choice(tab, rng)
    rng = rng or love.math.random
    return tab[rng(#tab)]
end




---@param x number
---@param y number
---@param w number
---@param h number
function helper.randomInRegion(x,y,w,h)
    local xx = helper.lerp(x,x+w, love.math.random())
    local yy = helper.lerp(y,y+h, love.math.random())
    return xx, yy
end



-- List of easing functions.
helper.EASINGS = {
    -- linear
    ---@param x number
    linear = function(x) return x end,

    -- in
    ---@param x number
    sineIn = function(x) return 1 - math.cos((x * math.pi) / 2) end,
    -- out
    ---@param x number
    sineOut = function(x) return math.sin((x * math.pi) / 2) end,
    -- inout
    ---@param x number
    sineInOut = function(x) return -(math.cos(math.pi * x) - 1) / 2 end,
    -- out
    ---@param x number
    easeOutBack = function(x)
        local c1 = 1.70158
        local c3 = c1 + 1

        return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2)
    end,
    ---@param x number
    easeInCubic = function(x)
        return x ^ 3
    end
}



---Calls `objects.Color:getRGBA()` then multiply the alpha by the specified value.
---@param color objects.Color
---@param alpha number
function helper.multiplyAlpha(color, alpha)
    local r, g, b, a = color:getRGBA()
    return objects.Color(r, g, b, a * alpha)
end



---@param text string
---@param font love.Font
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
function helper.printTextOutlineSimple(text, font, x, y, r, sx, sy, ox, oy)
    local col = {love.graphics.getColor()}
    -- Draw outline
    love.graphics.setColor(0, 0, 0, col[4])
    for dy = -1, 1 do
        for dx = -1, 1 do
            if not (dx == 0 and dy == 0) then
                love.graphics.print(text, font, x + dx, y + dy, r, sx, sy, ox, oy)
            end
        end
    end
    love.graphics.setColor(col)
    love.graphics.print(text, font, x, y, r, sx, sy, ox, oy)
end



---@param maxRadius number
---@param rng (fun():number)? Function that returns random number from 0 to 1.
function helper.randomPosInCircle(maxRadius, rng)
    rng = rng or love.math.random
    local angle = rng() * 2 * math.pi
    local radius = rng() * maxRadius
    return math.cos(angle) * radius, math.sin(angle) * radius
end



---Calculate length of position relative to (0, 0)
---@param x number
---@param y number
function helper.magnitude(x,y)
    return (x*x + y*y)^0.5
end


---@generic T, U, V
---@param b T
---@param er U
---@param ... V
---@return T
---@return U
---@return V ...
function helper.assert(b,er, ...)
    if not b then
        local t = {...}
        for i,v in ipairs(t)do
            t[i]=tostring(v)
        end
        local str = table.concat(t," ")
        error(tostring(er) .. " " .. str, 3)
    end
    return b,er,...
end


---@param increase integer
---@param startingPercentage integer?
---@return function
function helper.percentageGetter(increase, startingPercentage)
    helper.assert(math.floor(increase) == increase, "Increase must be an integer. E.g. 5%, 10%, etc")
    if startingPercentage then
        helper.assert(math.floor(startingPercentage) == startingPercentage, "startingPercentage must be an integer. E.g. 10%, 20%, etc")
    end

    local function getValues(self, level)
        if startingPercentage then
            return startingPercentage + ((level-1) * increase)
        end
        return level*increase
    end
    return getValues
end


---@param increase number
---@param startingVal number?
---@return function
function helper.valueGetter(increase, startingVal)
    helper.assert(type(increase)=="number","Increase needs to be a number")
    if startingVal then
        helper.assert(type(startingVal)=="number","startingVal needs to be a number")
    end
    local function getValues(self, level)
        if startingVal then
            return startingVal + ((level-1) * increase)
        end
        return level*increase
    end
    return getValues
end


helper.PERCENTAGE_FORMATTER = {"%d%%"}



---Note: Returned tilemap is 2D array in [y][x] order.
---@param imageName string
---@param splitsize integer
function helper.splitTileImage(imageName, splitsize)
    local atlas = g.getAtlas()
    local tilemapQuad = g.getImageQuad(imageName)
    local tx, ty, tw, th = tilemapQuad:getViewport()
    ---@type love.Quad[][]
    local tilemap = {}
    for y = 0, th - 1, splitsize do
        local tmap = {}

        for x = 0, tw - 1, splitsize do
            tmap[#tmap+1] = love.graphics.newQuad(x + tx, y + ty, splitsize, splitsize, atlas)
        end

        tilemap[#tilemap+1] = tmap
    end

    return tilemap
end



---@param int integer
---@return integer
function helper.hashInteger(int)
    int = int % 4294967296
    for i = 1, 3 do
        int = (int * 214013 + 2531011) % 4294967296
    end
    return int
end



---@param x number
function helper.sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    end
    return 0
end



---@param dir "horizontal"|"vertical"
---@param ... objects.Color
---@return love.graphics.Mesh
function helper.newGradientMesh(dir, ...)
    -- Check for direction
    local isHorizontal = true
    if dir == "vertical" then
        isHorizontal = false
    elseif dir ~= "horizontal" then
        error("bad argument #1 to 'gradient' (invalid value)", 2)
    end

    -- Check for colors
    local colorLen = select("#", ...)
    if colorLen < 2 then
        error("color list is less than two", 2)
    end

    -- Generate mesh
    local meshData = {}
    if isHorizontal then
        for i = 1, colorLen do
            local color = select(i, ...)
            ---@cast color objects.Color
            local x = (i - 1) / (colorLen - 1)

            meshData[#meshData + 1] = {x, 1, x, 1, color:getRGBA()}
            meshData[#meshData + 1] = {x, 0, x, 0, color:getRGBA()}
        end
    else
        for i = 1, colorLen do
            local color = select(i, ...)
            ---@cast color objects.Color
            local y = (i - 1) / (colorLen - 1)

            meshData[#meshData + 1] = {1, y, 1, y, color:getRGBA()}
            meshData[#meshData + 1] = {0, y, 0, y, color:getRGBA()}
        end
    end

    -- Resulting Mesh has 1x1 image size
    return love.graphics.newMesh(meshData, "strip", "static")
end


do
local mesh = nil


function helper.gradientRect(dir, col1, col2, x,y,w,h)
    local isHorizontal = true
    if dir == "vertical" then
        isHorizontal = false
    elseif dir ~= "horizontal" then
        error("bad argument #1 to 'gradient' (invalid value)", 2)
    end

    mesh = mesh or love.graphics.newMesh(4, "fan")
    local r1, g1, b1, a1 = col1[1], col1[2], col1[3], col1[4]
    local r2, g2, b2, a2 = col2[1], col2[2], col2[3], col2[4]

    if isHorizontal then
        mesh:setVertex(1, 0, 0, 0, 0, r1, g1, b1, a1)
        mesh:setVertex(2, 0, 1, 0, 1, r1, g1, b1, a1)
        mesh:setVertex(3, 1, 1, 1, 1, r2, g2, b2, a2)
        mesh:setVertex(4, 1, 0, 1, 0, r2, g2, b2, a2)
    else
        mesh:setVertex(1, 0, 0, 0, 0, r1, g1, b1, a1)
        mesh:setVertex(2, 0, 1, 0, 1, r2, g2, b2, a2)
        mesh:setVertex(3, 1, 1, 1, 1, r2, g2, b2, a2)
        mesh:setVertex(4, 1, 0, 1, 0, r1, g1, b1, a1)
    end

    love.graphics.draw(mesh, x,y, 0, w,h)
end

end


return helper
