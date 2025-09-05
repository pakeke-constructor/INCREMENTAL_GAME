

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")
local upgrades = require("src.upgrades.upgrades")
local world = require("src.world.world")


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
    local isQuestionOrEvent = (g.getQuestionInfo(ev_or_question) or g.isEvent(ev_or_question))
    if not isQuestionOrEvent then
        error("Invalid question/event: " .. tostring(ev_or_question), 2 + level)
    end
end


---@param ev string
---@param arg1 any
---@param ... unknown
function g.call(ev, arg1, ...)
    -- call systems
    if (type(arg1) == "table") and arg1[ev] then
        arg1[ev](arg1, ...)
    end

    upgrades.call(ev, arg1, ...)
end



local questions = {--[[
    [question] -> {reducer=func, defaultValue=0}
]]}

function g.getQuestionInfo(q)
    return questions[q]
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
end


---@param q string
---@param arg1 any
---@param ... unknown
function g.ask(q, arg1, ...)
    local t = questions[q]
    if not t then
        error("Invalid question")
    end
    local reducer, val = t.reducer, t.defaultValue

    if (type(arg1) == "table") and arg1[q] then
        val = reducer(arg1[q](arg1, ...), val)
    end

    return reducer(val, upgrades.ask(q, arg1, ...))
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


---@class g.stats
g.stats = {}

g.stats.HitDuration = g.defineStat("HitDuration")
g.stats.HitDamage = g.defineStat("HitDamage")
g.stats.HarvestArea = g.defineStat("HarvestArea")





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



function g.addEntity(ent)
    assert(type(ent) == "table")
    assert(ent.update)
    assert(ent.type)
    assert(ent.draw)

    world.entities:addBuffered(ent)
end

function g.removeEntity(ent)
    world.entities:removeBuffered(ent)
end



local tokenTypes = {--[[
    [tokenType] -> {
        health = X,
        
        onUpdate = func,
        onDestroyed = func
    }
]]}

local tokenMts = {--[[
    [tokenType] -> tokenMt
]]}


---@alias TokenDefinition {health:number, image:string, money:number? }

---@param tokType string
---@param tabl TokenDefinition
function g.defineToken(tokType, tabl)
    assert(not tabl.type, ".type is a reserved field!")
    ---@diagnostic disable-next-line
    tabl.type = tokType
    tokenTypes[tokType] = tabl
    tokenMts[tokType] = {__index = tabl}
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


local DEFAULT_MIN_SPACING = 12

local function getRandomPos(x, y, w, h, minSpacing, maxAttempts)
    maxAttempts = maxAttempts or 20
    minSpacing = minSpacing or DEFAULT_MIN_SPACING
    for attempt = 1, maxAttempts do
        local px = x + math.random() * w
        local py = y + math.random() * h
        local tooClose = false

        world.tokenPartition:query(px, py, function(tok)
            local dx = px - tok.x
            local dy = py - tok.y
            local distSq = dx*dx + dy*dy
            if distSq < minSpacing * minSpacing then
                tooClose = true
                return true -- stop iteration early
            end
        end)

        if not tooClose then
            return px, py
        end
    end

    return nil, nil
end


function g.getRandomPositionForToken()
    return getRandomPos(0,0, world.WIDTH,world.HEIGHT)
end


function g.spawnToken(tokType, x,y)
    assert(type(tokType) == "string")
    assert(x and y)
    if not (tokenTypes[tokType]) then
        error("Invalid token type")
    end

    local tok = setmetatable({
        x = x,
        y = y
    }, tokenMts[tokType])

    world.tokens:addBuffered(tok)
end


function g.removeToken(tok)
    world.tokens:removeBuffered(tok)
end


function g.tokenExists(tok)
    return world.tokens:has(tok)
end

function g.tryHitToken(tok)
    local time = world.tokensBeingHit[tok]
    if not time then
        world.tokensBeingHit[tok] = g.stats.HitDuration
    end
end






g.___internal = {}

-- DONT CALL THIS MANUALLY!
function g.___internal.update()
    for stat, t in pairs(validStats) do
        local mod = g.ask(t.add)
        local mult = g.ask(t.mult)
        g.stats[stat] = mod*mult
    end

    -- update TokenPool
    local tp = TokenPool()
    g.call("populateTokenPool", tp)
    _storage.tokenPool = tp
end


return g

