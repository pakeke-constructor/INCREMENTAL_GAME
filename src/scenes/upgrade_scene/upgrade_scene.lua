
local upgrades = require("src.upgrades.upgrades")


local FreeCameraScene = require("src.scenes.FreeCameraScene")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()




local TITLE = localization.localize("{o}UPGRADES!")


function upgscene:draw()
    self:setCamera()
    local header, body = Kirigami(0,0,ui.getScaledUIDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.2,0.4,0.8)
    love.graphics.setColor(1,1,1)

    local hoveredUpgrade = upgrades._draw()

    self:resetCamera()

    ui.startUI()
    self:renderNavbar()

    g.getHUD():drawResourceHUD(self.camera)

    if hoveredUpgrade then
        -- figure out if we render left or right.

        -- TODO: draw upgrade-hover-description here
    end

    ui.endUI()
end




function upgscene:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
end


function upgscene:keypressed()
end


function upgscene:mousepressed(x,y, button)
    
end

function upgscene:mousereleased(x,y, button)
end



return upgscene


