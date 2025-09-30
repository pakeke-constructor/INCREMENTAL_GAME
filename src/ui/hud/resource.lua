local objects = require("src.modules.objects.objects")

---@class g.hud.Resources: objects.Class
local Resources = objects.Class("g.hud:Resources")
Resources._moneyFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 32, "mono")
Resources._resourceFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 24, "mono")

---@class g.hud._ResourceParticle
---@field package kind g.ResourceType
---@field package amount integer
---@field package image string
---@field package tokenAngle number (angle between x,y and token position)
---@field package tokenRadius number (radius between x,y and token position)
---@field package spawnEasing fun(x:number):number
---@field package rot number
---@field package x number (offsetted from tokenAngle and tokenRadius)
---@field package y number (offsetted from tokenAngle and tokenRadius)
---@field package xEasing fun(x:number):number
---@field package yEasing fun(x:number):number
---@field package time number
---@field package tohudTime number

local SPAWN_ANIMATION_DURATION = 0.05
local AFTERSPAWN_ANIMATION_DELAY = 0.06
local TOHUD_ANIMATION_DURATION = {0.4, 0.5} -- random between these
local BEFOREHUD_TIME = SPAWN_ANIMATION_DURATION + AFTERSPAWN_ANIMATION_DELAY
local RANDOM_DELAY = 0.25 -- Random delay before the particle is spawned.
local PARTICLE_HUD_VISUAL_ATTENTION_DURATION = 0.5

local PARTICLE_SPAWN_CATEGORY = {
    money = {
        format = "money_particle_%d",
        counts = {1, 10, 100, 1000},
    },
    logs = {
        format = "log_particle_%d",
        counts = {1, 10, 100},
    },
    rocks = {
        format = "rock_particle_%d",
        counts = {1, 10},
    },
    bones = {
        format = "bone_particle_%d",
        counts = {1, 10, 100},
    },
}
local AROUND_TOKEN_RADIUS = 10

-- All these are sine
---@type (fun(x:number):number)[]
local EASINGS = {
    -- in
    function(x) return 1 - math.cos((x * math.pi) / 2) end,
    -- out
    function(x) return math.sin((x * math.pi) / 2) end,
    -- inout
    function(x) return -(math.cos(math.pi * x) - 1) / 2 end
}

---@type g.ResourceType[]
local RESOURCE_KIND_LIST = {"money", "logs", "rocks", "bones"}

function Resources:init()
    ---@type g.hud._ResourceParticle[]
    self.particles = {}

    self.poses = {
        money = {0, 0},
        logs = {0, 0},
        rocks = {0, 0},
        bones = {0, 0},
    }
    -- Shown value
    self.displayValue = {
        money = 0,
        logs = 0,
        rocks = 0,
        bones = 0,
    }
    -- Used for animation interpolation (e.g. increasing text scale)
    self.timeSinceChanged = {
        money = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        logs = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        rocks = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        bones = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
    }
end

if false then
    ---@return g.hud.Resources
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Resources() end
end

---@param dt number
function Resources:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]

        p.time = p.time + dt
        if p.time >= BEFOREHUD_TIME + p.tohudTime then
            table.remove(self.particles, i)
            self.displayValue[p.kind] = math.min(self.displayValue[p.kind] + p.amount, g.getResource(p.kind))
            self.timeSinceChanged[p.kind] = 0
        end
    end

    for _, kind in ipairs(RESOURCE_KIND_LIST) do
        local truthValue = g.getResource(kind)
        -- If truth value is less than the display value, reset.
        self.displayValue[kind] = math.min(self.displayValue[kind], truthValue)
        self.timeSinceChanged[kind] = self.timeSinceChanged[kind] + dt
    end
end

---@param text string
---@param font love.Font
---@param region layout.Region
---@param align love.AlignMode
---@param scale number?
local function printTextAt(text, font, region, align, scale)
    scale = scale or 1
    local x, y, w, h = region:get()
    local maxw, lines = font:getWrap(text, w)

    local th = #lines * font:getHeight()
    local tx = x + w / 2 -- default center
    local ty = y + h / 2

    if align == "left" then
        tx = tx - (w - maxw) / 2
    elseif align == "right" then
        tx = tx + (w - maxw) / 2
    end

    love.graphics.printf(text, font, tx, ty, maxw, "left", 0, scale, scale, maxw / 2, th / 2)
end

---@param x number
local function easeInCubic(x)
    return x * x * x
end

---@param kind g.ResourceType
---@param reg layout.Region
---@param image string
---@param scale number
---@param bgcolor [number, number, number, number?]
---@param barcolor [number, number, number, number?]
function Resources:_drawResourcesMeter(kind, reg, image, scale, bgcolor, barcolor)
    local iconR = reg:shrinkToAspectRatio(1, 1):attachToLeftOf(reg):moveRatio(1, 0):padUnit(4)
    local textR = reg:attachToRightOf(iconR):padUnit(4, 6)

    ui.debugRegion(iconR)
    ui.debugRegion(textR)

    -- Draw resource icon
    local icx, icy = iconR:getCenter()
    g.drawImage(image, icx, icy, 0, 1.5 * scale)

    -- Draw meter
    love.graphics.setColor(bgcolor)
    love.graphics.setStencilMode("draw", 1)
    -- Explicitly enable color mask.
    -- We want to draw the jagged rectangle AND the stencil at same time
    love.graphics.setColorMask(true, true, true, true)
    ui.jaggedRectangleRegion("fill", textR, 8)

    -- Enter test mode to just draw rectangle with stencil test active
    local tx, ty, tw, th = textR:get()
    love.graphics.setColor(barcolor)
    love.graphics.setStencilMode("test", 1)
    love.graphics.rectangle("fill", tx, ty, tw * self.displayValue[kind] / math.max(g.getResourceLimit(kind), 1), th)

    -- Disable stencil test to draw outline.
    love.graphics.setStencilMode()
    love.graphics.setColor(0, 0, 0)
    ui.jaggedRectangleRegion("line", textR, 8)

    -- Draw resource value
    local t = self:_getInterpolationTime(kind)
    love.graphics.setColor(1, 1, 1)
    printTextAt(
        g.formatNumber(self.displayValue[kind]),
        self._resourceFont,
        textR:padUnit(8, 0, 0, 0),
        "left",
        (1 + easeInCubic(1 - t) * 0.5) * scale
    )

    return iconR:getCenter()
end

---@param camera Camera
function Resources:drawHUD(camera)
    if not g.getSn() then return end

    local r = Kirigami(0,0,ui.getScaledUIDimensions())
    local moneyR = Kirigami(0, 0, 160, 50)
        :attachToTopOf(r)
        :attachToLeftOf(r)
        :moveRatio(1, 1)
        :moveUnit(4, 4)
    local baseResourceR = Kirigami(0, 0, 100, 32):moveUnit(4, 4)
    -- TODO: Replace this with loop once we have generic resources.
    local logsR = baseResourceR:attachToBottomOf(moneyR):moveUnit(0, 4)
    local rocksR = baseResourceR:attachToBottomOf(logsR):moveUnit(0, 4)
    local bonesR = baseResourceR:attachToBottomOf(rocksR):moveUnit(0, 4)

    -- Draw resource
    love.graphics.setColor(1, 1, 1)
    local ux, uy = love.graphics.transformPoint(
        self:_drawResourcesMeter("money", moneyR, "money_icon", 1.5, {0.31, 0.26, 0.01}, {0.71, 0.55, 0.02})
    )
    self.poses.money[1], self.poses.money[2] = camera:toWorld(ux, uy)
    ux, uy = love.graphics.transformPoint(
        self:_drawResourcesMeter("logs", logsR, "logs_icon", 1, {0.34, 0.32, 0.27}, {0.53, 0.5, 0.41})
    )
    self.poses.logs[1], self.poses.logs[2] = camera:toWorld(ux, uy)
    ux, uy = love.graphics.transformPoint(
        self:_drawResourcesMeter("rocks", rocksR, "rocks_icon", 1, {0.23, 0.23, 0.23}, {0.35, 0.35, 0.35})
    )
    self.poses.rocks[1], self.poses.rocks[2] = camera:toWorld(ux, uy)
    ux, uy = love.graphics.transformPoint(
        self:_drawResourcesMeter("bones", bonesR, "bones_icon", 1, {0.41, 0.11, 0.01}, {0.75, 0.27, 0.1})
    )
    self.poses.bones[1], self.poses.bones[2] = camera:toWorld(ux, uy)
end



---@param a number
---@param b number
---@param t number
---@return number
local function lerp(a, b, t)
    return (1.0 - t) * a + t * b
end

---@param camera Camera
function Resources:drawParticles(camera)
    for _, particle in ipairs(self.particles) do
        -- Time can be negative to delay it slightly
        if particle.time >= 0 then
            local x, y, scale

            -- Which phase are we in?
            if particle.time < SPAWN_ANIMATION_DURATION then
                -- Spawning
                local t = particle.time / SPAWN_ANIMATION_DURATION
                local easeT = math.min(math.max(particle.spawnEasing(t), 0), 1)
                x = particle.x - math.cos(particle.tokenAngle) * particle.tokenRadius * (1 - easeT)
                y = particle.y - math.sin(particle.tokenAngle) * particle.tokenRadius * (1 - easeT)
                scale = easeT
            elseif particle.time < BEFOREHUD_TIME then
                -- Idling
                x = particle.x
                y = particle.y
                scale = 1
            else
                -- Moving to HUD
                local t = (particle.time - BEFOREHUD_TIME) / particle.tohudTime
                local easeX = math.min(math.max(particle.xEasing(t), 0), 1)
                local easeY = math.min(math.max(particle.yEasing(t), 0), 1)

                x = lerp(particle.x, self.poses[particle.kind][1], easeX)
                y = lerp(particle.y, self.poses[particle.kind][2], easeY)
                scale = 1
            end

            g.drawImage(particle.image, x, y, particle.rot, scale)
        end
    end
end

---@param camera Camera
function Resources:draw(camera)
    self:drawHUD(camera)
    camera:attach()
    self:drawParticles(camera)
    camera:detach()
end

---@generic T
---@param tab T[] Table to pick elements of.
---@param rng (fun(max:integer):integer)? Function that returns random number from 1 to `max` both inclusive.
---@return T
local function choice(tab, rng)
    rng = rng or love.math.random
    return tab[rng(#tab)]
end

---@param kind g.ResourceType
---@param tier integer
---@param x number
---@param y number
---@param amount integer
---@private
function Resources:_spawnParticleImpl(kind, tier, x, y, amount)
    local smallAmount = 0
    -- 20% chance to spawn 1 additional smaller particles
    if tier > 1 and love.math.random() < 0.2 then
        smallAmount = math.ceil(amount * 0.9)
        amount = amount - smallAmount
    end

    local category = PARTICLE_SPAWN_CATEGORY[kind]

    local angle = math.rad(love.math.random() * 360)
    local radius = love.math.random() * AROUND_TOKEN_RADIUS
    local px = x + math.cos(angle) * radius
    local py = y + math.sin(angle) * radius

    self.particles[#self.particles+1] = {
        kind = kind,
        amount = amount,
        image = string.format(category.format, tier),
        tokenAngle = angle,
        rot = love.math.random() * (2*math.pi),
        tokenRadius = radius,
        spawnEasing = choice(EASINGS),
        x = px,
        y = py,
        xEasing = choice(EASINGS),
        yEasing = choice(EASINGS),
        time = -RANDOM_DELAY * love.math.random(),
        tohudTime = lerp(TOHUD_ANIMATION_DURATION[1], TOHUD_ANIMATION_DURATION[2], love.math.random())
    }

    if smallAmount > 0 then
        return self:_spawnParticleImpl(kind, tier - 1, x, y, smallAmount)
    end
end

---From 0 to 1.
---@param kind g.ResourceType
function Resources:_getInterpolationTime(kind)
    return math.min(self.timeSinceChanged[kind] / PARTICLE_HUD_VISUAL_ATTENTION_DURATION, 1)
end


---@param kind g.ResourceType
---@param x number Position of the token in world-space.
---@param y number Position of the token in world-space.
---@param amount number Amount to add to the display once it's done.
function Resources:spawnParticle(kind, x, y, amount)
    if amount <= 0 then return end

    local category = PARTICLE_SPAWN_CATEGORY[kind]
    ---@type number[]
    local tiersToSpawn = {}

    for i = #category.counts, 1, -1 do
        local spawnCount = math.floor(amount / category.counts[i])
        amount = amount - spawnCount * category.counts[i]
        table.insert(tiersToSpawn, 1, spawnCount)
    end

    assert(amount == 0)

    for tier, spawnCount in ipairs(tiersToSpawn) do
        local spawnAmount = category.counts[tier]
        for _ = 1, spawnCount do
            self:_spawnParticleImpl(kind, tier, x, y, spawnAmount)
        end
    end
end

return Resources
