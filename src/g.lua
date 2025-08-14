

-- global exports.
-- Gotta go fast, i dont care about "best practice"

---@class g
---@field private _money integer
local g = {}



local isLoadTime = true

---@return boolean
function g.isLoadTime()
    return isLoadTime
end

function g.finishLoading()
    isLoadTime = false
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




local definedEvents = objects.Set()

function g.defineEvent(ev)
    assert(g.isLoadTime())
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


local questions = objects.Array()
local definedQuestions = objects.Set()

function g.isQuestion(q)
    return definedQuestions:has(q)
end

---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function g.defineQuestion(question, reducer, defaultValue)
    assert(g.isLoadTime())
    questions:add({
        question = question,
        reducer = reducer,
        defaultValue = defaultValue
    })
    definedQuestions:add(question)
end




local objs = require("src.core.objs")


g.Object = objs.Object
g.Attachment = objs.Attachment





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

