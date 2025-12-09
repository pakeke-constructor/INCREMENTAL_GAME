---@class PlayerAvatarEntity: g.Entity
---@field public speed number
local PlayerAvatarEntity = {}

local SPEED = 50

---@param dt number
function PlayerAvatarEntity:update(dt)
    local mx, my = g.getMouseHarvesterPosition()
    local destx, desty = self.x, self.y
    if mx and my then
        destx, desty = mx, my
    end

    local rot = math.atan2(desty - self.y, destx - self.x)
    local magn = helper.magnitude(destx - self.x, desty - self.y)
    local vx = math.cos(rot) * math.min(SPEED * dt, magn)
    local vy = math.sin(rot) * math.min(SPEED * dt, magn)
    worldutil.updateWaddleAnimation(self, vx, vy)
    self.x = self.x + vx
    self.y = self.y + vy
end

function PlayerAvatarEntity:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rot or 0)
    love.graphics.scale(self.sx or 1, self.sy or 1)
    g.drawPlayerAvatar(self.ox or 0, (self.oy or 0) - 4, 1)
    love.graphics.pop()
end

g.defineEntity("avatar", PlayerAvatarEntity)
