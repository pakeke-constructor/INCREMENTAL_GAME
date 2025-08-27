---Provides type checking functionality.
---
---Availability: Client and Server
---@class typecheck
local typecheck = {}


local type = type
local floor = math.floor
local select = select


local types = {}

function types.any()
    return true
end


function types.int(x)
    return (type(x) == "number") and floor(x) == x, "expected integer, (not float!)"
end
types.integer = types.int


function types.num(x)
    return type(x) == "number", "expected number"
end
types.number = types.num


function types.string(x)
    return type(x) == "string", "expected string"
end
types.str = types.string


function types.table(x)
    return type(x) == "table",  "expected table"
end


function types.userdata(x)
    return type(x) == "userdata", "expected userdata"
end


function types.func(x)
    return type(x) == "function", "expected function"
end
types["function"] = types.func
types.fn = types.func


function types.boolean(x)
    return type(x) == "boolean", "expected boolean"
end
types.bool = types.boolean





local function optional(f, str)
    return function(x)
        return (x == nil) or f(x), "expected nil or " .. str
    end
end


local parseToFunction -- need to define here for mutual recursion


local function parseUnion(str)
    local s = str:find("|")
    local type1 = str:sub(1,s-1)
    local type2 = str:sub(s+1)
    local f1 = parseToFunction(type1)
    local f2 = parseToFunction(type2)
    return function(x)
        local ok1, er1 = f1(x)
        local ok2, er2 = f2(x)
        if ok1 or ok2 then
            return true
        else
            return false, er1 .. " or " .. er2
        end
    end
end


function parseToFunction(str)
    str = str:gsub(" ","")

    if str:find("|") then
        return parseUnion(str), str
    elseif str:find("%?") then
        -- if string contains question mark, treat the argument as optional.
        local str2 = str:gsub("%?","")
        local func = parseToFunction(str2)
        return optional(func, str), str
    elseif types[str] then
        return types[str], str
    end
    error("malformed typecheck string: " .. tostring(str))
end



-- Must define here for mutual recursion
local makeCheckFunction


local function parseTableType(tableType)
    local keyList = {}
    local valueCheckers = {}

    for key, arg in pairs(tableType) do
        table.insert(keyList, key)
        local er0
        valueCheckers[key], er0 = makeCheckFunction(arg)
        if not valueCheckers[key] then
            error("Couldn't create typecheck function for key: " .. key .. " : " .. er0)
        end
    end

    local function check(x)
        local typeOk, er1 = types.table(x)
        if not typeOk then
            return nil, er1
        end

        for _, key in ipairs(keyList) do
            local val = x[key]
            local ok, err = valueCheckers[key](val)
            if not ok then
                return nil, "had bad value for '" .. tostring(key) .. "':\n" ..tostring(err)
            end
        end

        return true -- else, we are goods
    end

    return check
end



function makeCheckFunction(arg)
    if type(arg) == "string" then
        return parseToFunction(arg)
    end
    if type(arg) == "table" then
        return parseTableType(arg)
    end
    if type(arg) == "function" then
        return arg
    end
    return nil, tostring(arg) .. " is NOT a valid typecheck value! Must be either function, string, or table"
end



local function parseArgCheckers(arr)
    local keys = {}
    local retKey = true

    for i=1, #arr do
        local func, kfunc = makeCheckFunction(arr[i])
        if not func then
            error(("Failure parsing typecheck arg: %d:\n"):format(i) .. tostring(kfunc))
        end
        arr[i] = func

        if type(arr[i]) == "string" then
            keys[i] = arr[i]
        else
            retKey = false
        end
    end

    if retKey then
        return table.concat(keys, "\0")
    else
        return nil
    end
end



local function makeErr(arg, err, i)
    local estring = "Bad argument " .. tostring(i) .. ":\n"
    local err_data = tostring(type(arg)) .. " was given, but " .. tostring(err) 
    return estring .. err_data
end


---@type table<string, fun(...:any)>
local ASSERT_CACHE = {}

---Availability: Client and Server
---@param ... table|string|(fun(x:any):(boolean,string?))
---@return fun(...:any)
function typecheck.assert(...)
    local check_fns = {...}
    assert(#check_fns > 0, "expected an argument")

    local key = parseArgCheckers(check_fns)
    local func = ASSERT_CACHE[key]

    if func then
        return func
    end

    -- Argument count specialization
    if #check_fns == 1 then
        local check1 = check_fns[1]
        func = function(arg1)
            local ok, err = check1(arg1)
            if not ok then
                error(makeErr(arg1, err, 1), 3)
            end
        end
    elseif #check_fns == 2 then
        local check1 = check_fns[1]
        local check2 = check_fns[2]
        func = function(arg1, arg2)
            local ok, err = check1(arg1)
            if not ok then
                error(makeErr(arg1, err, 1), 3)
            end
            ok, err = check2(arg2)
            if not ok then
                error(makeErr(arg2, err, 2), 3)
            end
        end
    elseif #check_fns == 3 then
        local check1 = check_fns[1]
        local check2 = check_fns[2]
        local check3 = check_fns[3]
        func = function(arg1, arg2, arg3)
            local ok, err = check1(arg1)
            if not ok then
                error(makeErr(arg1, err, 1), 3)
            end
            ok, err = check2(arg2)
            if not ok then
                error(makeErr(arg2, err, 2), 3)
            end
            ok, err = check3(arg3)
            if not ok then
                error(makeErr(arg3, err, 3), 3)
            end
        end
    else
        -- Generic implementation
        func = function(...)
            for i=1, #check_fns do
                local arg = select(i, ...)
                local ok, err = check_fns[i](arg)
                if not ok then
                    error(makeErr(arg, err, i), 3)
                end
            end
        end
    end

    if key then -- Prevent "table index is nil"
        ASSERT_CACHE[key] = func
    end

    return func
end

---asserts that `tabl` is a table, 
---and that it has all of the keys listed in the `keys` table.
---
---Availability: Client and Server
---@generic T
---@param tabl table<T, any>
---@param keys T[]
function typecheck.assertKeys(tabl, keys)
    if type(tabl) ~= "table" then
        error("Expected table, got: " .. type(tabl), 2)
    end
    for _, key in ipairs(keys) do
        if tabl[key] == nil then
            error("Missing key: " .. tostring(key), 2)
        end
    end
end


---Availability: Client and Server
---@param ... string
---@return fun(...:any):(boolean,string?)
function typecheck.check(...)
    local check_fns = {...}
    parseArgCheckers(check_fns)

    return function(...)
        for i=1, #check_fns do
            local arg = select(i, ...)
            local ok, err = check_fns[i](arg)
            if not ok then
                return false, makeErr(arg, err, i)
            end
        end
        return true
    end
end

---Availability: Client and Server
---@param x any
---@param typeName string
function typecheck.isType(x, typeName)
    assert(types[typeName], "Invalid type!")
    return types[typeName](x)
end

---Create a new "interface" typecheck function.
---
---Interface typecheck only consider function values and string keys and has cleaner error message compared to
---`typecheck.assert({method = "function"})`.
---
---Availability: Client and Server
---@param interface table
---@return fun(tabl:any):(boolean,string?)
function typecheck.interface(interface)
    assert(typecheck.isType(interface, "table"))

    local methods = {}

    for k, v in pairs(interface) do
        if type(k) == "string" and type(v) == "function" then
            methods[#methods+1] = k
        end
    end

    if #methods == 0 then
        error("no methods to check in this interface (use typecheck.assertKeys instead?)")
    end

    ---@param tabl any
    ---@return boolean,string?
    return function(tabl)
        local status, err = typecheck.isType(tabl, "table")
        if not status then
            return status, err
        end

        ---@cast tabl table
        local unimplemented = {"object does not adhere interface spec:"}
        for _, method in ipairs(methods) do
            local t = type(tabl[method])

            if t == "nil" then
                unimplemented[#unimplemented+1] = "unimplemented method '"..method.."'"
            elseif t ~= "function" then
                unimplemented[#unimplemented+1] = "method '"..method.."' is not a function (it was '"..t.."')"
            end

            -- If there are more than 3 errors, limit it to 3.
            -- Note: 5 is used because the last message and the first message counts, so:
            -- 3 (actual errors) + 2 (first and last message) = 5 (elements in table).
            if #unimplemented >= 5 then
                unimplemented[#unimplemented] = "... and more methods"
                break
            end
        end

        -- If there's only first message in the table, then it's not an error.
        if #unimplemented > 1 then
            return false, table.concat(unimplemented, "\n")
        end

        return true
    end
end



local addTypeTc = typecheck.assert("string", "function")

---Availability: Client and Server
---@param typeName string
---@param check fun(x:any):(boolean,string?)
function typecheck.addType(typeName, check)
    addTypeTc(typeName, check)
    assert(not types[typeName], "Overwriting existing type!")

    types[typeName] = check
end

-- LOVE types
local loveTypes = {
    "ImageData",
    "RandomGenerator",
    "Source",
    "Texture",
    "Transform",
    "Quad",
}
for _, lt in ipairs(loveTypes) do
    local errmsg = "Expected "..lt.." LOVE object"
    typecheck.addType("love:"..lt, function(x)
        local ok = not not (type(x) == "userdata" and x.typeOf and x:typeOf(lt))
        return ok, errmsg
    end)
end

typecheck.addType("love", function(x)
    local ok = not not (type(x) == "userdata" and x.typeOf and x:typeOf("Object"))
    return ok, "Expected LOVE object"
end)

return typecheck
