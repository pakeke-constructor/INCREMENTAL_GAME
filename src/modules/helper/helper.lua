

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


---@param vals [number, number]
---@param rng (fun():number)? Function that returns random number from 0 to 1.
function helper.randrange(vals, rng)
    rng = rng or love.math.random
    return helper.lerp(vals[1], vals[2], rng())
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
    -- in
    sineIn = function(x) return 1 - math.cos((x * math.pi) / 2) end,
    -- out
    sineOut = function(x) return math.sin((x * math.pi) / 2) end,
    -- inout
    sineInOut = function(x) return -(math.cos(math.pi * x) - 1) / 2 end
}



---Calls `objects.Color:getRGBA()` then multiply the alpha by the specified value.
---@param color objects.Color
---@param alpha number
function helper.multiplyAlpha(color, alpha)
    local r, g, b, a = color:getRGBA()
    return r, g, b, a * alpha
end



return helper
