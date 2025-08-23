

local FreeCameraScene = require("src.scenes.FreeCameraScene")


---@class UpgradeTreeScene: FreeCameraScene
local uptree = FreeCameraScene()




local TITLE = localization.localize("{o}UPGRADES!")


function uptree:draw()
    self:setCamera()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.2,0.4,0.8)
    love.graphics.setColor(1,1,1)

    richtext.printRichContained(TITLE, love.graphics.getFont(), header:get())
    self:resetCamera()

    self:renderNavbar()
end




function uptree:update(dt)
    self:updateCamera(dt)
end


function uptree:keypressed()
end


function uptree:mousepressed(x,y, button)
end

function uptree:mousereleased(x,y, button)
end



return uptree


