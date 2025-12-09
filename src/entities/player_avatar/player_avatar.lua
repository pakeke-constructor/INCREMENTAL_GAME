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

    local vx, vy = worldutil.moveToTarget(self, dt, destx, desty, SPEED)
    worldutil.updateWaddleAnimation(self, vx, vy)
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
