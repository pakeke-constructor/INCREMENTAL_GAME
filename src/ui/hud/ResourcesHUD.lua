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
local PARTICLE_HUD_VISUAL_ATTENTION_DURATION = 0.3

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

local EASINGS = {"sineIn", "sineOut", "sineInOut"}

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
        if p.time >= BEFOREHUD_TIME + p.tohudTime then
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
---@param region layout.Region
---@param align love.AlignMode
---@param baseScale number?
---@param scale number?
local function printTextAt(text, font, region, align, baseScale, scale)
    baseScale = baseScale or 1
    scale = scale or 1
    local x, y, w, h = region:get()
    local maxw, lines = font:getWrap(text, w)

    local th = #lines * font:getHeight()
    local tx = x + w / 2 -- default center
    local ty = y + h / 2

    if align == "left" then
        tx = tx - (w - maxw * baseScale) / 2
    elseif align == "right" then
        tx = tx + (w - maxw * baseScale) / 2
    end

    local s = baseScale * scale
    richtext.printRich(text, font, tx, ty, maxw, "left", 0, s, s, maxw / 2, th / 2)
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
---@param noDraw boolean?
function Resources:_drawResourcesMeter(kind, reg, image, scale, bgcolor, barcolor, noDraw)
    local iconR = reg:shrinkToAspectRatio(1, 1):attachToLeftOf(reg):moveRatio(1, 0):padUnit(4)
    local textR = reg:attachToRightOf(iconR):padUnit(4, 6)
    local t = self:_getInterpolationTime(kind)

    if not noDraw then
        -- Draw resource icon
        local icx, icy = iconR:getCenter()
        g.drawImage(image, icx, icy, 0, 1.5 * (scale + 0.25 * (1 - t) ^ 2))

        local lw = love.graphics.getLineWidth()
        love.graphics.setLineWidth(2)

        -- Draw meter
        love.graphics.setColor(bgcolor)
        love.graphics.setStencilMode("draw", 1)
        -- Explicitly enable color mask.
        -- We want to draw the jagged rectangle AND the stencil at same time
        love.graphics.setColorMask(true, true, true, true)
        ui.jaggedRectangle("fill", 8, textR:get())

        -- Enter stecil test mode to just draw rectangle with stencil test active
        local tx, ty, tw, th = textR:get()
        love.graphics.setColor(barcolor)
        love.graphics.setStencilMode("test", 1)
        love.graphics.rectangle("fill", tx, ty, tw * self.displayValue[kind] / math.max(g.getResourceLimit(kind), 1), th)

        -- Disable stencil test to draw outline.
        love.graphics.setStencilMode()
        love.graphics.setColor(0, 0, 0)
        ui.jaggedRectangle("line", 8, textR:get())

        -- Draw resource value
        love.graphics.setColor(1, 1, 1)
        local r = textR:padUnit(8, 0, 0, 0):moveUnit(0, math.sin(love.timer.getTime()*3)-2)
        printTextAt(
            g.formatNumber(math.max(0,self.displayValue[kind])),
            self._resourceFont,
            r,
            "left",
            scale,
            1 + easeInCubic(1 - t) * 0.25
        )

        love.graphics.setLineWidth(lw)
    end

    local ux, uy = iconR:getCenter()
    return ux, uy, iconR:union(textR)
end

---@param camera Camera
---@param noDraw boolean?
function Resources:drawHUD(camera, noDraw)
    if not g.getSn() then return end

    local r = Kirigami(0,0,ui.getScaledUIDimensions())

    -- Draw resources
    local mainResourceR = Kirigami(0, 0, 140, 40)
        :attachToTopOf(r)
        :attachToLeftOf(r)
        :moveRatio(1, 1)
        :moveUnit(14, 10)
    local otherBaseResourceR = Kirigami(0, 0, 80, 32):moveUnit(14, 4)
    local prevR = nil
    local leftPad = 0 -- For free area computation

    love.graphics.setColor(1, 1, 1)
    for i, resId in ipairs(g.RESOURCE_LIST) do
        if g.isResourceUnlocked(resId) then
            local targetR, scale
            if not prevR then
                -- its money (aka main-resource)
                targetR = mainResourceR
                scale = 1.5
            else
                -- Otherwise, treat it normally
                targetR = otherBaseResourceR:attachToBottomOf(prevR):moveUnit(0, 4)
                scale = 1
                leftPad = targetR.x + targetR.w
            end

            local resInfo = g.getResourceInfo(resId)

            local bgCol = objects.Color(resInfo.color)
            bgCol.value = bgCol.value/2
            bgCol.a = bgCol.a / 3

            local icx, icy, finalR = self:_drawResourcesMeter(
                resId, targetR, resInfo.image, scale,
                bgCol, resInfo.color, noDraw
            )
            local ux, uy = love.graphics.transformPoint(icx, icy)
            local pos = self.poses[resId]
            pos[1], pos[2] = camera:toWorld(ux, uy)

            if prevR then
                leftPad = finalR.x + finalR.w
            end
            prevR = targetR
        end
    end

    self.freeArea = r:padUnit(leftPad, mainResourceR.y + mainResourceR.h, 0, 0)
end

function Resources:getSafeArea()
    return self.freeArea:set()
end



local lerp = helper.lerp


function Resources:drawParticles()
    love.graphics.setColor(1,1,1)
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
                local easeX = helper.clamp(particle.xEasing(t), 0, 1)
                local easeY = helper.clamp(particle.yEasing(t), 0, 1)

                x = lerp(particle.x, self.poses[particle.kind][1], easeX)
                y = lerp(particle.y, self.poses[particle.kind][2], easeY)
                scale = 1
            end

            g.drawImage(particle.image, x, y, particle.rot, scale)
        end
    end
end

---@param camera Camera
---@param noDraw boolean?
function Resources:draw(camera, noDraw)
    camera:attach()
    if not noDraw then
        self:drawParticles()
    end
    camera:detach()
    self:drawHUD(camera, noDraw)
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
        spawnEasing = helper.EASINGS[helper.choice(EASINGS)],
        x = px,
        y = py,
        xEasing = helper.EASINGS[helper.choice(EASINGS)],
        yEasing = helper.EASINGS[helper.choice(EASINGS)],
        time = -RANDOM_DELAY * love.math.random(),
        tohudTime = helper.randrange(TOHUD_ANIMATION_DURATION)
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
---@param x number Position of the token in world-space.
---@param y number Position of the token in world-space.
---@param amount number Amount to add to the display once it's done.
function Resources:spawnParticles(kind, x, y, amount)
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
            _spawnParticleImpl(self, kind, tier, x, y, spawnAmount)
        end
    end
end

return Resources
