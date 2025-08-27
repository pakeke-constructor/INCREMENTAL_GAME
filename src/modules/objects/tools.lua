

local objects = {}



function objects.injectKeys(tabl, keyTable)
    for k,v in pairs(keyTable) do
        tabl[k] = v
    end
end


function objects.inlineMethods(self)
    --[[
        inline all methods in an object for efficiency,
        such that there is no __index overhead.
        (Just copies over key-vals)
    ]]
    local mt = getmetatable(self)
    if type(mt.__index) ~= "table" then
        return -- not much we can do here!
    end
    for k,v in pairs(mt.__index) do
        self[k] = v
    end
end


return objects
