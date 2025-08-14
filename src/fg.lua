


---@class fg
local fg = {}



local isLoadTime = true

---@return boolean
function fg.isLoadTime()
    return isLoadTime
end

function fg.finishLoading()
    isLoadTime = false
end




local definedEvents = objects.Set()

function fg.defineEvent(ev)
    assert(fg.isLoadTime())
    definedEvents:add(ev)
end

function fg.isEvent(ev)
    return definedEvents:has(ev)
end


function fg.assertIsQuestionOrEvent(ev_or_question)
    local isQuestionOrEvent = (fg.isQuestion(ev_or_question) or fg.isEvent(ev_or_question))
    if not isQuestionOrEvent then
        error("Invalid question/event: " .. tostring(ev_or_question), 2)
    end
end


local questions = objects.Array()
local definedQuestions = objects.Set()

function fg.isQuestion(q)
    return definedQuestions:has(q)
end

---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function fg.defineQuestion(question, reducer, defaultValue)
    assert(fg.isLoadTime())
    questions:add({
        question = question,
        reducer = reducer,
        defaultValue = defaultValue
    })
    definedQuestions:add(question)
end




local es = require("src.obj.es")


fg.System = es.System
fg.ComponentSystem = es.ComponentSystem
fg.Entity = es.Entity
fg.Attachment = es.Attachment



---@type es.World?
local currentWorld = nil

function fg.newWorld()
    currentWorld = es.World()
    ---@cast currentWorld es.World
    for _,ev in ipairs(definedEvents) do
        currentWorld:defineEvent(ev)
    end
    for _,q in ipairs(questions) do
        currentWorld:defineQuestion(q.question, q.reducer, q.defaultValue)
    end

    local systems = fg.requireFolder("src.systems")
    for _,sysClass in pairs(systems) do
        currentWorld:addSystem(sysClass)
    end
end


---@return es.World
function fg.getWorld()
    return assert(currentWorld)
end


---@return es.World?
function fg.tryGetWorld()
    return currentWorld
end


---@param ev string
---@param ... unknown
function fg.call(ev, ...)
    currentWorld:call(ev, ...)
end


---@param q string
---@param ... unknown
---@return unknown
function fg.ask(q, ...)
    return currentWorld:ask(q, ...)
end





---@param e Entity
function fg.destroy(e)
    if currentWorld then
        currentWorld:call("destroy", e)
        e:delete()
    end
end


---@param e Entity
function fg.exists(e)
    return currentWorld and currentWorld:exists(e)
end




function fg.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            fg.walkDirectory(path .. "/" .. pth, func)
        end
    end
end


function fg.requireFolder(path)
    local results = {}
    fg.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4,-1) == ".lua" then
            pth = pth:sub(1, -5)
            log.trace("loading file:", pth)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end


return fg

