

---@class ui
local ui = {}


---@param richText string
---@param x number
---@param y number
---@param w number
---@param h number
function ui.Button(richText, x,y,w,h)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", x,y,w,h)
    love.graphics.setColor(0,0,0)
    richtext.printRichContained(richText, love.graphics.getFont(), x,y,w,h)
    return iml.wasJustClicked(x,y,w,h, 1)
end


return ui
