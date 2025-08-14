

---@class es.System
---@field _world es.World
local System = {}
local System_mt = {__index = System}


function System:init()
    -- override this to initialize values
end

local OVERRIDES = {
    init = true
}


---@return es.World
function System:getWorld()
    return self._world
end


--- gets events for this system
---@return string[]
function System:getEventCallbacks()
    local buf = objects.Array()
    for k,v in pairs(self) do
        if type(v) == "function" and fg.isEvent(k) then
            buf:add(k)
        end
    end
    return buf
end


--- gets questions for this system
---@return string[]
function System:getQuestionCallbacks()
    local buf = objects.Array()
    for k,v in pairs(self) do
        if type(v) == "function" and fg.isQuestion(k) then
            buf:add(k)
        end
    end
    return buf
end




local function newSystemClass()
    local SystemClass = {}
    ---@param world es.World
    local function newInstance(_, world)
        assert(world,"?")
        local sys = {_world = world}
        for k,v in pairs(SystemClass) do
            -- copy the methods in, for efficiency.
            -- no need to worry about metatables.
            sys[k] = v
        end
        setmetatable(sys, System_mt)
        if sys.init then
            sys:init()
        end
        return sys
    end

    local SystemClass_mt = {
        __newindex = function(t,k,v)
            if System[k] and (not OVERRIDES[k]) then
                error("Attempted to overwrite privaleged method")
            end
            if (not OVERRIDES[k]) and type(v) == "function" then
                fg.assertIsQuestionOrEvent(k)
            end
            rawset(t,k,v)
        end,
        __call = newInstance
    }

    return setmetatable(SystemClass, SystemClass_mt)
end


return newSystemClass

