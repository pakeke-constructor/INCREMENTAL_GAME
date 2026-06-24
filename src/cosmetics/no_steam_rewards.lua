local localInventory = require("src.cosmetics.local_inventory")

---@class NoSteamRewards
local rewards = {}

function rewards.initForGameEntry()
    if not consts.NO_STEAM then
        return
    end

    local today = os.date("%Y-%m-%d") --[[@as string]]
    if localInventory.getLastDailyGrantDate() ~= today then
        localInventory.setLastDailyGrantDate(today)
        localInventory.addChest(1)
    end
end

---@param dt number
function rewards.update(dt)
    if not consts.NO_STEAM then
        return
    end

    localInventory.addPlaytimeProgress(dt)
end

function rewards.quit()
    if not consts.NO_STEAM then
        return
    end

    localInventory.quit()
end

return rewards
