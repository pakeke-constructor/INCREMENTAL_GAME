

local map = {}



function map:init()
    self.sceneButtons = {
        {
            x = 10,
            y = 10,
            scene = "forest"
        }
    }
end



local MAP_TITLE = localization.localize("{o}THE MAP.")


function map:draw()
    local r = Kirigami(0,0,love.graphics.getDimensions())

    local header = (r:splitVertical(1,5)):padRatio(0.2)
    love.graphics.clear(0.5,0.4,0.7)
    richtext.printRichContained(MAP_TITLE, love.graphics.getFont(), header:get())
end



function map:update()

end



function map:keypressed()

end



function map:mousepressed(x,y, button)
    
end


return map

