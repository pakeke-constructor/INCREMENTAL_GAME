
---@class _FisherCat: objects.Class
---@field public image string (Read-only)
---@field public x number
---@field public y number
---@field public state "idle"|"fishing"|"reeling"  NOTE: `reeling` state is only for player-cat.
local FisherCat = objects.Class("g:FisherCat")


---@param x number
---@param y number
function FisherCat:init(x, y, fishingWorld, isPlayerCat)
    self.x = x
    self.y = y
    self.image = "fishing_cat"
    self.fishingWorld = fishingWorld

    self.randomId = love.math.random(1,10000)

    self.isPlayerCat = isPlayerCat

    self.bobberX, self.bobberY = x,y
    self.targX, self.targY = x,y -- where we are casting the bobber towards

    self.state = "idle"
    self.timeOfLastCast = 0
end

if false then
    ---@param x number
    ---@param y number
    ---@param fishingWorld FishingWorld
    ---@param isPlayer boolean
    ---@return _FisherCat
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function FisherCat(x, y, fishingWorld, isPlayer) end
end


local CAST_TIME = 0.6
local BOBBER_CAST_HEIGHT = 50

local TIME_TO_CATCH = 25


function FisherCat:getTimeSinceCast()
    if self.state ~= "fishing" then
        return 0
    end
    local time = love.timer.getTime()
    local waitTime = time - self.timeOfLastCast
    return waitTime
end



---@param self _FisherCat
local function updateBot(self,dt)
    local delta = self:getTimeSinceCast()
    if self.state == "idle" then
        local cx,cy = helper.randomInRegion(self.fishingWorld.castArea:get())
        self:cast(cx,cy)
    elseif self.state == "fishing" and (delta > TIME_TO_CATCH) and (love.math.random() < dt/3) then
        -- catch fish!
        self:catch()
    end
end


---@param dt number
function FisherCat:update(dt)
    local delta = self:getTimeSinceCast()
    if delta < CAST_TIME then
        -- its still casting! Move bobber.
        local h = -math.sin(delta * (math.pi/CAST_TIME)) * BOBBER_CAST_HEIGHT
        local lerp = helper.lerp
        local t = delta/CAST_TIME
        local xx, yy = lerp(self.x, self.targX, t), lerp(self.y, self.targY, t)
        self.bobberX = xx
        self.bobberY = yy + h
    end

    if not self.isPlayerCat then
        updateBot(self,dt)
    end
end



function FisherCat:draw()
    -- TODO: Draw other fishing-related elements

    -- draw body:
    local t = love.timer.getTime() + self.randomId/3777
    local s = math.sin(t*2)
    local q = g.getImageQuad(self.image)
    q:getTextureDimensions()
    g.drawImage(self.image, self.x, self.y+s, s/17)

    g.drawImage("fishing_rod", self.x + 12, self.y-4)

    -- draw bobber:
    love.graphics.setColor(0,0,0)
    if self.state ~= "idle" then
        local bobY = self.bobberY + 3*math.sin(love.timer.getTime()*5 + self.randomId/377.34)

        love.graphics.setColor(1,1,1,0.5)
        love.graphics.setLineWidth(1)
        love.graphics.line(self.x+16,self.y-15, self.bobberX,bobY)
        love.graphics.setColor(1,1,1)
        g.drawImage("fishing_cat_bobber", self.bobberX, bobY)
    end
end


---@param x number
---@param y number
function FisherCat:cast(x, y)
    assert(type(y)=="number","?")
    self.timeOfLastCast = love.timer.getTime()
    self.state = "fishing"
    self.targX = x
    self.targY = y
end




function FisherCat:catch()
    self:reset()

    if (self.isPlayerCat) and (love.math.random() < 0.6) then
        -- player cat gets a secret buff :)
    end
end


function FisherCat:reset()
    self.state = "idle"
    self.bobberX, self.bobberY = self.x, self.y
end


return FisherCat

