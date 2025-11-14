

---@class g.UpgradeTree: objects.Class
local UpgradeTree = objects.Class("g:UpgradeTree")


---@param fromJson string
function UpgradeTree:init(fromJson)

end


function UpgradeTree:serialize()

end


---@param x integer
---@param y integer
---@return
function UpgradeTree:get(x,y)
    return uinfo, price
    -- hmm, maybe should return `level` here too?
end


function UpgradeTree:set(x,y, uinfo)

end



function UpgradeTree:iterateVisibleUpgrades()

end


function UpgradeTree:iterateAllUpgrades()

end


return UpgradeTree
