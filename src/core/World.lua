

---@class es.World
local World = objects.Class("es:World")


local newEntityType = require(".Entity")



---@alias es.Entity table<string,any>|es.EntityClass
---@alias Entity es.Entity


function World:init()
    self.definedEntityTypes = {--[[
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




local defEntityTc = typecheck.assert("string", "table")

---@param name string
---@param etype table<string, any>
function World:defineEntity(name, etype)
    defEntityTc(name, etype)
    local ctor = newEntityType(name, self, etype)
    self.definedEntityTypes[name] = ctor
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

