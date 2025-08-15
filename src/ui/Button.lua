

local lg = love.graphics

---@param parentPanel Panel The parent panel to add this button to
---@param callback function The function to call when button is clicked
---@param text string Optional text to display on the button
---@return Panel The button panel
local function newButton(parentPanel, callback, text)
    local button = Panel()

    button.text = text or "Button"

    function button:onDraw(x, y, w, h)
        -- Simple button appearance
        lg.setColor(0.3, 0.3, 0.3, 1) -- Dark gray background
        lg.rectangle("fill", x, y, w, h)

        lg.setColor(0.7, 0.7, 0.7, 1) -- Light gray border
        lg.rectangle("line", x, y, w, h)

        -- Draw text centered
        if self.text then
            lg.setColor(1, 1, 1, 1) -- White text
            local font = lg.getFont()
            local textWidth = font:getWidth(self.text)
            local textHeight = font:getHeight()
            local textX = x + (w - textWidth) / 2
            local textY = y + (h - textHeight) / 2
            lg.print(self.text, textX, textY)
        end
    end

    function button:onClicked(m, x, y)
        callback(m, x, y)
    end

    if parentPanel then
        parentPanel:addChild(button)
    end

    return button
end

return newButton

