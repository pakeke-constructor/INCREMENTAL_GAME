---@class LocalInventory
local localInventory = {}

local SAVE_PATH = "local_cosmetics.json"

---@type (fun(id:string):boolean)?
local isValidCosmetic = nil

local state = {
    chestCount = 0,
    ---@type objects.Set<string>
    unlocked = objects.Set(),
    playtimeProgress = 0.,
    lastDailyGrantDate = nil,
}

local function save()
    love.filesystem.write(SAVE_PATH, json.encode({
        chestCount = state.chestCount,
        unlocked = state.unlocked:totable(),
        playtimeProgress = state.playtimeProgress,
        lastDailyGrantDate = state.lastDailyGrantDate,
    }))
end

---@param validator fun(id:string):boolean
function localInventory.init(validator)
    isValidCosmetic = assert(validator)

    state.chestCount = 0
    state.unlocked:clear()
    state.playtimeProgress = 0.
    state.lastDailyGrantDate = nil

    if not love.filesystem.getInfo(SAVE_PATH, "file") then
        return
    end

    local read = love.filesystem.read(SAVE_PATH)
    if not read then
        return
    end

    local ok, data = pcall(json.decode, read)
    if not ok or type(data) ~= "table" then
        return
    end

    state.chestCount = math.max(0, math.floor(tonumber(data.chestCount) or 0))
    state.playtimeProgress = math.max(0, tonumber(data.playtimeProgress) or 0)

    if type(data.lastDailyGrantDate) == "string" then
        state.lastDailyGrantDate = data.lastDailyGrantDate
    end

    if type(data.unlocked) == "table" then
        for _, cosmeticId in ipairs(data.unlocked) do
            if type(cosmeticId) == "string" and (not isValidCosmetic or isValidCosmetic(cosmeticId)) then
                state.unlocked:add(cosmeticId)
            end
        end
    end
end

function localInventory.getUnlockedSet()
    return state.unlocked
end

function localInventory.getChestCount()
    return state.chestCount
end

---@param count integer
---@param shouldSave boolean?
function localInventory.addChest(count, shouldSave)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then
        return
    end

    state.chestCount = state.chestCount + count
    if shouldSave ~= false then
        save()
    end
end

---@param cosmeticId string
---@return boolean
function localInventory.consumeChestForUnlock(cosmeticId)
    if not isValidCosmetic then return false end
    if state.chestCount <= 0 then return false end
    if not isValidCosmetic(cosmeticId) then return false end

    state.chestCount = state.chestCount - 1
    state.unlocked:add(cosmeticId)
    save()
    return true
end

function localInventory.getPlaytimeProgress()
    return state.playtimeProgress
end

---@param dt number
function localInventory.addPlaytimeProgress(dt)
    state.playtimeProgress = math.max(0, state.playtimeProgress + dt)

    if state.playtimeProgress >= consts.NO_STEAM_CHEST_PLAYTIME_SECONDS then
        localInventory.addChest(1)
        state.playtimeProgress = state.playtimeProgress % consts.NO_STEAM_CHEST_PLAYTIME_SECONDS
        return true
    end

    return false
end

localInventory.save = save
localInventory.quit = save

---@return string?
function localInventory.getLastDailyGrantDate()
    return state.lastDailyGrantDate
end

---@param date string
function localInventory.setLastDailyGrantDate(date)
    state.lastDailyGrantDate = date
end

return localInventory
