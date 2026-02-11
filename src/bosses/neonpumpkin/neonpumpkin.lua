

local particles = require("src.modules.particles.particles")



---@type godrays.RayBundle
local RAY1 = {
    rayCount = 5,
    color = objects.Color("#".."FFC1DD08"),
    startWidth = 5,
    length = 60,
    divisions = 40,
    growRate = 0.3,
}




local PARTICLE_LIFETIME = 0.5

local pworld = particles.newParticlesWorld({
    drawParticle = function (p)
        local lt = p.lifetime
        local ox = math.sin(lt*3)*4
        lg.setColor(0.1, 0.8, 0.9)
        local scale = 1 - (lt / PARTICLE_LIFETIME)
        if p.id % 2 == 0 then
            g.drawImage("pixel_circle_r16", p.x+ox, p.y-lt*5, 0, scale, scale)
        else
            g.drawImage("pixel_circle_r9", p.x+ox, p.y-lt*5, 0, scale, scale)
        end
        lg.setColor(1, 1, 1, 1)
    end,

    getParticleDuration = function (p)
        return PARTICLE_LIFETIME
    end,
})



local PARTICLE_SPAWN_RADIUS = 30
local PARTICLE_VY_MIN = -60
local PARTICLE_VY_MAX = -100
local PARTICLE_VX_RANGE = 40

g.defineBoss("neonpumpkin_boss", 3, "pumpkin_health", { -- pumpkin_health is defined in pumpkin boss
    maxHealth = 1100000,
    resources = {},
    drawOrder = 90,

    flightCustomWings = {
        image = "big_purplewing_visual",
        distance = 46
    },

    update = function (tok, dt)
        pworld:update(dt)
        worldutil.updateBossTokenFlypath(tok, 4, consts.BOSSFIGHT_DURATION, 4)
        g.requestBGM(g.BGMID.BOSS)
        if love.math.random()/60 < dt then
            local angle = love.math.random() * math.pi * 2
            local dist = love.math.random() * PARTICLE_SPAWN_RADIUS
            local px = tok.x + math.cos(angle) * dist
            local py = tok.y + math.sin(angle) * dist
            local vx = (love.math.random() - 0.5) * 2 * PARTICLE_VX_RANGE
            local vy = PARTICLE_VY_MIN + love.math.random() * (PARTICLE_VY_MAX - PARTICLE_VY_MIN)
            pworld:spawnParticle(px, py, vx, vy)
        end
    end,

    drawBelow = function (tok)
        -- shadow:
        lg.setColor(0, 0, 0, 0.5)
        g.drawImage("neonpumpkin_boss", tok.x, tok.y + 18)
        lg.setColor(1, 1, 1)

        -- rays:
        local t = love.timer.getTime()
        godrays.drawRays(tok.x, tok.y, t*0.7, RAY1)

        pworld:draw()
    end
})
