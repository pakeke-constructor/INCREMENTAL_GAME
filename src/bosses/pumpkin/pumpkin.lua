


---@type godrays.RayBundle
local RAY1 = {
    rayCount = 5,
    color = objects.Color.CRIMSON,
    startWidth = 5,
    length = 250,
    divisions = 25,
    growRate = 0.3,
}

---@type godrays.RayBundle
local RAY2 = {
    rayCount = 3,
    color = objects.Color.CRIMSON,
    startWidth = 10,
    length = 150,
    divisions = 25,
    growRate = 0.2,
}



g.defineBoss("pumpkin_boss", 0, {
    maxHealth = 100000,
    resources = {},
    drawOrder = 90,

    drawBelow = function (tok)
        lg.setColor(0,0,0,0.5)
        g.drawImage("pumpkin_boss", tok.x, tok.y + 18)
        lg.setColor(1,1,1)
        local t = love.timer.getTime()
        godrays.drawRays(tok.x, tok.y, t+0.7, RAY1)
        godrays.drawRays(tok.x, tok.y, -t-0.7, RAY1)
        godrays.drawRays(tok.x, tok.y, t*0.7, RAY2)
    end
})


