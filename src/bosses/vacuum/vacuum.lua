local particles = require("src.modules.particles.particles")

---@type godrays.RayBundle
local RAY = {
    rayCount = 8,
    color = objects.Color("#".."FF000000"),
    startWidth = 5,
    length = 100,
    divisions = 40,
    growRate = 0.3,
}

local PARTICLE_LIFETIME = 0.5
local PARTICLE_SPAWN_RADIUS = 30
local PARTICLE_VY_MIN = -60
local PARTICLE_VY_MAX = -100
local PARTICLE_VX_RANGE = 40

local pworld = particles.newParticlesWorld({
    drawParticle = function (p)
        local lt = p.lifetime
        local ox = math.sin(lt*3)*4
        lg.setColor(1, 1, 1)
        local scale = 1 - (lt / PARTICLE_LIFETIME)
        if p.id % 2 == 0 then
            g.drawImage("pixel_circle_r16", p.x+ox, p.y-lt*5, 0, scale, scale)
        else
            g.drawImage("pixel_circle_r9", p.x+ox, p.y-lt*5, 0, scale, scale)
        end
    end,

    getParticleDuration = function (p)
        return PARTICLE_LIFETIME
    end,
})

local SUCKING_POWER = 16 -- pixels per second
local SUCKING_RADIUS = 32 -- pixels on center of vacuum to delete the token.

g.defineBoss("vacuum_boss", 2, nil, {
    maxHealth = 5000000,
    image = "vacuum_body",
    resources = {},
    drawOrder = 90,

    flightCustomWings = {
        image = "big_wing_visual",
        distance = 46
    },

    update = function(tok, dt)
        pworld:update(dt)
        worldutil.updateBossTokenFlypath(tok, 4, consts.BOSSFIGHT_DURATION, 4)
        g.requestBGM(g.BGMID.BOSS)

        -- Particles
        if love.math.random()/60 < dt then
            local angle = love.math.random() * math.pi * 2
            local dist = love.math.random() * PARTICLE_SPAWN_RADIUS
            local px = tok.x + math.cos(angle) * dist
            local py = tok.y + math.sin(angle) * dist
            local vx = (love.math.random() - 0.5) * 2 * PARTICLE_VX_RANGE
            local vy = PARTICLE_VY_MIN + love.math.random() * (PARTICLE_VY_MAX - PARTICLE_VY_MIN)
            pworld:spawnParticle(px, py, vx, vy)
        end

        local ww, wh = g.getWorldDimensions()
        -- Sucking mechanic
        for _, gtok in ipairs(g.getMainWorld().tokens) do
            if gtok ~= tok then
                ---@cast gtok g.Token
                local rot = math.atan2(gtok.y - tok.y, gtok.x - tok.x)
                gtok.x = helper.clamp(gtok.x - math.cos(rot) * SUCKING_POWER * dt, 0, ww)
                gtok.y = helper.clamp(gtok.y - math.sin(rot) * SUCKING_POWER * dt, 0, wh)

                if helper.magnitude(gtok.y - tok.y, gtok.x - tok.x) < SUCKING_RADIUS then
                    g.deleteToken(gtok)
                end
            end
        end
    end,

    drawBelow = function (tok)
        -- shadow:
        lg.setColor(0, 0, 0, 0.5)
        g.drawImage("vacuum_body", tok.x, tok.y + 18)
        lg.setColor(1, 1, 1)

        -- rays:
        local t = love.timer.getTime()
        godrays.drawRays(tok.x, tok.y, t*0.7, RAY)

        pworld:draw()
    end,

    drawToken = function(tok, px, py, rot, sx, sy, kx, ky)
        local t = love.timer.getTime() / 2
        local sin1 = math.sin(t * math.pi * 2)
        local sin2 = math.sin(t * math.pi)
        local sin3 = sin1 * sin2
        local eyedir = sin3 > 0 and math.floor(sin3 + 0.5) or math.ceil(sin3 - 0.5)
        g.drawImage("vacuum_eye", px - 9 + eyedir * 5, py - 4, rot, sx, sy, kx, ky)
        g.drawImage("vacuum_eye", px + 9 + eyedir * 5, py - 4, rot, -sx, sy, kx, ky)
    end
})
