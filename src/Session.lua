


local World = require("src.world.world")



---@class g.Session: objects.Class
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
    self.playtime = 0
    self.idletime = 0

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
    ]]} --[[@as table<integer,integer>]]

    self.mainWorld = World()

    -- metrics are running-totals of stuff.
    -- E.g. "how much logs has been collected in total?"
    self.metrics = {--[[
        [metricName] -> number
    ]]}

    -- Fishing-scene upgrades stored in here,
    -- (theres no other good place to put them; they arent regular upgrades)
    self.fisherCatCount = 0

    -- Tokens that are queued for spawning in harvest area
    ---@type string[]
    self.tokenQueue = {}

    -- reset stats:
    for k,sta in pairs(g.VALID_STATS) do
        g.stats[k] = sta.startingValue
    end
end

if false then
    ---@return g.Session
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Session() end
end





--- updates session and main world. should only be called once, (hence _)
---@param dt any
function Session:_update(dt)
    for stat, t in pairs(g.VALID_STATS) do
        local mod = g.ask(t.addQuestion) + t.startingValue
        local mult = g.ask(t.multQuestion)
        g.stats[stat] = mod*mult
    end
    self.playtime = self.playtime + dt
    self.mainWorld:_update(dt)
end


---@param data table
function Session.deserialize(data)
    local sess = Session()

    -- Load current prestige
    sess.prestige = assert(data.prestige) + 0
    sess.playtime = (data.playtime or 0) + 0
    sess.idletime = (data.idletime or 0) + 0

    -- Load resources
    for _,resId in ipairs(g.RESOURCE_LIST) do
        sess.resources[resId] = tonumber(data.resources[resId]) or 0
    end

    -- Load upgrade levels
    for utype, v in pairs(data.upgradeLevels) do
        if pcall(g.getUpgradeInfo, utype) then
            sess.upgradeLevels[utype] = assert(tonumber(v))
        end
    end

    -- Load prestige levels
    -- Stored prestige ID is 1-based but we want 0-based
    for pid, v in ipairs(data.prestigeLevels) do
        sess.prestigeLevels[pid - 1] = assert(tonumber(v))
    end

    -- Metrics
    for metric, v in pairs(data.metrics) do
        sess.metrics[metric] = assert(tonumber(v))
    end

    -- Stats
    for k,sta in pairs(g.VALID_STATS) do
        g.stats[k] = helper.assert(tonumber(data.stats[k] or sta.startingValue), "invalid stat value", k)
    end

    return sess
end

function Session:serialize()
    -- Convert prestige level indices to 1-based
    local plevels = {}
    for i = 0, #self.prestigeLevels do
        plevels[i + 1] = self.prestigeLevels[i]
    end

    -- Save stats
    local stats = {}
    for k in pairs(g.VALID_STATS) do
        stats[k] = g.stats[k]
    end

    return {
        prestige = self.prestige,
        playtime = self.playtime,
        idletime = self.idletime,
        resources = self.resources,
        upgradeLevels = self.upgradeLevels,
        prestigeLevels = plevels,
        metrics = self.metrics,
        stats = stats
    }
end


return Session
