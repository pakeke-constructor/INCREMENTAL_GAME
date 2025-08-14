

--[[

Attachments can be explicitly "attached" to entities.

They are like systems, but only on the entity they are attached to.

]]

---@class es.Attachment
---@field id string?
---@field ob es.Object
local Attachment = {}


local OVERRIDES = {
    init = true,
    onAttached = true,
    onDetached = true,
}


function Attachment:init()
end


function Attachment:getEntity()
    return self.ob
end


function Attachment:onAttached(ob)
end

function Attachment:onDetached(ob)
end


function Attachment:getEvents()
    local events = {}
    for k, v in pairs(getmetatable(self).__index) do
        if type(v) == "function" and g.isEvent(k) then
            table.insert(events, k)
        end
    end
    return events
end


function Attachment:getQuestions()
    local questions = {}
    for k, v in pairs(getmetatable(self).__index) do
        if type(v) == "function" and g.isQuestion(k) then
            table.insert(questions, k)
        end
    end
    return questions
end



function Attachment:detach()
    self.ob:detach(self)
end


local function newAttachment()
    local AttachmentClass = {}
    local AttachmentClass_meta = {__index = AttachmentClass}

    setmetatable(AttachmentClass, {
        __index = Attachment,
        __call = function(cls, ...)
            local instance = setmetatable({}, AttachmentClass_meta)
            if instance.init then
                instance:init(...)
            end
            return instance
        end,
        __newindex = function(t, k, v)
            if Attachment[k] and (not OVERRIDES[k]) then
                error("Attempted to overwrite privaleged method")
            end
            if (not OVERRIDES[k]) and type(v) == "function" then
                g.assertIsQuestionOrEvent(k, 1)
            end
            rawset(t,k,v)
        end
    })

    return AttachmentClass
end

return newAttachment

