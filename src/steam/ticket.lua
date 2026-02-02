-- A dead simple steam ticket dispatcher.

---@class Steam.Ticket
local Ticket = {}

---@class Steam.TicketObject: objects.Class
---@field package hexTicket string
---@field package ticketHandle integer
local TicketObject = objects.Class("Steam:TicketObject")

---@param hexTicket string
---@param hticket integer
function TicketObject:init(hexTicket, hticket)
    self.hexTicket = hexTicket
    self.ticketHandle = hticket
    self.cancelled = false
end

function TicketObject:destroy()
    if not self.cancelled then
        local luasteam = assert(Steam.getSteam(), "steam must be active")
        luasteam.user.cancelAuthTicket(self.ticketHandle)
        self.cancelled = true
    end
end

function TicketObject:getHexTicket()
    return (assert(self.hexTicket))
end

function TicketObject:__gc()
    return self:destroy()
end



---@alias Steam.TicketCallback fun(ticket:Steam.TicketObject?,err:luasteam.result)

---@type table<integer, Steam.TicketCallback?>
local ticketCallbacks = {}

function Ticket.init()
    local luasteam = Steam.getSteam()
    if luasteam then
        function luasteam.user.onTicketForWebApiResponse(data)
            local cb = ticketCallbacks[data.ticket]
            if cb then
                local ticketObj = nil
                if data.result == "OK" then
                    ticketObj = TicketObject(data.hexTicket, data.ticket)
                end

                ticketCallbacks[data.ticket] = nil
                cb(ticketObj, data.result)
            end
        end
    end
end

---@param callback Steam.TicketCallback TicketObject is valid even after exiting the callback.
function Ticket.request(callback)
    local luasteam = assert(Steam.getSteam(), "steam must be active")
    local ticketHandle = luasteam.user.getAuthTicketForWebApi(consts.ANALYTICS_IDENTITY)

    if ticketHandle then
        ticketCallbacks[ticketHandle.ticket] = callback
    end
end

return Ticket
