


local map = {}




--[[
ALL UI RENDERING GOES IN HERE.
]]
local P = Panel()
do

local goForest = ui.Button(P, function()
    g.gotoScene("forest")
end, "Forest")




local MAP_TITLE = localization.localize("{o}THE MAP.")



function P:onDraw(x,y, w,h)
    local header, body = Kirigami(x,y,w,h):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.5,0.4,0.7)
    richtext.printRichContained(MAP_TITLE, love.graphics.getFont(), header:get())

    goForest:draw(body:padRatio(0.8):get())
end

function map:draw()
    P:draw(0,0,love.graphics.getDimensions())
end

end


function map:update()
end



function map:keypressed()

end



function map:mousepressed(x,y, button)
    P:mousepressed(x,y, button)
end

function map:mousereleased(x,y, button)
    P:mousereleased(x,y, button)
end



return map

