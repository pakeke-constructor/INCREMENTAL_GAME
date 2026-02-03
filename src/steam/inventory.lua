-- A dead simple steam inventory dispatcher.

---@class Steam.Inventory
local Inventory = {}

---@alias Steam.InventoryCallback fun(result:luasteam.result, handle:integer)

---@type table<integer, Steam.InventoryCallback?>
local inventoryCallbacks = {}

function Inventory.init()
    local luasteam = Steam.getSteam()
    if luasteam then
        function luasteam.inventory.onSteamInventoryResultReady(data)
            local cb = inventoryCallbacks[data.handle]

            if cb then
                inventoryCallbacks[data.handle] = nil
                cb(data.result, data.handle)
            end

            luasteam.inventory.destroyResult(data.handle)
        end
    end
end

---@param targetItemdefId integer
---@param ingredients table<luasteam.uint64, integer> Key is item ID (not itemdef ID), Value is quantity.
---@param callback Steam.InventoryCallback Inventory result is only valid inside the callback.
function Inventory.exchangeItems(targetItemdefId, ingredients, callback)
    local luasteam = assert(Steam.getSteam())
    local handle = luasteam.inventory.exchangeItems(targetItemdefId, ingredients)
    if handle then
        inventoryCallbacks[handle] = callback
    end
    return not not handle
end

---@param callback Steam.InventoryCallback Inventory result is only valid inside the callback.
function Inventory.getAllItems(callback)
    local luasteam = assert(Steam.getSteam())
    local handle = luasteam.inventory.getAllItems()
    if handle then
        inventoryCallbacks[handle] = callback
    end
    return not not handle
end

return Inventory
