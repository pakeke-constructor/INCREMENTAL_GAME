


---@class es.ObjectClass
---@field protected _world es.World
---@field protected _name es.World
---@field init function
local Object = {}
local Object_mt = {__index=Object}




function Object:_ensureAttachments()
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
function Object:attach(atc)
    self:_ensureAttachments()

    local atcs = self.attachments
    if atc.id  then
        if atcs.ids[atc.id] then
            local oldAtc = atcs.ids[atc.id]
            self:detach(oldAtc)
        end
        atcs.ids[atc.id] = atc
    end

    assert(not atc.ob, "Object attached twice")
    atc.ob = self

    for _, event in ipairs(atc:getEvents()) do
        atcs.events[event] = atcs.events[event] or objects.Set()
        atcs.events[event]:add(atc)
    end
    
    for _, question in ipairs(atc:getQuestions()) do
        atcs.questions[question] = atcs.questions[question] or objects.Set()
        atcs.questions[question]:add(atc)
    end

    if atc.onAttached then
        atc:onAttached(atc.ob)
    end
end



---@param atc string|es.Attachment
function Object:detach(atc)
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
        atc:onDetached(atc.ob)
    end
    atc.ob = nil
end



function Object:getAttachmentById(id)
    return self.attachments.ids[id]
end

---@param event string
---@param ... unknown
function Object:call(event, ...)
    local atcs = self.attachments
    if not atcs or not atcs.events[event] then return end
    for _, atc in ipairs(atcs.events[event]) do
        if atc[event] then
            atc[event](atc, self, ...)
        end
    end
end


---@param question string
---@param ... unknown
---@return any
function Object:ask(question, ...)
    local reducer = getQuestionReducer(question)
    local value = getQuestionDefaultValue(question)

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




function Object:getSharedComponents()
    -- huge stinky hack! 
    -- oh well, make sure we test it.
    return getmetatable(self).__index
end



function Object:getWorld()
    return self._world
end

function Object:getTypename()
    return self._name
end




local function shallowCopy(otype)
    assert(not getmetatable(otype), "?")
    local cpy={}
    for k,v in pairs(otype) do
        cpy[k]=v
    end
    return cpy
end


---@param name string
---@param otype table
local function newObjectType(name, otype)
    otype = shallowCopy(otype)

    otype._name = name

    for k,v in pairs(otype) do
        if Object[k] then
            error("Attempted to overwrite privaleged method: " .. tostring(k))
        end
    end

    local mt = {
        __index = setmetatable(otype, Object_mt),
    }

    local function newInstance(...)
        local e = setmetatable({}, mt)
        if e.init then
            e:init(...)
        end
        return e
    end

    return newInstance
end



return newObjectType


