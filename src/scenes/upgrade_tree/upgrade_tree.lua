



local uptree = {}





local TITLE = localization.localize("{o}UPGRADES!")


function uptree:draw()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.5,0.7,0.3)
    love.graphics.setColor(1,1,1)

    richtext.printRichContained(TITLE, love.graphics.getFont(), header:get())

    if ui.Button("Map", body:padRatio(0.8):get()) then
        g.gotoScene("map")
    end
end




function uptree:update()
end


function uptree:keypressed()
end


function uptree:mousepressed(x,y, button)
end

function uptree:mousereleased(x,y, button)
end



return uptree


