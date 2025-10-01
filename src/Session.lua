

local upgrades = require("src.upgrades.upgrades")

local World = require("src.world.world")



---@class g.Session
---@field prestige number
---@field upgrades table<string, boolean>
---@field resources g.Resources
---@field mainWorld g.World
---@field metrics table<string, number>
---@field stats table<string, number>
local Session = objects.Class("g:Session")



--[[

Session class.

IMPORTANT NOTE:
Session should be like a data-class.

Dont create complex getters.
just provide the raw data, keep it simple.

]]

function Session:init()
    self.prestige = 0

    self.resources = {}
    for _,resId in ipairs(g.RESOURCE_LIST) do
        self.resources[resId] = 0
        if consts.DEV_MODE then
            self.resources[resId] = 1000000000
        end
    end

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

    -- reset stats:
    for k,sta in pairs(g.VALID_STATS) do
        g.stats[k] = sta.startingValue
    end
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
