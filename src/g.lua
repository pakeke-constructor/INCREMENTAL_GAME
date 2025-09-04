

-- global exports.
-- Gotta go fast, i dont care about "best practice"

---@class g
---@field private _money integer
local g = {}


-- A "storage" table that stores a bunch of data 
-- relevant to this play session
local _storage = {}


local validMetrics = {--[[
    [metricName] -> true
]]}



function g.initialize()
    _storage = {}
    _storage.metrics = {}

    for metricName in pairs(validMetrics) do
        _storage.metrics[metricName] = 0
    end
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



function g.getTokens()
    local tokens = {}
    g.call("populateTokens", tokens)
    return tokens
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



local questions = objects.Array()
local definedQuestions = objects.Set()

function g.isQuestion(q)
    return definedQuestions:has(q)
end

---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function g.defineQuestion(question, reducer, defaultValue)
    assert(g.getLoadingContext())
    questions:add({
        question = question,
        reducer = reducer,
        defaultValue = defaultValue
    })
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


return g

