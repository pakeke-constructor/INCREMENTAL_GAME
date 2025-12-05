

```lua






---@param uinfo g.UpgradeInfo
---@return boolean
function g.isUpgradeHidden(uinfo)
end



---Retireves list of upgrade connectors adjacent to the upgrade.
---
---TODO: Not sure if this should be in g. but upgrade_scene needs it.
---@param uinfo g.UpgradeInfo
---@param prestige integer
---@param makeArtifical boolean? Set to true to generate connector directly adjacent to an upgrade (for rendering purpose)
function g.getUpgradeConnectors(uinfo, prestige, makeArtifical)
end



--- Floors a number, removing insignificant digits.
--- Useful for adjusting prices to look a bit "nicer"
---
--- g.floorSignificant(12345, 1) -> 10000
--- g.floorSignificant(12345, 2) -> 12000
--- g.floorSignificant(12345, 3) -> 12300
--- g.floorSignificant(12345, 4) -> 12340
--- g.floorSignificant(12345, 5) -> 12345
---@param value number
---@param nsig integer
---@return integer
local function floorSignificant(value, nsig)
end

local function modifyUpgradePrice(uinfo, val, level)
end


---WARNING: This incurs a table allocation.
---@param uinfo g.UpgradeInfo
---@param level integer? Optional; defaults to the current upgrade's level.
---@return g.Bundle
function g.getUpgradePrice(uinfo, level)
end


---@param uinfo g.UpgradeInfo
---@param level number? Optional; defaults to the current level.
---@return boolean
function g.canAffordUpgrade(uinfo, level)
end



---@param uinfo g.UpgradeInfo
---@return boolean wasPurchased
function g.tryBuyUpgrade(uinfo)
end



---@param uinfo g.UpgradeInfo
---@return number
function g.getUpgradeLevel(uinfo)
end

```



