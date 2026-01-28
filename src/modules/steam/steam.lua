---@diagnostic disable: inject-field
local hasluasteam, luasteam = pcall(require, "luasteam")

local Steam
if hasluasteam then
    local lsinit = luasteam.init
    local lsshutdown = luasteam.shutdown
    Steam = luasteam
    Steam.available = true
    Steam.active = false

    function Steam.init()
        local result = lsinit()
        Steam.active = result
        return result
    end

    function Steam.shutdown()
        lsshutdown()
        Steam.active = false
    end
else
    Steam = {
        available = false,
        active = false,
        init = function()
            return false
        end,
        shutdown = function()
        end
    }
end

return Steam
