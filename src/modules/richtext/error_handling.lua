---@param txt string
---@param fmt string
return function(txt, fmt, ...)
    -- TODO: Debug check
    if true then
        txt = "Error in richtext: " .. tostring(txt) .. "\n" .. string.format(fmt, ...)
        error(txt, 2)
        return nil, txt
    end
    return nil, txt
end
