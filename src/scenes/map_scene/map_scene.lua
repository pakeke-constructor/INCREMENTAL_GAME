

local FreeCameraScene = require("src.scenes.FreeCameraScene")



---@class MapScene: FreeCameraScene
local map = FreeCameraScene()





local MAP_TITLE = localization.localize("{o thickness=4}THE MAP.")


local mapImg = love.graphics.newImage("src/scenes/map_scene/map_image.png")


function map:draw()
    love.graphics.clear(0.5,0.4,0.7)

    self:setCamera()
    local header, body = Kirigami(0,0,mapImg:getDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.setColor(1,1,1)
    love.graphics.draw(mapImg,0,0)

    richtext.printRichContained(MAP_TITLE, love.graphics.getFont(), header:get())

    self:resetCamera()

    self:renderNavbar()
    -- self:renderMap()
end




function map:update(dt)
    self:updateCamera(dt)
end



function map:keypressed(k)
end



function map:mousepressed(x,y, button)
end

function map:mousereleased(x,y, button)
end



return map

