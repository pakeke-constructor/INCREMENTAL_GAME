

local DrawSystem = fg.ComponentSystem("drawable")

local cam11 = require("lib.cam11")


function DrawSystem:init()
    self.camera = cam11()
end



local function drawFloor()

end

local function drawEntities()

end

local function drawEffects()

end

local function drawUI()

end





function DrawSystem:draw()
    love.graphics.push()
    love.graphics.applyTransform(camera:getTransform())
    ---@type number,number
    local ox, oy = fg.ask("rendering:getCameraOffset")
    love.graphics.translate(ox, oy)


    drawFloor()
    drawEntities()
end





function DrawSystem:update()

end


return DrawSystem

