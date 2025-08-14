


---@class es.EntityClass
---@field protected _world es.World
---@field protected _name es.World
---@field init function
local Entity = {}
local Entity_mt = {__index=Entity}



function Entity:isSharedComponent(comp)
    local shcomps = self:getSharedComponents()
    return (not rawget(self, comp)) and (rawget(shcomps, comp) ~= nil)
end

function Entity:isRegularComponent(comp)
    return rawget(self, comp) ~= nil
end

function Entity:hasComponent(comp)
    return rawget(self, comp) ~= nil
end



function Entity:_ensureAttachments()
    if not self.attachments then
        self.attachments = {
            ids = {--[[
                [attachmentId] -> attachment
            ]]},
            events = {--[[
                [event] -> objects.Set({atch1, atch2, ... })
            ]]},
            questions = {--[[
                [question] -> objects.Set({atch1, atch2, ... })
            ]]}
        }
    end
end


---@param atc es.Attachment
function Entity:attach(atc)
    self:_ensureAttachments()

    local atcs = self.attachments
    if atc.id  then
        if atcs.ids[atc.id] then
            local oldAtc = atcs.ids[atc.id]
            self:detach(oldAtc)
        end
        atcs.ids[atc.id] = atc
    end

    assert(not atc.ent, "Entity attached twice")
    atc.ent = self

    for _, event in ipairs(atc:getEvents()) do
        atcs.events[event] = atcs.events[event] or objects.Set()
        atcs.events[event]:add(atc)
    end
    
    for _, question in ipairs(atc:getQuestions()) do
        atcs.questions[question] = atcs.questions[question] or objects.Set()
        atcs.questions[question]:add(atc)
    end

    if atc.onAttached then
        atc:onAttached(atc.ent)
    end
end



---@param atc string|es.Attachment
function Entity:detach(atc)
    local atcs = self.attachments
    if not atcs then return end
    if type(atc) == "string" then
        atc = self:getAttachmentById(atc)
        if not atc then return end
    end
    if atc.id then
        atcs.ids[atc.id] = nil
    end

    for _, event in ipairs(atc:getEvents()) do
        if atcs.events[event] then
            atcs.events[event]:remove(atc)
        end
    end
    for _, question in ipairs(atc:getQuestions()) do
        if atcs.questions[question] then
            atcs.questions[question]:remove(atc)
        end
    end

    if atc.onDetached then
        atc:onDetached(atc.ent)
    end
    atc.ent = nil
end



function Entity:getAttachmentById(id)
    return self.attachments.ids[id]
end

---@param event string
---@param ... unknown
function Entity:_callAttachments(event, ...)
    local atcs = self.attachments
    if not atcs or not atcs.events[event] then return end
    for _, atc in ipairs(atcs.events[event]) do
        if atc[event] then
            atc[event](atc, self, ...)
        end
    end
end


---@param question string
---@param reducer fun(a:any, b:any): any
---@param value any
---@param ... unknown
---@return any
function Entity:_askAttachments(question, reducer, value, ...)
    local atcs = self.attachments
    if not atcs or not atcs.questions[question] then return value end
    local result = value
    for _, atc in ipairs(atcs.questions[question]) do
        if atc[question] then
            local answer = atc[question](atc, self, ...)
            result = reducer(result, answer)
        end
    end
    
    return result
end




function Entity:getSharedComponents()
    -- huge stinky hack! 
    -- oh well, make sure we test it.
    return getmetatable(self).__index
end



function Entity:getWorld()
    return self._world
end

function Entity:getTypename()
    return self._name
end



---@param comp string
---@param val any
function Entity:addComponent(comp, val)
    rawset(self,comp,val)
    local world = self:getWorld()
    world:_addComponent(self,comp)
end

---@param comp string
function Entity:removeComponent(comp)
    local isRegular = self:isRegularComponent(comp)
    local world = self:getWorld()
    rawset(self,comp,nil)
    if isRegular then
        world:_removeComponent(self,comp)
    end
end




function Entity:isDeleted()
    return self.___deleted
end

function Entity:delete()
    local w = self:getWorld()
    w:_removeEntity(self)
    self.___deleted = true
end




local function shallowCopy(etype)
    assert(not getmetatable(etype), "?")
    local cpy={}
    for k,v in pairs(etype) do
        cpy[k]=v
    end
    return cpy
end


---@param name string
---@param world es.World
---@param etype table
local function newEntityType(name, world, etype)
    etype = shallowCopy(etype)

    etype._world = world
    etype._name = name

    local ent_mt = {
        __index = setmetatable(etype, Entity_mt),
        __newindex = Entity.addComponent
    }

    local function newEntityInstance(x, y, ...)
        local e = setmetatable({
            x=x, y=y
        }, ent_mt)
        if e.init then
            e:init(x, y, ...)
        end
        return e
    end

    return newEntityInstance
end



return newEntityType


