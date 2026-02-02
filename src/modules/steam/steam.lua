local hasluasteam, luasteam = pcall(require, "luasteam")

local Steam = {
    available = hasluasteam,
    active = false
}

function Steam.init()
    if hasluasteam then
        local result = luasteam.init()
        Steam.active = result
    end

    return Steam.active
end

function Steam.shutdown()
    if hasluasteam then
        luasteam.shutdown()
        Steam.active = false
    end
end

function Steam.getSteam()
    if hasluasteam and Steam.active then
        return luasteam
    end

    return nil
end

return Steam
