---
---@class reducers
local reducers = {}
--[[

These are mainly supposed to be used with the umg.ask() function,
as the reducer.

]]

---
---@param a boolean
---@param b boolean
---@return boolean
function reducers.OR(a,b)
    return a or b
end

---
---@param a boolean
---@param b boolean
---@return boolean
function reducers.AND(a,b)
    return a and b
end


---
---@param a number
---@param b number
---@return number
function reducers.ADD(a,b)
    return (a or 0) + (b or 0)
end
reducers.SUM = reducers.ADD


---@param a number
---@param b number
---@return number
function reducers.MULTIPLY(a,b)
    return (a or 1) * (b or 1)
end

---combines vectors together by adding.
---(Answers must return 2 numbers)
---
---
---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@return number,number
function reducers.ADD_VECTOR(x1,x2, y1,y2)
    return x1 + x2, y1 + y2
end

---combines 3d vectors together by adding.
---(Answers must return 3 numbers)
---
---
---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@param z1 number
---@param z2 number
---@return number,number,number
function reducers.ADD_VECTOR3(x1,x2, y1,y2, z1,z2)
    return x1 + x2, y1 + y2, z1+z2
end

---combines vectors together by multiplying.
---(Only works when the answers return 2 numbers.)
---
---
---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@return number,number
function reducers.MULTIPLY_VECTOR(x1,x2, y1,y2)
    return x1 * x2, y1 * y2
end

-- default priority
local D_PRIO = -9999

---Treats the 2nd answer-value as the priority.
---Returns the answer with the highest priority.
---
---The first argument can be any type- only the priority matters for resolution.
---
---(If priorities are equal, returns the most recently defined answer)
---
---If you want a definitive answer to a question, 
---(i.e. a question where results can't really be combined,)
---this is probably the best reducer to use.
---
---Example:
---```lua
----- answering image for an entity:
---umg.answer("modname:getImage", function(ent)
---    if ent.animation then
---        -- return
---        local img = ent.animation.frame
---        local priority = 1
---        return img, priority
---    end
---end)
---```
---
---
---@param a any
---@param b any
---@param prio_a number
---@param prio_b number
---@return any,number
function reducers.PRIORITY(a, b, prio_a, prio_b)
    if (prio_a or D_PRIO) > (prio_b or D_PRIO) then
        return a, prio_a
    end
    return b, prio_b
end


---same as PRIORITY, but for 2 arguments, not 1.
---
---Argument visualization:
---```lua
---umg.answer(... function()
---    return x1, y1, prio_1
---end)
---
---umg.answer(... function()
---    return x2, y2, prio_2
---end)
---```
---
---
---@param x1 any
---@param x2 any
---@param y1 any
---@param y2 any
---@param prio_1 integer
---@param prio_2 integer
---@return any,any,integer
function reducers.PRIORITY_DOUBLE(x1,x2, y1,y2, prio_1, prio_2)
    if (prio_1 or D_PRIO) > (prio_2 or D_PRIO) then
        return x1, y1, prio_1
    end
    return x2, y2, prio_2
end


---Thin wrapper to `math.min`
---
---
---@param a number
---@param b number
---@return number
function reducers.MIN(a, b)
    return math.min(a, b)
end

---Thin wrapper to `math.max`
---
---
---@param a number
---@param b number
---@return number
function reducers.MAX(a, b)
    return math.max(a, b)
end




return reducers

