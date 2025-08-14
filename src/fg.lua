


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


function fg.assertIsQuestionOrEvent(ev_or_question, level)
    level = level or 0
    local isQuestionOrEvent = (fg.isQuestion(ev_or_question) or fg.isEvent(ev_or_question))
    if not isQuestionOrEvent then
        error("Invalid question/event: " .. tostring(ev_or_question), 2 + level)
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




local objs = require("src.core.objs")


fg.Object = objs.Object
fg.Attachment = objs.Attachment





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

