---@type godrays.RayBundle
local RAY = {
    rayCount = 5,
    color = objects.Color("#".."ffce42f5"),
    startWidth = 5,
    length = 60,
    divisions = 40,
    growRate = 0.3,
}

---@param tok g.Token
---@param oy number
local function drawClaw(tok, oy)
    local t = tok.timeAlive / 3
    local rotleft = math.sin(t * 2 * math.pi) * 0.4
    local rotright = math.cos(t * 2 * math.pi) * 0.4

    g.drawImageOffset("giantcrab_claw", tok.x + 32, tok.y + 19 + oy, rotright, 1, 1, 0.6, 0.2)
    g.drawImageOffset("giantcrab_claw", tok.x - 32, tok.y + 19 + oy, rotleft, -1, 1, 0.6, 0.2)
end

g.defineBoss("giantcrab_boss", 1, "giantcrab_crabberry", {
    maxHealth = 100000,
    image = "giantcrab_body",
    resources = {},
    drawOrder = 90,

    flightCustomWings = {
        image = "big_wing_visual",
        distance = 42
    },

    update = function (tok)
        worldutil.updateBossTokenFlypath(tok, 4, consts.BOSSFIGHT_DURATION, 4)
        g.requestBGM(g.BGMID.BOSS)
    end,

    drawBelow = function(tok)
        -- shadow:
        lg.setColor(0, 0, 0, 0.5)
        g.drawImage("giantcrab_body", tok.x, tok.y + 18)
        drawClaw(tok, 18)
        lg.setColor(1, 1, 1)

        godrays.drawRays(tok.x, tok.y, tok.timeAlive*0.7, RAY)
    end,

    drawToken = function(tok, x, y, rot, sx, sy, kx, ky)
        drawClaw(tok, 0)
    end
})

g.defineToken("giantcrab_crabberry", "\0giantcrab_health_internal", {
    maxHealth = 50,
    resources = {},

    update = function(tok)
        local boss = g.getBossToken()
        if not boss then
            g.deleteToken(tok)
        end
    end,

    tokenDestroyed = function(tok)
        local boss = g.getBossToken()
        if boss then
            local ent = worldutil.spawnFadingLine(tok.x, tok.y, boss.x, boss.y, 5, objects.Color.RED, 0.5)
            ent.drawOrder = -800
            g.damageToken(boss, 4150)
        end
    end
})
