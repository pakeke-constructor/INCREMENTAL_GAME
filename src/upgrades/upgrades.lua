


local upgrades = {}



function upgrades.definePrestige(prestigeId, upgradeTable)

end


---@param upgradeId string
---@param upgradeTable any
function upgrades.defineUpgrade(upgradeId, upgradeTable)

end


function upgrades.get(upgradeId)

end


---@param upgradeId string
---@return number? level level of upgrade; nil if not upgraded.
function upgrades.upgrade(upgradeId)
    return 1
end



return upgrades


