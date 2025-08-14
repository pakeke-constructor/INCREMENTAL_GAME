

---@class es.World
local World = objects.Class("es:World")


local newObjectType = require(".Object")



---@alias es.Object table<string,any>|es.ObjectClass
---@alias Object es.Object


function World:init()
    self.definedObjectTypes = {--[[
        [otypeName] -> etype
    ]]}

    self.defineAttachmentTypes = {--[[
        [attachmentName] -> atype
    ]]}

    self.events = {--[[
        [ev] -> {sys1, sys2, sys3, ...}
    ]]}

    self.questions = {--[[
        [qname] -> {sys1, sys2, sys3, ...}
    ]]}

    self.questionReducers = {} -- [qname] -> reducer
    self.questionDefaultValues = {} -- [qname] -> defaultValue
end




local defObjectTc = typecheck.assert("string", "table")

---@param name string
---@param otype table<string, any>
function World:defineObject(name, otype)
    defObjectTc(name, otype)
    local ctor = newObjectType(name, self, otype)
    self.definedObjectTypes[name] = ctor
end



function World:defineEvent(ev)
    self.events[ev] = objects.Array()
end




---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function World:defineQuestion(question, reducer, defaultValue)
    self.questionDefaultValues[question] = defaultValue
    self.questionReducers[question] = reducer

    self.questions[question] = objects.Array()
end


return World

