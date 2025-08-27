
--[[


Spring:
Used for juicy movement and stuff

Taken from: 
https://github.com/a327ex/blog/issues/60


]]
local Class = require(".Class")

---@class objects.Spring: objects.Class
local Spring = Class("objects:Spring")

local DEFAULT = {
    target = 0
}


function Spring:init(args)
    args = args or DEFAULT
    self.x = args.target
    self.stiffness = args.stiffness or 100
    self.damping = args.damping or 10
    self.target = args.target
    self.vx = 0
end


function Spring:update(dt)
    local a = -self.stiffness*(self.x - self.target) - self.damping*self.vx
    self.vx = self.vx + a*dt
    self.x = self.x + self.vx*dt
end


function Spring:pull(f)
    self.x = self.x + f
end

return Spring

