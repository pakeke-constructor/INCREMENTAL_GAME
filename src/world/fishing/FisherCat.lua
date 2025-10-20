
---@class g.FisherCat: objects.Class
---@field public image string (Read-only)
---@field public x number
---@field public y number
---@field public state "idle"|"fishing"|"reeling"  NOTE: `reeling` state is only for player-cat.
local FisherCat = objects.Class("g:FisherCat")


---@param x number
---@param y number
---@param image string?
function FisherCat:init(x, y, image)
    self.x = x
    self.y = y
    self.image = image or "happy_cat"

    self.bobberX, self.bobberY = x,y
    self.targX, self.targY = x,y -- where we are casting the bobber towards

    self.state = "idle"
    self.timeOfLastCast = 0
end

if false then
    ---@param x number
    ---@param y number
    ---@param image string?
    ---@return g.FisherCat
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function FisherCat(x, y, image) end
end


local CAST_TIME = 0.6
local BOBBER_CAST_HEIGHT = 50

---@param dt number
function FisherCat:update(dt)
    local time = love.timer.getTime()
    local delta = time - self.timeOfLastCast
    if delta < CAST_TIME then
        -- its still casting! Move bobber.
        local h = math.sin(delta * (math.pi/CAST_TIME)) * BOBBER_CAST_HEIGHT
        local lerp = helper.lerp
        local xx, yy = lerp(self.x, self.targX, delta), lerp(self.y, self.targY, delta)
        self.bobberX = xx
        self.bobberY = yy + h
    end
end



function FisherCat:draw()
    -- TODO: Draw other fishing-related elements
    g.drawImage(self.image, self.x, self.y)

    love.graphics.setColor(0,0,0)
    love.graphics.line(self.x,self.y, self.bobberX,self.bobberY)
end


function FisherCat:cast()
    self.timeOfLastCast = love.timer.getTime()
    self.state = "fishing"
    self.bobberX = 100
    self.bobberY = 100
end



function FisherCat:reset()
    self.state = "idle"
    self.bobberX, self.bobberY = self.x, self.y
end


return FisherCat

