


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
            g.damageToken(tok, g.stats.KnifeDamage)
            ent.lifetime = 0 -- Destroy
        end
    }
}

function KnifeEntity:init(rot, leeway)
    rot = rot or helper.lerp(0, 2 * math.pi, love.math.random())
    self.rot = rot + ROT_OFFSET
    self.vx = math.cos(rot) * SPEED
    self.vy = math.sin(rot) * SPEED
    if leeway then
        -- leeway can be used to ensure that if we spawn knife on 
        -- top of a token, it doesnt hit the token
        local dx,dy=0,0
        dx = leeway * math.cos(rot)
        dy = leeway * math.sin(rot)
        self.x = self.x + dx
        self.y = self.y + dy
    end

end

function KnifeEntity:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

g.defineEntity("knife", KnifeEntity)
end







do
local ROT_SPEED = 7 -- rad/s
local SPEED = 200 -- units/s

---@class _ScytheEntity: g.Entity
local ScytheEntity = {
    image = "iron_scythe",
    lifetime = 5,
    hitToken = {
        radius = 16,
        collision = function(ent, tok)
            g.damageToken(tok, g.stats.HitDamage)
            ent.lifetime = 0 -- Destroy
        end
    }
}

function ScytheEntity:init(rot, leeway)
    rot = rot or helper.lerp(0, 2 * math.pi, love.math.random())
    self.baseRot = rot
    self.vx = math.cos(rot) * SPEED
    self.vy = math.sin(rot) * SPEED
    if leeway then
        -- leeway can be used to ensure that if we spawn knife on 
        -- top of a token, it doesnt hit the token
        local dx,dy=0,0
        dx = leeway * math.cos(rot)
        dy = leeway * math.sin(rot)
        self.x = self.x + dx
        self.y = self.y + dy
    end
end


function ScytheEntity:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.rot = self.baseRot + self.lifetime*ROT_SPEED
end

g.defineEntity("scythe_projectile", ScytheEntity)
end


