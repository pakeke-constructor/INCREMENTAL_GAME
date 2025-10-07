

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")



---@class MapScene: FreeCameraScene
local map = FreeCameraScene()





local MAP_TITLE = localization.localize("{o thickness=4}THE MAP.")


local mapImg = love.graphics.newImage("src/scenes/map_scene/map_image.png")


function map:init()
    local w,h = mapImg:getDimensions()
    self.camera:setPos(w/2,h/2-200)
end

function map:draw()
    local COL = objects.Color("#FF00A2E8")
    love.graphics.clear(COL)

    self:setCamera()
    local header, body = Kirigami(0,0,mapImg:getDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.setColor(1,1,1)
    love.graphics.draw(mapImg,0,0)

    richtext.printRichContained(MAP_TITLE, love.graphics.getFont(), header:get())

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderNavbar()
    -- self:renderMap()
    ui.endUI()
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

