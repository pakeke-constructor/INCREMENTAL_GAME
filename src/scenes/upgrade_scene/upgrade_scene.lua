
local upgrades = require("src.upgrades.upgrades")


local FreeCameraScene = require("src.scenes.FreeCameraScene")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()




local TITLE = localization.localize("{o}UPGRADES!")


function upgscene:draw()
    self:setCamera()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.2,0.4,0.8)
    love.graphics.setColor(1,1,1)

    upgrades._draw()

    self:resetCamera()

    self:renderNavbar()
end




function upgscene:update(dt)
    self:updateCamera(dt)
end


function upgscene:keypressed()
end


function upgscene:mousepressed(x,y, button)
end

function upgscene:mousereleased(x,y, button)
end



return upgscene


