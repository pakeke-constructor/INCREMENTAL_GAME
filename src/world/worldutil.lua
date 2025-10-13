local worldutil = {}


---@param x number
---@param y number
---@param rad number
---@param circleColor objects.Color
---@param circleBorderColor objects.Color
function worldutil.drawHarvestCircle(x, y, rad, circleColor, circleBorderColor)
    love.graphics.setColor(circleColor)
    love.graphics.circle("fill", x,y, rad)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.floor(rad / 15))
    love.graphics.setColor(circleBorderColor)
    love.graphics.circle("line", x,y, rad)
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

---@param world g.World
---@param obj {x:number,y:number,dirX:number,dirY:number,speed:number}
---@param dt number
function worldutil.updateLikeDVD(world, obj, dt)
    local flip

    obj.x, flip = computeValueBouncing(dt, obj.x, obj.speed * obj.dirX, world.WIDTH)
    if flip then
        obj.dirX = -obj.dirX
    end

    obj.y, flip = computeValueBouncing(dt, obj.y, obj.speed * obj.dirY, world.HEIGHT)
    if flip then
        obj.dirY = -obj.dirY
    end
end



-- worldutil.lifetimeAnimationUpdater
-- for animation of entities with lifetime comp
do

local function makeFrames(framePrefix, numFrames)
    local t = {}
    for i=1, numFrames do
        table.insert(t, framePrefix .. tostring(i))
    end
    return t
end

---@param framePrefix string
function worldutil.lifetimeAnimationUpdater(framePrefix, numFrames)
    local frames = nil

    local function update(ent, dt)
        -- SLIGHT HACK: tapping into __index
        local parentLifetime = getmetatable(ent).__index.lifetime

        assert(ent.lifetime)
        assert(parentLifetime)

        frames = frames or makeFrames(framePrefix, numFrames)
        local i = math.floor((ent.lifetime/parentLifetime) * #frames) + 1
        local frame = frames[i]
        ent.image = frame
    end

    return update
end

end




---@param x any
---@param y any
---@param damage any
function worldutil.spawnLightning(x,y,damage)
    g.spawnEntity("lightning_animation", x,y)
    g.iterateTokensInArea(x,y, 32, function(tok)
        g.damageToken(tok,damage)
    end)
end


return worldutil
