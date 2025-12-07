


do
local ROT_OFFSET = math.pi / 4
local SPEED = 200 -- units/s

---@class _KnifeEntity: g.Entity
local KnifeEntity = {
    image = "knife",
    lifetime = 5,
    hitToken = {
        radius = 16,
        collision = function(ent, tok)
            g.damageToken(tok, 1)
            ent.lifetime = 0 -- Destroy
        end
    }
}

function KnifeEntity:init(rot)
    rot = rot or helper.lerp(0, 2 * math.pi, love.math.random())
    self.rot = rot + ROT_OFFSET
    self.vx = math.cos(rot) * SPEED
    self.vy = math.sin(rot) * SPEED
end

function KnifeEntity:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

g.defineEntity("knife", KnifeEntity)
end

















