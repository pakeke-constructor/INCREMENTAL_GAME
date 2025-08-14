

--[[

Attachments can be explicitly "attached" to entities.

They are like systems, but only on the entity they are attached to.

]]

---@class es.Attachment
---@field id string?
---@field ent es.Entity
local Attachment = {}


local OVERRIDES = {
    init = true,
    onAttached = true,
    onDetached = true,
}


function Attachment:init(n)
end


function Attachment:getEntity()
    return self.ent
end


function Attachment:onAttached(ent)
end

function Attachment:onDetached(ent)
end


function Attachment:getEvents()
    local events = {}
    for k, v in pairs(getmetatable(self).__index) do
        if type(v) == "function" and fg.isEvent(k) then
            table.insert(events, k)
        end
    end
    return events
end


function Attachment:getQuestions()
    local questions = {}
    for k, v in pairs(getmetatable(self).__index) do
        if type(v) == "function" and fg.isQuestion(k) then
            table.insert(questions, k)
        end
    end
    return questions
end



function Attachment:detach()
    self.ent:detach(self)
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
                fg.assertIsQuestionOrEvent(k)
            end
            rawset(t,k,v)
        end
    })

    return AttachmentClass
end

return newAttachment

