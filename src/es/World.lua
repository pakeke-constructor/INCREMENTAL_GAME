

---@class es.World
local World = objects.Class("es:World")


local newEntityType = require(".Entity")



---@alias es.Entity table<string,any>|es.EntityClass
---@alias Entity es.Entity


local function isNumber(x)
    return type(x) == "number"
end

function World:init()
    self.definedComponents = {--[[
        [compName] -> typecheckFunc?
    ]]}
    self.definedEntityTypes = {--[[
        [etypeName] -> etype
    ]]}

    self.systems = {--[[
        [SystemClass] -> system
    ]]}
    self.componentSystems = {--[[
        [comp] -> system
    ]]}

    self.entities = {--[[
        [e] -> true
    ]]}

    self.rembuffer = objects.Set()

    self.events = {--[[
        [ev] -> {sys1, sys2, sys3, ...}
    ]]}

    self.questions = {--[[
        [qname] -> {sys1, sys2, sys3, ...}
    ]]}

    self.questionReducers = {} -- [qname] -> reducer
    self.questionDefaultValues = {} -- [qname] -> defaultValue

    self:defineComponent("attachments")
    self:defineComponent("x", isNumber)
    self:defineComponent("y", isNumber)
end




local defCompTc = typecheck.assert("string", "function?")

---@param comp string
---@param checker (fun(x:any):boolean)?
function World:defineComponent(comp, checker)
    defCompTc(comp, checker)
    self.definedComponents[comp] = checker or nil
end



local defEntityTc = typecheck.assert("string", "table")

---@param name string
---@param etype table<string, any>
function World:defineEntity(name, etype)
    defEntityTc(name, etype)
    local ctor = newEntityType(name, self, etype)
    self.definedEntityTypes[name] = ctor
end


---@param e es.Entity
---@return es.World
function World:_incorporateEntity(e)
    self.entities[e] = true
    for c,_ in pairs(e:getSharedComponents()) do
        if c:sub(1,1) ~= "_" then
            self:_addComponent(e,c)
        end
    end
    return self
end


local newEntityTc = typecheck.assert("es:World", "string", "number", "number")


---@param name string
---@param x number
---@param y number
---@param ... unknown
---@return Entity
function World:newEntity(name, x, y, ...)
    newEntityTc(self, name, x, y)
    local ctor = self.definedEntityTypes[name]
    if not ctor then
        error("Invalid entity-type: " .. tostring(name))
    end

    local e = ctor(x,y,...)
    e.x = x
    e.y = y
    self:_incorporateEntity(e)
    return e
end




---@param e es.Entity
---@return boolean
function World:exists(e)
    return self.entities[e]
end

function World:_removeEntity(e)
    self.rembuffer:add(e)
end


---@param e Entity
---@param comp string
function World:_addComponent(e, comp)
    ---@type es.ComponentSystem
    local sys = self.componentSystems[comp]
    if sys then
        sys:_addBuffered(e)
    end
end



---@param e Entity
---@param comp string
function World:_removeComponent(e, comp)
    ---@type es.ComponentSystem
    local sys = self.componentSystems[comp]
    if sys then
        sys:_removeBuffered(e)
    end
end






---@param systemClass es.System
---@return boolean
function World:addSystem(systemClass)
    if self.systems[systemClass] then return false end
    local sys = systemClass(self)
    local comp = sys._component
    if comp then
        if self.componentSystems[comp] then
            error("Overwriting component system: " .. tostring(comp))
        end
        self.componentSystems[comp] = sys
    end
    for _, event in ipairs(sys:getEventCallbacks()) do
        self.events[event]:add(sys)
    end
    for _, question in ipairs(sys:getQuestionCallbacks()) do
        self.questions[question]:add(sys)
    end
    self.systems[systemClass] = sys
    return true
end




---@param systemClass es.System
---@return es.System|table<string,any>
function World:getSystem(systemClass)
    return self.systems[systemClass]
end




---@param arr objects.Array
---@param sys es.System
local function removeCallback(arr, sys)
    for i, syss in ipairs(arr) do
        if syss == sys then
            arr:remove(i)
        end
    end
end


---@param systemClass es.System
function World:removeSystem(systemClass)
    local sys = self.systems[systemClass]
    if not sys then return end
    self.systems[systemClass] = nil

    local comp = sys._component
    if comp then
        self.componentSystems[comp] = nil
    end
    for _, cb in ipairs(sys:getEventCallbacks()) do
        removeCallback(self.events[cb], sys)
    end
    for _, cb in ipairs(sys:getQuestionCallbacks()) do
        removeCallback(self.questions[cb], sys)
    end
end



function World:defineEvent(ev)
    self.events[ev] = objects.Array()
end


---@param ev string
---@param maybe_ent any
---@param ... unknown
function World:call(ev, maybe_ent, ...)
    local systems = self.events[ev]
    if (not systems) then
        error("Invalid event: " .. tostring(ev))
    end
    if self:exists(maybe_ent) and maybe_ent.attachments then
        maybe_ent:_callAttachments(ev, maybe_ent, ...)
    end
    for _,sys in ipairs(systems) do
        sys[ev](sys, maybe_ent, ...)
    end
end




---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function World:defineQuestion(question, reducer, defaultValue)
    self.questionDefaultValues[question] = defaultValue
    self.questionReducers[question] = reducer

    self.questions[question] = objects.Array()
end



---@param question string
---@param maybe_ent Entity|any?
---@param ... unknown
function World:ask(question, maybe_ent, ...)
    local systems = self.questions[question]
    if (not systems) then
        error("Invalid question: " .. tostring(question))
    end

    local currentValue = self.questionDefaultValues[question]
    local reducer = self.questionReducers[question]

    if self:exists(maybe_ent) and maybe_ent.attachments then
        currentValue = maybe_ent:_askAttachments(question, reducer, currentValue, ...)
    end
    for _,sys in ipairs(systems) do
        local answer = sys[question](sys, maybe_ent, ...)
        currentValue = reducer(currentValue, answer)
    end
    return currentValue
end




function World:flush()
    for _, sys in pairs(self.componentSystems) do
        ---@cast sys es.ComponentSystem
        sys:_flush()

        for _,e in ipairs(self.rembuffer) do
            sys:_removeInstantly(e)
        end
    end
    self.rembuffer:clear()
end


return World

