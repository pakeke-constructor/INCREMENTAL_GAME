



-- we probably want more useful enum methods here.
local EnumMethods = {}

function EnumMethods:has(k)
    return rawget(self, k)
end



local ENUM_MT = {
    __index = function(t,k)
        if EnumMethods[k] then
            return EnumMethods[k]
        end
        error("Attempt to access undefined enum value: " .. k, 2)
    end,
    __newindex = function(t,k,v)
        error("Attempt to edit a constant enum", 2)
    end
}




local function assertString(x)
    if type(x) ~= "string" then
        error("Enum values must be strings", 3)
    end
end

---Availability: Client and Server
---@generic T
---@param values T
---@return T
local function newEnum(values)
    local enum = {}
    for _, v in ipairs(values) do
        enum[v] = v
        assertString(v)
    end

    for k,_v in pairs(values) do
        if type(k) ~= "number" then
            assertString(k)
            enum[k] = k
        end
    end

    return setmetatable(enum, ENUM_MT)
end


return newEnum

