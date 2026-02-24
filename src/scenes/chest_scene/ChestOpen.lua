
local cosmetics = require("src.cosmetics.cosmetics")
local particles = require("src.modules.particles.particles")


local lg = love.graphics

local REEL_SIZE = 50
local REEL_DURATION = 8.0
local TIMEOUT = 5.0
local RAY_COLOR = objects.Color("#".."FFEFC52C")

local function getReelIndex(elapsed, reelSize)
    local t = math.min(elapsed / REEL_DURATION, 1)
    local curve = 1 - (1 - t)^3
    return math.floor(1 + curve * (reelSize - 1) + 0.5)
end

local function buildReel(resultCosmetic)
    local all = cosmetics.getAll()
    local reel = {}
    for i = 1, REEL_SIZE - 1 do
        reel[i] = all[love.math.random(#all)]
    end
    reel[REEL_SIZE] = resultCosmetic
    return reel
end

local function drawGodrays(rx, ry, scale)
    scale = scale or 1
    local t2 = love.timer.getTime() / 2
    godrays.drawRays(rx, ry, t2/2.5, {rayCount=3, divisions=100, color=RAY_COLOR, startWidth=8*scale, length=600*scale, fadeTo=0, growRate=0.6})
    godrays.drawRays(rx, ry, -t2/1.5, {rayCount=5, divisions=100, color=RAY_COLOR, startWidth=9*scale, length=150*scale, fadeTo=0, growRate=1.6})
    godrays.drawRays(rx, ry, t2, {rayCount=6, divisions=100, color=RAY_COLOR, startWidth=10*scale, length=200*scale, fadeTo=0, growRate=2.6})
    godrays.drawRays(rx, ry, t2*-1, {rayCount=5, divisions=100, color=RAY_COLOR, startWidth=10*scale, length=300*scale, fadeTo=0, growRate=2.6})
end



local function newChestParticles()
    return particles.newParticlesWorld({
        gravity = 80,
        drawParticle = function(p)
            local id = p.id
            local t = love.timer.getTime()
            local sx,sy = math.sin(t*10 + id*1.77)*2, 2
            local img = id%2 == 0 and "money_particle_1" or "money_particle_2"
            g.drawImage(img, p.x, p.y, 0, sx, sy)
        end,
        getParticleDuration = function(p)
            return 1.5 + (p.id % 4) * 0.3
        end
    })
end






---@class ChestScene.ChestOpen: objects.Class
---@field phase "waiting"|"spinning"
---@field startTime number
---@field spinStart number?
---@field reel string[]?
---@field cosmetic string?
---@field done boolean
---@field error boolean
local ChestOpen = objects.Class("chest_scene:ChestOpen")

function ChestOpen:init()
    self.phase = "waiting"
    self.startTime = love.timer.getTime()
    self.done = false
    self.error = false
    self.particles = newChestParticles()
end

function ChestOpen:setResult(cosmeticId)
    if self.phase ~= "waiting" then return end
    self.cosmetic = cosmeticId
    self.reel = buildReel(cosmeticId)
    self.phase = "spinning"
    self.spinStart = love.timer.getTime()
end

function ChestOpen:setError()
    self.error = true
    self.done = true
end

function ChestOpen:isDone()
    return self.done
end

function ChestOpen:isError()
    return self.error
end

function ChestOpen:update(dt)
    self.particles:update(dt)
end



local NUM_PARTICLES = 30


function ChestOpen:draw()
    if self.done then return end

    local r = ui.getFullScreenRegion()
    local rx, ry = r:getCenter()
    local t = love.timer.getTime()

    lg.setColor(0, 0, 0, 0.8)
    lg.rectangle("fill", r:get())

    if self.phase == "waiting" then
        if t - self.startTime >= TIMEOUT then
            self:setError()
            return
        end
        lg.setColor(1, 1, 1)
        local K=40
        local AMP = 10
        local tt = self.startTime - t
        local dx = tt * math.sin(tt*K) * AMP
        local dr = tt * math.sin(tt*K) * 0.07
        g.drawImage("chest_big", rx+dx, ry, dr, 8, 8)

    elseif self.phase == "spinning" then
        local elapsed = t - self.spinStart
        local reelIndex = getReelIndex(elapsed, #self.reel)
        local settled = reelIndex >= #self.reel

        -- draw background square that converges onto item:
        do
        if reelIndex < #self.reel then
            local ratio = (#self.reel - reelIndex) / #self.reel
            local sze = (r.w / 4) + ratio*r.w
            lg.setColor(1, 0.84, 0.2, ratio * 0.5)
            local lw = lg.getLineWidth()
            lg.setLineWidth(r.h / 20)
            lg.circle("line", rx, ry, sze/1.5)
            lg.setLineWidth(lw)
        end
        end

        -- draw shockwave:
        do
        local lw = lg.getLineWidth()
        lg.setColor(1, 0.84, 0.2)
        lg.setLineWidth(r.h / 10)
        local dt = love.timer.getTime() - self.spinStart
        lg.circle("line", rx,ry, 20 + dt * 550)
        lg.setLineWidth(lw)
        end

        local progress = elapsed / REEL_DURATION
        drawGodrays(rx, ry, math.min(progress + 0.3, 1.3))

        lg.setColor(1, 1, 1)
        self.particles:draw()
        -- spawn particles from center
        if self.particles:getParticleCount() < NUM_PARTICLES then
            local a = love.math.random() * math.pi * 2
            local mag = 150 + love.math.random() * 80
            self.particles:spawnParticle(rx, ry, math.cos(a)*mag, math.sin(a)*mag)
        end

        if settled then
            if iml.wasJustPressed(r:get()) then
                self.done = true
                return
            end
            local info = cosmetics.getInfo(self.cosmetic)
            local sc = 10
            if info.type == "BACKGROUND" then
                sc = 6
            end
            lg.setColor(1, 1, 1)
            g.drawImage(info.image, rx, ry, 0, sc,sc)
            helper.printTextOutline(info.name, g.getSmallFont(32), 2, rx, ry + 90, r.w, "center", 0, 1, 1, r.w / 2)
            helper.printTextOutline("Click anywhere to close", g.getSmallFont(32), 2, rx, ry + 120, r.w, "center", 0, 1, 1, r.w / 2)
        else
            local currentId = self.reel[reelIndex]
            local info = cosmetics.getInfo(currentId)
            lg.setColor(1, 1, 1)
            local sc = 10
            if info.type == "BACKGROUND" then
                sc = 6
            end
            g.drawImage(info.image, rx, ry, 0, sc,sc)
            helper.printTextOutline(info.name, g.getSmallFont(32), 2, rx, ry + 90, r.w, "center", 0, 1, 1, r.w / 2)
        end
    end
end

return ChestOpen
