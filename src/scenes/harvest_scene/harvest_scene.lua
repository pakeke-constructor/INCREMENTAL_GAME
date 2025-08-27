

local FreeCameraScene = require("src.scenes.FreeCameraScene")

---@class HarvestScene: FreeCameraScene
local harvest = FreeCameraScene()



local HARVEST_CIRCLE_INSIDE = {0.5,0.5,0.5,0.6}
local HARVEST_CIRCLE_BORDER = {.8,.8,.8}
local function drawHarvestCircle(x,y, rad)
    love.graphics.setColor(HARVEST_CIRCLE_INSIDE)
    love.graphics.circle("fill", x,y, rad)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.floor(rad / 12))
    love.graphics.setColor(HARVEST_CIRCLE_BORDER)
    love.graphics.circle("line", x,y, rad)
    love.graphics.setLineWidth(lw)
end



local MONEY_INTERP = localization.newInterpolator("{wavy}{outline}MONEH: %{money}")

function harvest:draw()
    self:setCamera()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)

    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    local cx,cy = self.camera:toWorld(love.mouse.getPosition())
    drawHarvestCircle(cx,cy, 50)

    local txt = MONEY_INTERP({
        money = (math.floor(g.getMoney()))
    })
    richtext.printRichContained(txt, love.graphics.getFont(), 10, 10, 80, 20)

    self:resetCamera()

    self:renderNavbar()
end


function harvest:update(dt)
    self:updateCamera(dt)

    local mx,my = love.mouse.getPosition()

end


return harvest

