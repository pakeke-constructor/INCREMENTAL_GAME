-- Coefficient of restitution
local COR = 0.5
local GRAVITY = 5 * 9.81 -- in pixels
local DECELERATION_X = 8 -- per second
local EPSILON = 0.1 -- velocity is considered zero if less than this

---@class GrowthFallingEntity: g.Entity
---@field private vx number
---@field private vy number
---@field private radius number
local GrowthFallingEntity = {}

---@param growth string
---@param ground number
function GrowthFallingEntity:init(growth, ground)
    self.image = growth
    self.vx = helper.lerp(10, 20, love.math.random()) * (love.math.random(0, 1) * 2 - 1)
    self.vy = -helper.lerp(4, 12, love.math.random())
    self.ground = ground

    local q = g.getImageQuad(growth)
    local _, _, w, h = q:getViewport()
    self.radius = helper.magnitude(w, h)
end

---@param dt number
function GrowthFallingEntity:update(dt)
    self.vx = helper.sign(self.vx) * math.max(math.abs(self.vx) - DECELERATION_X * dt, 0)
    self.vy = self.vy + GRAVITY * dt

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.rot = (self.rot or 0) + self.vx * dt / self.radius
    if self.y > self.ground then
        -- Bounce
        self.vy = -self.vy * COR
        self.y = 2 * self.ground - self.y
    end

    if not self.lifetime then
        if math.abs(self.y - self.ground) < EPSILON and math.abs(self.vx) < EPSILON and math.abs(self.vy) < EPSILON then
            self.lifetime = 0.3
        end
    end
end

function GrowthFallingEntity:drawBelow()
    lg.setColor(1,1,1, math.max(0, self.lifetime/0.15))
end

g.defineEntity("growth_falling", GrowthFallingEntity)
