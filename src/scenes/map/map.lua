


local map = {}





local MAP_TITLE = localization.localize("{o}THE MAP.")


local mapImg = love.graphics.newImage("src/scenes/map/map_image.png")

function map:draw()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.5,0.4,0.7)
    love.graphics.setColor(1,1,1)

    love.graphics.draw(mapImg,0,0)

    richtext.printRichContained(MAP_TITLE, love.graphics.getFont(), header:get())

    local b1,b2 = body:splitVertical(1,1)

    if ui.Button("Harvest", b1:padRatio(0.8):get()) then
        g.gotoScene("harvest")
    end

    if ui.Button("Upgrades", b2:padRatio(0.8):get()) then
        g.gotoScene("upgrade_tree")
    end
end




function map:update()
end



function map:keypressed()
end



function map:mousepressed(x,y, button)
    iml.mousepressed(x,y, button)
end

function map:mousereleased(x,y, button)
    iml.mousereleased(x,y, button)
end



return map

