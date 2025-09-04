

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")


---@class g
---@field private _money integer
local g = {}


-- A "storage" table that stores a bunch of data 
-- relevant to this play session
---@class _STORAGE
---@field metrics table<string, number>
---@field stats table<string, number>
---@field tokenPool g.TokenPool
local _storage = {}


local validMetrics = {--[[
    [metricName] -> true
]]}




---@class g.TokenPool: objects.Class
local TokenPool = objects.Class("g:TokenPool")
function TokenPool:init()
    self.tokens = {}
end
function TokenPool:add(tokenId, amount)
    self.tokens[tokenId] = (self.tokens[tokenId] or 0) + (amount or 1)
end



function g.initialize()
    ---@diagnostic disable-next-line
    _storage = {}

    _storage.metrics = {--[[
        [metricName] -> number
    ]]}

    -- TokenPool is refreshed/recreated every frame
    _storage.tokenPool = TokenPool()

    -- stats are recomputed every frame.
    -- Think of them as like "global properties"
    _storage.stats = {--[[
        [statName] -> number
    ]]}

    for metricName in pairs(validMetrics) do
        _storage.metrics[metricName] = 0
    end
end



local loadingContext = {
    modname = "@" -- @ = built-in mod
}


---@return {modname:string}
function g.getLoadingContext()
    return loadingContext
end

function g.finishLoading()
    loadingContext = nil
end



g._money = 0

function g.addMoney(x)
    g._money = g._money + x
end


function g.trySubtractMoney(x)
    -- used for shopping:  
    -- if g.trySubtractMoney(COST) then  getUpgrade()  end
    if x <= g._money then
        g._money = g._money - x
        return true
    end
    return false
end


function g.getMoney()
    return g._money
end



---@return fun(table: table<string, number>, index?: string):string, number
---@return table<string, number>
function g.iterateTokenPool()
    return pairs(_storage.tokenPool.tokens)
end

---@param token string
---@return number
function g.getTokenPoolCount(token)
    return _storage.tokenPool.tokens[token] or 0
end





local sceneManager

---@param scName string
function g.gotoScene(scName)
    sceneManager = sceneManager or require("src.scenes.sceneManager")
    sceneManager.gotoScene(scName)
end



local definedEvents = objects.Set()

function g.defineEvent(ev)
    assert(g.getLoadingContext())
    definedEvents:add(ev)
end

function g.isEvent(ev)
    return definedEvents:has(ev)
end


function g.assertIsQuestionOrEvent(ev_or_question, level)
    level = level or 0
    local isQuestionOrEvent = (g.isQuestion(ev_or_question) or g.isEvent(ev_or_question))
    if not isQuestionOrEvent then
        error("Invalid question/event: " .. tostring(ev_or_question), 2 + level)
    end
end


---@param ev string
---@param ent_or_any any
---@param ... unknown
function g.call(ev, ent_or_any, ...)
    -- call systems

    -- call upgrades
end



local questions = {--[[
    [question] -> {reducer=func, defaultValue=0}
]]}
local definedQuestions = {}

function g.isQuestion(q)
    return definedQuestions[q]
end

---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function g.defineQuestion(question, reducer, defaultValue)
    assert(g.getLoadingContext())
    questions[question] = {
        reducer = reducer,
        defaultValue = defaultValue
    }
    definedQuestions:add(question)
end


---@param q string
---@param ent_or_any any
---@param ... unknown
function g.ask(q, ent_or_any, ...)
    -- ask systems

    -- ask upgrades
end






function g.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            g.walkDirectory(path .. "/" .. pth, func)
        end
    end
end


function g.requireFolder(path)
    local results = {}
    g.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4,-1) == ".lua" then
            pth = pth:sub(1, -5)
            log.trace("loading file:", pth)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end





-- metrics are "temporary" values that start at 0,
-- and keep track of arbitrary runtime stuff
-- (eg. number of logs destroyed, seconds-elapsed, mine-count, etc)

local metricTc = typecheck.assert("string")
function g.defineMetric(name)
    metricTc(name)

    validMetrics[name] = true
    _storage.metrics[name] = 0
end


local setMetricTc = typecheck.assert("string","number")
function g.setMetric(name, x)
    setMetricTc(name, x)
    assert(validMetrics[name], name)
    _storage.metrics[name] = x
end


function g.getMetric(name)
    metricTc(name)
    assert(validMetrics[name], name)
    return _storage.metrics[name]
end




local strTc = typecheck.assert("string")

---@type table<string, {add: string, mult:string}>
local validStats = {}

function g.defineStat(name)
    strTc(name)
    assert(name:sub(1,1):upper() == name:sub(1,1), "Stats must have first letter capitalized")
    local addQ = "get" .. name .. "Modifier"
    g.defineQuestion(addQ, reducers.ADD, 0)
    local multQ = "get" .. name .. "Multiplier"
    g.defineQuestion(multQ, reducers.MULTIPLY, 1)
    validStats[name]={
        add = addQ, mult = multQ
    }
    return 0
end

function g.getStat(name)
    strTc(name)
    assert(validStats[name], name)
    return _storage.stats[name] or 1
end


---@class g.stats
g.stats = {}

g.stats.HitDuration = g.defineStat("HitDuration")
g.stats.HitDamage = g.defineStat("HitDamage")
g.stats.HarvestArea = g.defineStat("HarvestArea")






g.___internal = {}

-- DONT CALL THIS MANUALLY!
function g.___internal.update()
    for stat, t in pairs(validStats) do
        local mod = g.ask(t.add)
        local mult = g.ask(t.mult)
        _storage.stats[stat] = mod*mult
    end

    -- update TokenPool
    local tp = TokenPool()
    g.call("populateTokenPool", tp)
    _storage.tokenPool = tp
end


return g

