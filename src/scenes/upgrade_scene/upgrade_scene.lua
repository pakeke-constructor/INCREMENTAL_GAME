
local upgrades = require("src.upgrades.upgrades")
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")


local FreeCameraScene = require("src.scenes.FreeCameraScene")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()

---@type ui.UpgradeDescription
upgscene.upgradeDescription = nil
upgscene.upgradeDescriptionType = nil


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
        if not self.upgradeDescription or upgscene.upgradeDescriptionType ~= hoveredUpgrade.type then
            self.upgradeDescription = UpgradeDescription()
            self.upgradeDescription:autoBuild(hoveredUpgrade)
            self.upgradeDescriptionType = hoveredUpgrade.type
        end

        local CONTENT_PADDING = 8
        local r = Kirigami(0, 0, ui.getScaledUIDimensions())
        local mx, my = ui.getMouse()
        local descriptionBoxR = Kirigami(0, 0, self.upgradeDescription:getDimensions())
            :padUnit(-CONTENT_PADDING) -- expand
            :set(mx + 14, my - 3)
            :clampInside(r:padUnit(4))

        -- Background
        love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
        love.graphics.rectangle("fill", descriptionBoxR:get())

        -- Border
        local lw = love.graphics.getLineWidth()
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.,0.,0.08)
        love.graphics.rectangle("line", descriptionBoxR:get())
        love.graphics.setLineWidth(lw)

        -- Upgrade description
        love.graphics.setColor(1,1,1)
        self.upgradeDescription:draw(descriptionBoxR.x + CONTENT_PADDING, descriptionBoxR.y + CONTENT_PADDING)
    else
        self.upgradeDescription = nil
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


