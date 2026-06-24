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
    if consts.NO_STEAM then
        localInventory.addPlaytimeProgress(dt)
    end
end

function rewards.quit()
    if consts.NO_STEAM then
        localInventory.quit()
    end
end

return rewards
