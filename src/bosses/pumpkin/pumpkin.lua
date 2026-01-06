

local particles = require("src.modules.particles.particles")



---@type godrays.RayBundle
local RAY1 = {
    rayCount = 5,
    color = objects.Color.BLACK,
    startWidth = 5,
    length = 100,
    divisions = 5,
    growRate = 0.3,
}

---@type godrays.RayBundle
local RAY2 = {
    rayCount = 3,
    color = objects.Color.BLACK,
    startWidth = 10,
    length = 40,
    divisions = 5,
    growRate = 0.2,
}


local pworld = particles.newParticlesWorld({
    drawParticle = function (p)
        local lt = p.lifetime
        local ox = math.sin(lt*3)*4
        if p.id % 2 == 0 then
            g.drawImage("pixel_circle_r6", p.x+ox,p.y-lt*5)
        else
            g.drawImage("pixel_circle_r5", p.x+ox,p.y-lt*5)
        end
    end,

    getParticleDuration = function (p)
        return 0.35
    end,
})


g.defineBoss("pumpkin_boss", 0, {
    maxHealth = 100000,
    resources = {},
    drawOrder = 90,

    update = function (tok, dt)
        pworld:update(dt)
    end,

    drawBelow = function (tok)
        lg.setColor(0,0,0,0.5)
        g.drawImage("pumpkin_boss", tok.x, tok.y + 18)
        lg.setColor(1,1,1)

        pworld:draw()
        local t = love.timer.getTime()
        -- godrays.drawRays(tok.x, tok.y, t+0.7, RAY1)
        -- godrays.drawRays(tok.x, tok.y, -t-0.7, RAY1)
        -- godrays.drawRays(tok.x, tok.y, t*0.7, RAY2)
    end
})


