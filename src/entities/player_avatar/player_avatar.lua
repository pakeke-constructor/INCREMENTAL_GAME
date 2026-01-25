---@class PlayerAvatarEntity: g.Entity
---@field public speed number
local PlayerAvatarEntity = {}

local SPEED = 150

---@param dt number
function PlayerAvatarEntity:update(dt)
    local world = g.getMainWorld()
    local destx, desty = world.mouseX or self.x, world.mouseY or self.y
    local vx, vy = worldutil.moveToTarget(self, dt, destx, desty, SPEED, 18)
    worldutil.updateWaddleAnimation(self, vx, vy)
end

function PlayerAvatarEntity:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rot or 0)
    love.graphics.scale(self.sx or 1, self.sy or 1)
    g.drawPlayerAvatar(self.ox or 0, (self.oy or 0) - 4, 1)
    local sinfo = g.getScytheInfo(g.getCurrentScythe())
    g.drawImageOffset(sinfo.image, 12, 4, math.pi / 4, -1, 1, 0.1, 0.9)
    love.graphics.pop()
end

g.defineEntity("avatar", PlayerAvatarEntity)
