
---@class _g.SpinningAxe: g.Entity
local SpinningAxe = {}


SpinningAxe.lifetime = 3.6
SpinningAxe.image = "spinning_axe"

local RAD = 20

function SpinningAxe:init()
    local S=40
    local a = love.math.random() * 2*math.pi
    self.vx = (S*math.cos(a))
    self.vy = (S*math.sin(a))

    g.iterateTokensInArea(self.x,self.y, RAD * 1.5, function(tok)
        g.damageToken(tok, 50)
    end)
end

function SpinningAxe:drawBelow()
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,1,1,0.4)
    love.graphics.circle("line", self.x,self.y, RAD)
end


function SpinningAxe:update(dt)
    local ROT_SPEED = 8
    self.rot = (self.rot or 0) - dt*ROT_SPEED
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end


function SpinningAxe:perSecondUpdate()
    g.iterateTokensInArea(self.x,self.y, RAD, function(tok)
        g.damageToken(tok, 50)
    end)
end


g.defineEntity("spinning_axe", SpinningAxe)

