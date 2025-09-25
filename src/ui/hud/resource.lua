local objects = require("src.modules.objects.objects")

---@class g.hud.Resources: objects.Class
local Resources = objects.Class("g.hud:Resources")
Resources._moneyFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 32, "mono")
Resources._resourceFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 24, "mono")

---@alias g.hud._ResourceKind "money"|"logs"|"rocks"|"bones"

---@class g.hud._ResourceParticle
---@field package kind g.hud._ResourceKind
---@field package amount integer
---@field package image string
---@field package tokenAngle number (angle between x,y and token position)
---@field package tokenRadius number (radius between x,y and token position)
---@field package spawnEasing fun(x:number):number
---@field package x number (offsetted from tokenAngle and tokenRadius)
---@field package y number (offsetted from tokenAngle and tokenRadius)
---@field package xEasing fun(x:number):number
---@field package yEasing fun(x:number):number
---@field package time number
---@field package tohudTime number

local SPAWN_ANIMATION_DURATION = 0.1
local AFTERSPAWN_ANIMATION_DELAY = 0.1
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
    -- Initial value
    self.displayValueBefore = {
        money = 0,
        logs = 0,
        rocks = 0,
        bones = 0,
    }
    -- Target value
    self.displayValueAfter = {
        money = 0,
        logs = 0,
        rocks = 0,
        bones = 0,
    }
    self.interpolateTime = {
        money = 0,
        logs = 0,
        rocks = 0,
        bones = 0,
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
        local particle = self.particles[i]

        particle.time = particle.time + dt
        if particle.time >= BEFOREHUD_TIME + particle.tohudTime then
            table.remove(self.particles, i)
            self:_animateHudFor(particle.kind, particle.amount)
        end
    end

    for _, kind in ipairs(RESOURCE_KIND_LIST) do
        self.interpolateTime[kind] = math.max(self.interpolateTime[kind] - dt, 0)
        if self.interpolateTime[kind] <= 0 then
            self.displayValueBefore[kind] = self.displayValueAfter[kind]
        end
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

---@param reg layout.Region
local function makeIconAndTextRegion(reg)
    local iconR = reg:shrinkToAspectRatio(1, 1):attachToLeftOf(reg):moveRatio(1, 0)
    local textR = reg:attachToRightOf(iconR)
    return iconR:padUnit(4), textR
end

---@param camera Camera
function Resources:drawHUD(camera)
    if not g.getSn() then return end

    local r = Kirigami(0,0,love.graphics.getDimensions())
    local leftR = r:splitHorizontal(1, 1, 1, 1, 1)
    local moneyR = leftR:shrinkToAspectRatio(2, 1):attachToTopOf(r):moveRatio(0, 1):padRatio(0.05)
    local resourcesR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(moneyR):padRatio(0.05)

    -- Draw money
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", moneyR:get())
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("line", moneyR:get())
    love.graphics.setColor(0, 0, 0)
    local value, t = self:_getDisplayValueFor("money")
    printTextAt("$"..g.formatNumber(value), self._moneyFont, moneyR, "center", 1 + easeInCubic(t) * 0.5)

    -- Prepare resource layout
    local logsR, rocksR, bonesR = resourcesR:splitVertical(1, 1, 1)
    local logsIconR, logsTextR = makeIconAndTextRegion(logsR)
    local rocksIconR, rocksTextR = makeIconAndTextRegion(rocksR)
    local bonesIconR, bonesTextR = makeIconAndTextRegion(bonesR)

    -- Draw resource text
    love.graphics.setColor(1, 1, 1)
    value, t = self:_getDisplayValueFor("logs")
    printTextAt(g.formatNumber(value), self._resourceFont, logsTextR, "left", 1 + easeInCubic(t) * 0.5)
    value, t = self:_getDisplayValueFor("rocks")
    printTextAt(g.formatNumber(value), self._resourceFont, rocksTextR, "left", 1 + easeInCubic(t) * 0.5)
    value, t = self:_getDisplayValueFor("bones")
    printTextAt(g.formatNumber(value), self._resourceFont, bonesTextR, "left", 1 + easeInCubic(t) * 0.5)

    -- Draw resource icon
    local icx, icy = logsIconR:getCenter()
    g.drawImage("logs_icon", icx, icy, 0, 1.5)
    icx, icy = rocksIconR:getCenter()
    g.drawImage("rocks_icon", icx, icy, 0, 1.5)
    icx, icy = bonesIconR:getCenter()
    g.drawImage("bones_icon", icx, icy, 0, 1.5)

    self.poses.money[1], self.poses.money[2] = camera:toWorld(moneyR:getCenter())
    self.poses.logs[1], self.poses.logs[2] = camera:toWorld(logsIconR:getCenter())
    self.poses.rocks[1], self.poses.rocks[2] = camera:toWorld(rocksIconR:getCenter())
    self.poses.bones[1], self.poses.bones[2] = camera:toWorld(bonesIconR:getCenter())
end



---@param a number
---@param b number
---@param t number
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

            local sx, sy = camera:toScreen(x, y)
            g.drawImage(particle.image, sx, sy, 0, scale)
        end
    end
end

---@param camera Camera
function Resources:draw(camera)
    self:drawHUD(camera)
    return self:drawParticles(camera)
end

function Resources:reset()
    if not g.getSn() then return end

    self.displayValueAfter.money = g.getMoney()
    self.displayValueAfter.logs = g.getLogs()
    self.displayValueAfter.rocks = g.getRocks()
    self.displayValueAfter.bones = g.getBones()

    for _, kind in ipairs(RESOURCE_KIND_LIST) do
        self.displayValueBefore[kind] = self.displayValueAfter[kind]
        self.interpolateTime[kind] = 0
    end

    self.particles = {}
end

---@generic T
---@param tab T[] Table to pick elements of.
---@param rng (fun(max:integer):integer)? Function that returns random number from 1 to `max` both inclusive.
---@return T
local function choice(tab, rng)
    rng = rng or love.math.random
    return tab[rng(#tab)]
end

---@param kind g.hud._ResourceKind
---@param tier integer
---@param x number
---@param y number
---@param amount integer
---@private
function Resources:_spawnParticleImpl(kind, tier, x, y, amount)
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
        tokenRadius = radius,
        spawnEasing = choice(EASINGS),
        x = px,
        y = py,
        xEasing = choice(EASINGS),
        yEasing = choice(EASINGS),
        time = -RANDOM_DELAY * love.math.random(),
        tohudTime = lerp(TOHUD_ANIMATION_DURATION[1], TOHUD_ANIMATION_DURATION[2], love.math.random())
    }

    -- 20% chance to spawn 1 additional cosmetic particles
    if tier > 1 and love.math.random() < 0.2 then
        self:_spawnParticleImpl(kind, tier - 1, x, y, 0)
    end
end

---@param kind g.hud._ResourceKind
function Resources:_getDisplayValueFor(kind)
    local t = self.interpolateTime[kind] / PARTICLE_HUD_VISUAL_ATTENTION_DURATION
    local easeT = easeInCubic(t)
    return math.ceil(lerp(self.displayValueAfter[kind], self.displayValueBefore[kind], easeT)), t
end

---@param kind g.hud._ResourceKind
---@param incramount integer
function Resources:_animateHudFor(kind, incramount)
    self.displayValueBefore[kind] = self:_getDisplayValueFor(kind)
    self.displayValueAfter[kind] = self.displayValueAfter[kind] + incramount
    self.interpolateTime[kind] = PARTICLE_HUD_VISUAL_ATTENTION_DURATION
end

---@param kind g.hud._ResourceKind
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
