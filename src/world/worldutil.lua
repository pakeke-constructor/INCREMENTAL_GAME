local worldutil = {}


---@param x number
---@param y number
---@param rad number
---@param circleColor objects.Color
---@param circleBorderColor objects.Color
---@param drawComboTimeout boolean?
function worldutil.drawHarvestCircle(x, y, rad, circleColor, circleBorderColor, drawComboTimeout)
    love.graphics.setColor(circleColor)
    love.graphics.circle("fill", x,y, rad)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.max(1, math.floor(rad / 15)))
    love.graphics.setColor(circleBorderColor)
    love.graphics.circle("line", x,y, rad)

    if drawComboTimeout then
        local world = g.getMainWorld()
        local combodur = world:_getComboDuration()
        local ratio = world.comboTimeout / combodur
        local joltScale = math.max(helper.remap(world.comboTimeout, combodur, combodur - 0.2, 1.4, 1), 1)

        local lineWidth = math.floor(rad/15) + 2
        local SEG=60

        -- Draw progress bar fill
        if ratio < 0.3 then
            lg.setColor(1, 0.3, 0.1)
        elseif ratio < 0.6 then
            lg.setColor(0.6, 0.5, 0.2)
        else
            lg.setColor(0.2, 0.8, 0.2)
        end
        helper.drawPartialCircle(x,y, rad, ratio, lineWidth*joltScale, SEG)
    end


    love.graphics.setLineWidth(lw)
end


---@param dt number
---@param value number
---@param velocity number
---@param maxvalue number
---@return number @New value
---@return boolean @Should direction be flipped?
local function computeValueBouncing(dt, value, velocity, maxvalue)
    value = value + velocity * dt
    if value < 0 then
        return -value, true
    elseif value >= maxvalue then
        return 2 * maxvalue - value, true
    end

    return value, false
end

---@param obj {x:number,y:number,dirX:number,dirY:number,speed:number}
---@param dt number
function worldutil.updateLikeDVD(obj, dt)
    local flip
    local worldW, worldH = g.getWorldDimensions()

    obj.x, flip = computeValueBouncing(dt, obj.x, obj.speed * obj.dirX, worldW)
    if flip then
        obj.dirX = -obj.dirX
    end

    obj.y, flip = computeValueBouncing(dt, obj.y, obj.speed * obj.dirY, worldH)
    if flip then
        obj.dirY = -obj.dirY
    end
end



-- worldutil.lifetimeAnimationUpdater
-- for animation of entities with lifetime comp
do

---@param framePrefix string
---@param numFrames integer
---@return string[]
local function makeFrames(framePrefix, numFrames)
    local t = {}
    for i=1, numFrames do
        table.insert(t, framePrefix .. tostring(i))
    end
    return t
end


---@param opt {framePrefix?: string, numFrames?: integer, frames?:string[]}
function worldutil.lifetimeAnimationUpdater(opt)
    local frames
    if opt.framePrefix then
        frames = makeFrames(opt.framePrefix, assert(opt.numFrames))
    else
        frames = assert(opt.frames)
    end

    ---@param ent g.Entity
    ---@param dt number
    local function update(ent, dt)
        -- SLIGHT HACK: tapping into __index
        local parentLifetime = getmetatable(ent).__index.lifetime

        assert(ent.lifetime)
        assert(parentLifetime)

        local i = math.floor((ent.lifetime/parentLifetime) * #frames) + 1
        local frame = frames[i]
        ent.image = frame
    end

    return update
end

end



local LIGHTNING_CHAIN_LIFETIME = 0.15
g.defineEntity("lightning_chain_visual", {
    init = function (ent, tokens)
        -- list of tokens to strike
        ---@cast ent g.Entity|{_tokens:g.Token[]}
        ent._tokens = tokens
        local bestY = -100
        for _,t in ipairs(tokens) do
            if t.y > bestY then
                ent.x = t.x
                ent.y = t.y
                bestY = t.y
            end
        end
    end,

    lifetime = LIGHTNING_CHAIN_LIFETIME,

    draw = function (ent)
        local lw=lg.getLineWidth()
        local fade = (math.min(1, ent.lifetime / LIGHTNING_CHAIN_LIFETIME))

        ---@cast ent g.Entity|{_tokens:g.Token[]}
        for i = 1, #ent._tokens - 1 do
            local tok1 = ent._tokens[i]
            local tok2 = ent._tokens[i + 1]
            lg.setLineWidth(10 * fade)
            lg.setColor(0.9, 0.7, 1)
            local r = love.math.random
            local r1 = helper.lerp(-4,4, r())
            local r2 = helper.lerp(-4,4, r())
            lg.line(tok1.x, tok1.y, tok2.x + r2, tok2.y + r1)
        end

        lg.setLineWidth(lw)
    end
})


local function findClosestToken(x, y, excludeTokens)
    local radius = 80
    local buffer = {}
    g.iterateTokensInArea(x, y, radius, function(tok)
        if not excludeTokens[tok] then
            table.insert(buffer, tok)
        end
    end)
    if #buffer == 0 then
        return nil
    end
    return helper.randomChoice(buffer)
end

---@param x number
---@param y number
---@param tokenChainSize number?
function worldutil.spawnLightning(x, y, tokenChainSize)
    g.playWorldSound("lightning_zap", 0.9, 0.25, 0.3, 0)
    tokenChainSize = math.max(2, tokenChainSize or 5)

    local foundTokens = {}
    local tokenList = {}

    local tok = findClosestToken(x, y, foundTokens)
    if not tok then return end

    foundTokens[tok] = true
    table.insert(tokenList, tok)

    for i = 1, tokenChainSize - 1 do
        local tok1 = findClosestToken(tok.x, tok.y, foundTokens)
        if not tok1 then break end
        foundTokens[tok1] = true
        table.insert(tokenList, tok1)
        tok = tok1
    end
    for _,t in ipairs(tokenList)do
        g.damageToken(t, g.stats.LightningDamage)
    end

    if #tokenList >= 2 then
        g.spawnEntity("lightning_chain_visual", 0,0,tokenList)
    end
end



---@param x number
---@param y number
---@param dmgMult number?
function worldutil.explosion(x,y,dmgMult)
    g.spawnEntity("small_explosion_animation", x,y)
    g.playWorldSound("small_explosion", 1.2,0.2,0.35,0.05)
    local dmg = g.stats.ExplosionDamage * (dmgMult or 1)
    g.iterateTokensInArea(x,y, 80, function(tok)
        g.damageToken(tok,dmg)
    end)
end





local WADDLE_ANIM_SPEED=6

---@param ent g.Entity
---@param vx number
---@param vy number
function worldutil.updateWaddleAnimation(ent,vx,vy)
    -- HACK: __index trick
    local origOy = ((getmetatable(ent).__index).oy or 0)

    if vx > 0 then
        ent.sx = 1
    elseif vx < 0 then
        ent.sx = -1
    end

    local t = love.timer.getTime() * WADDLE_ANIM_SPEED
    if (vx*vx + vy*vy) > 0.01 then
        -- then we are moving! do waddle
        local height = math.abs(math.sin(t))*7
        local rot = 0 + math.cos(t)/6
        ent.oy = origOy - height
        ent.rot = rot
    else
        ent.rot = 0
        ent.oy = origOy
    end
end

---@param ent {x:number,y:number}
---@param dt number
---@param destx number
---@param desty number
---@param speed number
---@param leewayRadius number? Stop moving when in range of this
function worldutil.moveToTarget(ent, dt, destx, desty, speed, leewayRadius)
    local rot = math.atan2(desty - ent.y, destx - ent.x)
    local magn = helper.magnitude(destx - ent.x, desty - ent.y)
    local vx = math.cos(rot) * math.min(speed * dt, magn)
    local vy = math.sin(rot) * math.min(speed * dt, magn)
    if (leewayRadius or 1) > magn then
        vx,vy = 0,0
    end

    local w,h = g.getWorldDimensions()
    ent.x = helper.clamp(ent.x + vx, 0,w)
    ent.y = helper.clamp(ent.y + vy, 0,h)
    return vx, vy
end




---@param tokid string
---@param x number
---@param y number
---@param radius number
function worldutil.spawnTokenNearPosition(tokid, x, y, radius)
    local magn = helper.lerp(0, radius, love.math.random())
    local rot = helper.lerp(0, 2 * math.pi, love.math.random())
    local tx = math.cos(rot) * magn
    local ty = math.sin(rot) * magn
    return g.spawnToken(tokid, x + tx, y + ty)
end






g.defineEntity("STS_ANIMATION", {
    drawOrder = 100,
    draw = function (ent)
        ---@diagnostic disable-next-line
        local img = assert(ent._image)
        ---@diagnostic disable-next-line
        local dur = ent._duration
        ---@diagnostic disable-next-line
        local maxScale = ent._maxScale
        local sc = helper.remap(ent.lifetime, dur,0, 1, maxScale)
        lg.setColor(1,1,1, ent.lifetime / dur)
        g.drawImage(img, ent.x, ent.y, 0, sc,sc)
    end
})

---@param image string
---@param x number
---@param y number
---@param duration number
---@param maxScale number?
function worldutil.spawnSTSAnimation(image, x, y, duration, maxScale)
    if g.isBeingSimulated() then
        return -- dont spawn when simulation mode
    end
    local e = g.spawnEntity("STS_ANIMATION", x, y)
    ---@diagnostic disable-next-line
    e._image = image
    ---@diagnostic disable-next-line
    e._duration = duration
    ---@diagnostic disable-next-line
    e._maxScale = maxScale or 3
    e.lifetime = duration
end



g.defineEntity("SHOCKWAVE_ANIMATION", {
    drawOrder = 100,
    draw = function (ent)
        ---@diagnostic disable-next-line
        local dur = ent._duration
        ---@diagnostic disable-next-line
        local maxRad = ent._maxRad
        ---@diagnostic disable-next-line
        local c = ent._color or objects.Color.WHITE

        local rad = helper.remap(ent.lifetime, dur,0, 7, maxRad)
        local alpha = ent.lifetime/dur
        lg.setColor(c[1],c[2],c[3], math.sqrt(alpha))

        local lw=lg.getLineWidth()
        lg.setLineWidth(maxRad/4)
        lg.push()
        lg.circle("line", ent.x,ent.y, rad,rad)
        lg.pop()
        lg.setLineWidth(lw)
    end
})

---@param x number
---@param y number
---@param duration number
---@param radius number?
---@param color (objects.Color|[number,number,number,number?])?
function worldutil.spawnShockwave(x, y, duration, radius, color)
    if g.isBeingSimulated() then
        return -- dont shockwave when simulation mode
    end
    local e = g.spawnEntity("SHOCKWAVE_ANIMATION", x, y)
    ---@diagnostic disable-next-line
    e._duration = duration
    ---@diagnostic disable-next-line
    e._maxRad = radius or 20
    e._color = color or objects.Color.WHITE
    e.lifetime = duration
end



g.defineEntity("TEXT_ANIMATION", {
    drawOrder = 100,
    shadow = false,
    draw = function (ent)
        ---@diagnostic disable-next-line
        local dur = ent._duration
        ---@diagnostic disable-next-line
        local text = ent._text
        ---@diagnostic disable-next-line
        local moveDistance = ent._moveDistance

        local yOffset = helper.remap(math.max(ent.lifetime*2-dur, 0), dur,0, 0, moveDistance)
        local alpha = 1

        lg.setColor(1, 1, 1, alpha)
        local f = g.getSmallFont(16)
        local sc = 1.2
        richtext.printRichCentered(text, assert(f), ent.x, ent.y - yOffset, 5000, "left", 0, sc)
    end
})

---@param text string
---@param x number
---@param y number
---@param duration number?
---@param moveDistance number?
function worldutil.spawnText(text, x, y, duration, moveDistance)
    if g.isBeingSimulated() then
        return -- dont spawn text when simulation mode
    end
    local e = g.spawnEntity("TEXT_ANIMATION", x, y)
    ---@diagnostic disable-next-line
    e._text = text
    ---@diagnostic disable-next-line
    e._duration = duration or 1.0
    ---@diagnostic disable-next-line
    e._moveDistance = moveDistance or 20
    e.lifetime = duration or 1.0
end




---@param x number
---@param y number
---@param rot number?
---@param leeway number?
function worldutil.spawnKnife(x, y, rot, leeway)
    g.spawnEntity("knife", x,y,rot, leeway)
end



---@param x number
---@param y number
---@param rot number?
---@param leeway number?
function worldutil.spawnScytheProjectile(x, y, rot, leeway)
    g.spawnEntity("scythe_projectile", x,y,rot, leeway)
end





g.defineEntity("line", {
    draw = function(ent)
        ---@diagnostic disable-next-line: undefined-field
        local t = ent.lifetime / ent._duration
        local col = {love.graphics.getColor()}
        ---@diagnostic disable-next-line: undefined-field
        love.graphics.setColor(ent._color)
        g.drawImage("1x1", ent.x, ent.y, ent.rot, ent.sx, ent.sy * t)
        love.graphics.setColor(col)
    end
})

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param width number
---@param color objects.Color
---@param duration number
function worldutil.spawnFadingLine(x1, y1, x2, y2, width, color, duration)
    local ent = g.spawnEntity("line", (x1 + x2) / 2, (y1 + y2) / 2)
    ent.sx = helper.magnitude(x2 - x1, y2 - y1)
    ent.sy = width
    ent.rot = math.atan2(y2 - y1, x2 - x1)
    ent.lifetime = duration
    ---@diagnostic disable-next-line: inject-field
    ent._color = color
    ---@diagnostic disable-next-line: inject-field
    ent._duration = duration
    return ent
end



---@param tok g.Token
---@param duration number How long it takes to travel across world.
function worldutil.initializeFlyingToken(tok, duration)
    local r=love.math.random

    local leeway = g.getWorldEdgeLeeway()
    local ww,hh = g.getWorldDimensions()

    local isVert = r()<0.3--higher chance to move horizontal

    local tokX,tokY, endX, endY

    if isVert then
        local startY = helper.lerp(0.1*hh, 0.9*hh, r())
        local worldEndY = helper.lerp(0.1*hh, 0.9*hh, r())
        tokX, tokY = (r()<0.5 and -leeway or ww+leeway), startY
        endX, endY = (tokX < 0 and ww+leeway or -leeway), worldEndY
    else
        local startX = helper.lerp(0.1*ww, 0.9*ww, r())
        local worldEndX = helper.lerp(0.1*ww, 0.9*ww, r())
        tokX, tokY = startX, (r()<0.5 and -leeway or hh+leeway)
        endX, endY = worldEndX, (tokY < 0 and hh+leeway or -leeway)
    end

    -- Total distance the token travels
    local dx, dy = endX - tokX, endY - tokY
    -- Distance across the primary world dimension
    local worldDist = isVert and ww or hh
    -- Speed to cross world dimension in 'duration' time
    local speed = worldDist / duration
    -- Total path length
    local pathLength = math.sqrt(dx*dx + dy*dy)
    -- Time to travel the full path at this speed
    local totalTime = pathLength / speed
    local vx, vy = dx / totalTime, dy / totalTime

    tok.x = tokX
    tok.y = tokY
    tok.flight = {
        vx = vx, vy = vy
    }
end



do

local RANDOM_PATH_DURATION = 5

---@param startX number
---@param startY number
---@param endX number
---@param endY number
---@param duration number
local function getVelocityByPoints(startX, startY, endX, endY, duration)
    -- Total distance the token travels
    local dx, dy = endX - startX, endY - startY
    local vx, vy = dx / duration, dy / duration
    return vx, vy
end

---@param tok g.Token
---@param initduration number
---@param hoverduration number
---@param endduration number
function worldutil.updateBossTokenFlypath(tok, initduration, hoverduration, endduration)
    local activeTime = tok.timeAlive - initduration
    if tok.timeAlive < initduration then
        if not tok.flight then
            -- Phase 1: Boss token moves to center
            local leeway = g.getWorldEdgeLeeway()
            local ww,hh = g.getWorldDimensions()
            local startY = helper.lerp(0.1 * hh, 0.9*hh, love.math.random())
            local startX = helper.lerp(-leeway, ww+leeway, love.math.random() >= 0.5 and 0 or 1)
            local endX, endY = ww / 2, hh / 2
            local vx, vy = getVelocityByPoints(startX, startY, endX, endY, initduration)
            tok.x, tok.y = startX, startY
            tok.flight = {vx = vx, vy = vy}
        end
    elseif activeTime >= 0 and activeTime < hoverduration then
        -- Phase 2: make boss goes in random path every RANDOM_PATH_DURATION seconds
        local index = math.floor(tok.timeAlive / RANDOM_PATH_DURATION)
        if tok.bossPathIndex ~= index then
            local hash = tok.id - index * 1000
            local ww,hh = g.getWorldDimensions()
            local endX = helper.lerp(0, ww, helper.hashInteger(hash) / 4294967296)
            local endY = helper.lerp(0, hh, helper.hashInteger(-hash) / 4294967296)
            local vx, vy = getVelocityByPoints(tok.x, tok.y, endX, endY, 10)
            tok.flight.vx, tok.flight.vy = vx, vy
            ---@diagnostic disable-next-line: inject-field
            tok.bossPathIndex = index
        end
    elseif tok.timeAlive >= initduration + hoverduration then
        -- Phase 3: Make token goes offscreen
        local leeway = g.getWorldEdgeLeeway()
        local ww,hh = g.getWorldDimensions()
        local endX = helper.lerp(-leeway, ww+leeway, helper.hashInteger(-tok.id) / 4294967295 >= 0.5 and 0 or 1)
        local endY = helper.lerp(-leeway, hh+leeway, helper.hashInteger(tok.id) / 4294967295)
        tok.flight.vx, tok.flight.vy = getVelocityByPoints(ww / 2, hh / 2, endX, endY, endduration)
    end
end

end



-- worldutil.initializeFlyingTokenWithPos(tok, duration)
do
local SAMPLES = 3

--- initializes a flying token, which will fly off-screen in a random
--- direction. (prioritizes long distances)
---@param tok g.Token
---@param duration number How long it takes to travel off screen
function worldutil.initializeFlyingTokenWithPos(tok, duration)
    local x, y = tok.x, tok.y

    local ww, hh = g.getWorldDimensions()

    -- Sample X random points on world perimeter, keep the furthest.
    -- (This ensures token doesnt just spawn, then travel off-screen)
    local targetX, targetY
    local bestDist = 0

    for _ = 1, SAMPLES do
        local tx, ty = helper.getRandomPositionOnEdge(0, 0, ww, hh)
        local dist = math.sqrt((tx - x)^2 + (ty - y)^2)
        if dist > bestDist then
            bestDist = dist
            targetX, targetY = tx, ty
        end
    end
    -- Calculate velocity to reach target in given duration
    local vx = (targetX - x) / duration
    local vy = (targetY - y) / duration
    tok.flight = {
        vx = vx, vy = vy
    }
end

end



---@param x number
---@param y number
---@param rad number radius (visual only)
---@param t number world time (positive = outward, negative = inward)
---@param nwave integer? (default 5)
function worldutil.drawWaveAnimation(x, y, rad, t, nwave)
    if g.isBeingSimulated() then return end

    nwave = nwave or 5
    local basePosition = t % 1
    local r, g, b, a = love.graphics.getColor()
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(rad / nwave / 2)
    for i = 1, nwave do
        local pos = (basePosition + i / nwave) % 1
        local alpha = helper.clamp(math.sin(pos * math.pi), 0, 1)
        love.graphics.setColor(r, g, b, a * alpha)
        love.graphics.circle("line", x, y, pos * rad)
    end
    love.graphics.setLineWidth(lw)
    love.graphics.setColor(r, g, b, a)
end


return worldutil
