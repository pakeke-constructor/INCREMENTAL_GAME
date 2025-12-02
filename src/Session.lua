


local World = require("src.world.world")
local Tree = require("src.upgrades.Tree")
local cosmetics = require("src.cosmetics.cosmetics")



---@class g.Session: objects.Class
---@field prestige number
---@field upgrades table<string, boolean>
---@field resources g.Resources
---@field mainWorld g.World
---@field metrics table<string, number>
---@field stats table<string, number>
---@field tokenQueue {tokenId:string, onSpawn: function?}[]
local Session = objects.Class("g:Session")



--[[

Session class.

IMPORTANT NOTE:
Session should be like a data-class.

Dont create complex getters.
just provide the raw data, keep it simple.

]]

function Session:init()
    self.worldTime = 0.
    self.prestige = 0
    self.playtime = 0
    self.idletime = 0

    -- xp is basically just token-health.
    -- eg.  Harvest token with 5 health ==> earn +5 xp
    self.xpRequirement = 1
    self.xp = 0
    -- (only increments when player is INSIDE harvest-scene)

    self.level = 0 -- when xp > xpRequirement, level up!

    self.resources = {}
    for _,resId in ipairs(g.RESOURCE_LIST) do
        self.resources[resId] = 0
        if consts.DEV_MODE then
            self.resources[resId] = 1000000000
        end
    end

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
    ---@type {tokenId:string, onSpawn: function?}[]
    self.tokenQueue = {}

    -- Accessory data
    ---@type g.Avatar
    self.avatar = {
        avatar = consts.DEFAULT_CAT_AVATAR,
        background = consts.DEFAULT_BACKGROUND_AVATAR,
        hat = nil,
    }

    self.tree = Tree()

    self.unlockedPOI = objects.Set()

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




local function calculateXPRequirement()
    --[[
    xp requirement scales with the number of tokens.
    xp = the amount of token-health destroyed
    ]]
    local totalTokenHP = 0
    local world = g.getMainWorld()
    for tokType, count in world:iterateTokenPool() do
        local tinfo = g.getTokenInfo(tokType)
        totalTokenHP = totalTokenHP + (tinfo.maxHealth * count)
    end

    local level = g.getSn().level
    if level <= 1 then
        return math.ceil(totalTokenHP * 1.8)
    elseif level <= 5 then
        return math.ceil(totalTokenHP * 2.5)
    end

    return math.ceil(totalTokenHP * math.sqrt(level))
end



--- updates session and main world. should only be called once, (hence _)
---@param dt any
function Session:_update(dt)
    for stat, t in pairs(g.VALID_STATS) do
        local mod = g.ask(t.addQuestion) + t.startingValue
        local mult = g.ask(t.multQuestion)
        g.stats[stat] = mod*mult
    end
    self.worldTime = self.worldTime + dt
    self.playtime = self.playtime + dt
    self.mainWorld:_update(dt)

    self.xpRequirement = calculateXPRequirement()
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

    -- Load accessory unlocks
    if data.avatar then
        local av = data.avatar
        sess.avatar.avatar = cosmetics.isValidCosmetic(av.avatar) and av.avatar or consts.DEFAULT_CAT_AVATAR
        sess.avatar.background = cosmetics.isValidCosmetic(av.background) and av.background or consts.DEFAULT_BACKGROUND_AVATAR
        sess.avatar.hat = cosmetics.isValidCosmetic(av.hat) and av.hat or nil
    end

    -- Metrics
    for metric, v in pairs(data.metrics) do
        sess.metrics[metric] = assert(tonumber(v))
    end

    -- Stats
    for k,sta in pairs(g.VALID_STATS) do
        g.stats[k] = helper.assert(tonumber(data.stats[k] or sta.startingValue), "invalid stat value", k)
    end

    -- Upgrade trees
    if data.tree then
        sess.tree = Tree.deserialize(data.tree)
    end

    -- Unlocked map POIs
    if data.unlockedPOI then
        for _, v in ipairs(data.unlockedPOI) do
            sess.unlockedPOI:add(v)
        end
    end

    return sess
end

function Session:serialize()
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
        metrics = self.metrics,
        stats = stats,
        avatar = {
            avatar = self.avatar.avatar,
            background = self.avatar.background,
            hat = self.avatar.hat
        },
        tree = self.tree:serialize(),
        unlockedPOI = self.unlockedPOI:totable()
    }
end


return Session
