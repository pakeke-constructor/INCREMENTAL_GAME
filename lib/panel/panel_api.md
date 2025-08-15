

# panel API



```lua


local function newButton(parentPanel, callback)
    local button = panels.Panel()

    function button:onDraw(x,y,w,h)
        lg.rectangle("fill", x,y,w,h)
    end

    function button:onClicked(...)
        callback(...)
    end

    parentPanel:addChild(button)

    return button
end




local panel = panels.Panel()

panel.buttonA = newButton(panel, funcA)
panel.buttonB = newButton(panel, funcB)




function panel:onDraw(x,y,w,h)
    -- called when `:draw` is called
    local a,b = Region(x,y,w,h):splitHorizontal(1,1):padRatio(0.1)

    self.buttonA:draw(a:get())
    self.buttonB:draw(b:get())
end




function love.draw(...)
    panel:draw(...)
end

function love.mousepressed(...)
    panel:mousepressed(...)
end

function love.mousereleased(...)
    panel:mousereleased(...)
end

function love.wheelmoved(...)
    panel:wheelmoved(...)
end






```

