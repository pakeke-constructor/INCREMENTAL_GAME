



```lua


function love.draw()
    ui.beginFrame()

    if ui.isClicked(x,y,w,h) then
        -- internally, uses hash(x,y,w,h) as a hash.
    end

    if ui.isHovered(x,y,w,h) then
    end

    ui.endFrame()
end


local function textInput(x,y,w,h)
    local txt = ui.getState(textInput, x,y,w,h)
    local isTyping = ui.isSelected(x,y,w,h)

    if isTyping then
        txt = txt .. ui.pollTextInput()
        ui.setState(..., txt)
    end

    love.graphics.drawTextContained(newText, x,y,w,h)
    if isTyping then
        drawCursor(x,y,w,h)
    end
end


function myButton(x,y,w,h)
    if ui.isHovered(x,y,w,h) then
        setColor(RED)
    else
        setColor(GREEN)
    end

    rectangle(x,y,w,h)
    return ui.isClicked(x,y,w,h)
end


```


