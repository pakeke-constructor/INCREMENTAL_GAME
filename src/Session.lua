

local upgrades = require("src.upgrades.upgrades")

local World = require("src.world.world")



---@class g.Session
---@field upgrades table<string, boolean>
---@field money number
---@field logs number
---@field bones number
---@field rocks number
---@field mainWorld g.World
---@field metrics table<string, number>
---@field stats table<string, number>
local Session = objects.Class("g:Session")


function Session:init()
    self.money = 0
    self.logs = 0
    self.bones = 0
    self.rocks = 0

    self.upgradeLevels = {--[[
        [upgradeId] -> level
    ]]}

    self.prestigeLevels = {--[[
        [prestigeId] -> prestigeLevel
    ]]}

    self.mainWorld = World()

    -- metrics are running-totals of stuff.
    -- E.g. "how much logs has been collected in total?"
    self.metrics = {--[[
        [metricName] -> number
    ]]}

    -- stats are recomputed every frame.
    -- Think of them as like "global properties".
    -- (EG. harvestingSpeed, harvestingDamage)
    self.stats = {--[[
        [statName] -> number
    ]]}
end


---@param upgradeId string
function Session:increaseUpgrade(upgradeId)
    self.upgradeLevels[upgradeId] = (self.upgradeLevels[upgradeId] or 0) + 1
end


---@param upgradeId string
---@return number
function Session:getUpgradeLevel(upgradeId)
    assert(upgrades.getInfo(upgradeId), "Upgrade doesnt exist")
    return self.upgradeLevels[upgradeId] or 0
end



---@param prestigeId string
function Session:prestige(prestigeId)

end





--- updates session. should only be called once, (hence _)
---@param dt any
function Session:_update(dt)
    for stat, t in pairs(g.VALID_STATS) do
        local mod = g.ask(t.addQuestion) + t.startingValue
        local mult = g.ask(t.multQuestion)
        g.stats[stat] = mod*mult
    end
end


--- updates main world. should only be called once, (hence _)
---@param dt number
function Session:_updateMainWorld(dt)
    self.mainWorld:_update(dt)
end


return Session
