---@class g.hud.Resources: objects.Class
local Resources = objects.Class("g.hud:Resources")

---@class g.hud._ResourceParticle
---@field package kind g.ResourceType
---@field package amount integer
---@field package image string
---@field package spawnEasing fun(x:number):number
---@field package rot number
---@field package x number (offsetted from tokenAngle and tokenRadius)
---@field package y number (offsetted from tokenAngle and tokenRadius)
---@field package xEasing fun(x:number):number
---@field package yEasing fun(x:number):number
---@field package time number
---@field package tohudTime number

local SPAWN_ANIMATION_DURATION = 0.025
local AFTERSPAWN_ANIMATION_DELAY = 0.06
local PARTICLE_SPEED = 550
local BEFOREHUD_TIME = SPAWN_ANIMATION_DURATION + AFTERSPAWN_ANIMATION_DELAY
local RANDOM_DELAY = 0.25 -- Random delay before the particle is spawned.
local PARTICLE_HUD_VISUAL_ATTENTION_DURATION = 0.3

local PARTICLE_SPAWN_CATEGORY = {
    money = {
        format = "money_particle_%d",
        counts = {1, 10, 100, 1000},
    },
    fabric = {
        format = "money_particle_%d",
        counts = {1, 10, 100, 1000},
    },
    juice = {
        format = "money_particle_%d",
        counts = {1, 10, 100, 1000},
    },
    bread = {
        format = "money_particle_%d",
        counts = {1, 10, 100, 1000},
    },
    fish = {
        format = "money_particle_%d",
        counts = {1, 10, 100, 1000},
    },
}

local RESOURCE_HUD_BGS = {
    money = {"resource_bg1", "resource_bg1_filled"},
    juice = {"resource_bg2", "resource_bg2_filled"},
    fabric = {"resource_bg3", "resource_bg3_filled"},
    bread = {"resource_bg4", "resource_bg4_filled"},
    fish = {"resource_bg5", "resource_bg5_filled"},
}

local EASINGS = {"sineIn", "sineOut", "sineInOut"}

function Resources:init()
    ---@type g.hud._ResourceParticle[]
    self.particles = {}

    self.poses = {
        money = {0, 0},
        fabric = {0, 0},
        bread = {0, 0},
        fish = {0,0},
        juice = {0, 0},
    }

    -- Shown value
    self.displayValue = {
        money = 0,
        fabric = 0,
        fish = 0,
        bread = 0,
        juice = 0,
    }

    -- Used for animation interpolation (e.g. increasing text scale)
    self.timeSinceChanged = {
        money = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        fabric = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        bread = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        fish = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
        juice = PARTICLE_HUD_VISUAL_ATTENTION_DURATION,
    }

    self.freeArea = Kirigami(0, 0, ui.getScaledUIDimensions())
end

if false then
    ---@return g.hud.Resources
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Resources() end
end

---@param dt number
function Resources:update(dt)
    local resourcesInFlight = {}
    -- the amount of resources that are currently flying towards HUD

    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        resourcesInFlight[p.kind] = (resourcesInFlight[p.kind] or 0) + p.amount

        p.time = p.time + dt
        if p.time >= p.tohudTime then
            -- particle hit!
            table.remove(self.particles, i)
            self.timeSinceChanged[p.kind] = 0
        end
    end

    for _, kind in ipairs(g.RESOURCE_LIST) do
        local truthValue = g.getResource(kind)
        local limit = g.getResourceLimit(kind)
        local amount = resourcesInFlight[kind] or 0
        if truthValue == limit then
            -- dont subtract resources if its at limit.
            amount = 0
        end
        self.displayValue[kind] = truthValue - amount
        self.timeSinceChanged[kind] = self.timeSinceChanged[kind] + dt
    end
end

---@param text string
---@param font love.Font
---@param region kirigami.Region
---@param align love.AlignMode
---@param baseScale number?
---@param scale number?
local function printTextAt(text, font, region, align, baseScale, scale)
    baseScale = baseScale or 1
    scale = scale or 1
    local x, y, w, h = region:get()

    local s = baseScale * scale
    richtext.printRich(text, font, x, y, w / s, align, 0, s, s)
end

---@param x number
local function easeInCubic(x)
    return x * x * x
end

---@param self g.hud.Resources
---@param kind g.ResourceType
---@param x number
---@param y number
---@param image string
---@param scale number
---@param barimage string
---@param barimagefill string
---@param noDraw boolean?
local function _drawResourcesMeter(self, kind, x, y, image, scale, barimage, barimagefill, noDraw)
    local bw, bh = select(3, g.getImageQuad(barimage):getViewport())
    local reg = Kirigami(x, y, bw * scale, bh * scale)
    local iconR = reg
        :shrinkToAspectRatio(1, 1)
        :shrinkToMultipleOf(16)
        :attachToLeftOf(reg)
        :centerY(reg)
        :moveRatio(1, 0)
    local textR = reg
        :moveUnit(iconR.w)
        :intersection(reg)
    local t = self:_getInterpolationTime(kind)

    if not noDraw then
        -- Draw bar background (unfilled)
        love.graphics.setColor(1, 1, 1)
        g.drawImageOffset(barimage, x, y, 0, scale, scale, 0, 0)

        -- Draw filled bar (potentially partially filled)
        local q = helper.cloneQuad(g.getImageQuad(barimagefill))
        local fillVal = self.displayValue[kind] / math.max(g.getResourceLimit(kind), 1)
        do
            -- Compute bar width
            local qx, qy, qw, qh = q:getViewport()
            local mult = helper.clamp(fillVal, 0, 1)
            q:setViewport(qx, qy, qw * mult, qh)
        end
        -- Cannot use g.drawImageOffset here because we're using different quad.
        -- Don't worry, it's still batched though.
        love.graphics.draw(g.getAtlas(), q, x, y, 0, scale, scale)
        q:release()

        -- Draw resource value
        love.graphics.setColor(1, 1, 1)
        local font = g.getBigFont(16)
        local r = textR
            :set(nil, nil, nil, font:getHeight())
            :padUnit(4, 0, 8, 0)
            :centerY(textR)
            :moveUnit(0, math.sin(love.timer.getTime()*3) - 1)

        local richtxt = "{o}"..g.formatNumber(math.max(0,self.displayValue[kind])).."{/o}"
        local isFull = fillVal >= 1
        if isFull then
            richtxt = helper.wrapRichtextColor({1,0.2,0.2}, richtxt)
        end
        printTextAt(
            richtxt,
            font,
            r,
            "left",
            scale,
            1 + easeInCubic(1 - t) * 0.25
        )

        -- Draw resource icon
        local icx, icy = iconR:getCenter()
        g.drawImage(image, icx, icy, 0, scale * helper.lerp(1, 1.25, (1 - t) ^ 2))
    end

    local ux, uy = iconR:getCenter()
    return ux, uy, reg.x + reg.w
end

---@param noDraw boolean?
function Resources:drawHUD(noDraw)
    if not g.getSn() then return end

    local r = Kirigami(0,0,ui.getScaledUIDimensions())

    -- Draw resources
    local BASE_X = 8
    local BASE_Y = 8
    local leftPad = 0 -- For free area computation
    local freeX = 0

    love.graphics.setColor(1, 1, 1)
    local indices = 0
    for i, resId in ipairs(g.RESOURCE_LIST) do
        if g.isResourceUnlocked(resId) then
            local usedBarImage = RESOURCE_HUD_BGS[resId]
            local resInfo = g.getResourceInfo(resId)

            local icx, icy, currentFreeX = _drawResourcesMeter(
                self,
                resId,
                BASE_X, BASE_Y + 32 * indices,
                resInfo.image, 1,
                usedBarImage[1], usedBarImage[2],
                noDraw
            )
            local pos = self.poses[resId]
            pos[1], pos[2] = icx, icy
            indices = indices + 1
            freeX = math.max(freeX, currentFreeX)
        end
    end

    self.freeArea = r:padUnit(freeX, 0, 0, 0)
end

function Resources:getSafeArea()
    return self.freeArea:set()
end



local lerp = helper.lerp


function Resources:drawParticles()
    love.graphics.setColor(1,1,1)
    for _, particle in ipairs(self.particles) do
        local x = particle.x
        local y = particle.y
        local scale = 1

        -- Which phase are we in?
        if particle.time < 0 then
            -- Spawning
            local time = -(particle.time + AFTERSPAWN_ANIMATION_DELAY)
            local t = 1 - helper.clamp(time / SPAWN_ANIMATION_DURATION, 0, 1)
            scale = helper.clamp(particle.spawnEasing(t), 0, 1)
        else
            -- Moving to HUD
            local t = particle.time / particle.tohudTime
            local easeX = helper.clamp(particle.xEasing(t), 0, 1)
            local easeY = helper.clamp(particle.yEasing(t), 0, 1)

            x = lerp(particle.x, self.poses[particle.kind][1], easeX)
            y = lerp(particle.y, self.poses[particle.kind][2], easeY)
        end

        g.drawImage(particle.image, x, y, particle.rot, scale)
    end
end

---@param noDraw boolean?
function Resources:draw(noDraw)
    self:drawParticles()
    self:drawHUD(noDraw)
end


---@param self g.hud.Resources
---@param kind g.ResourceType
---@param tier integer
---@param x number
---@param y number
---@param amount integer
local function _spawnParticleImpl(self, kind, tier, x, y, amount)
    local smallAmount = 0
    -- 20% chance to spawn 1 additional smaller particles
    if tier > 1 and love.math.random() < 0.2 then
        smallAmount = math.ceil(amount * 0.9)
        amount = amount - smallAmount
    end

    local category = PARTICLE_SPAWN_CATEGORY[kind]
    local resPos = self.poses[kind]

    local lifetime = helper.magnitude(resPos[1]-x, resPos[2]-y) / PARTICLE_SPEED

    self.particles[#self.particles+1] = {
        kind = kind,
        amount = amount,
        image = string.format(category.format, tier),
        rot = love.math.random() * (2*math.pi),
        spawnEasing = helper.EASINGS[helper.randomChoice(EASINGS)],
        x = x,
        y = y,
        xEasing = helper.EASINGS[helper.randomChoice(EASINGS)],
        yEasing = helper.EASINGS[helper.randomChoice(EASINGS)],
        time = -RANDOM_DELAY * love.math.random() - BEFOREHUD_TIME,
        tohudTime = lifetime
    }

    if smallAmount > 0 then
        _spawnParticleImpl(self, kind, tier - 1, x, y, smallAmount)
    end
end

---From 0 to 1.
---@param kind g.ResourceType
function Resources:_getInterpolationTime(kind)
    return math.min(self.timeSinceChanged[kind] / PARTICLE_HUD_VISUAL_ATTENTION_DURATION, 1)
end


---@param kind g.ResourceType
---@param x number Position of the token (same coordinate space as HUD)
---@param y number Position of the token (same coordinate space as HUD)
---@param amount number Amount to add to the display once it's done.
function Resources:spawnParticles(kind, x, y, amount)
    if amount <= 0 then return end
    amount = math.floor(amount)

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
            _spawnParticleImpl(self, kind, tier, x, y, spawnAmount)
        end
    end
end

return Resources
