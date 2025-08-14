local Pass = require(".Pass")
local parser = require(".parser")

-- ---@type text.Pass
-- local passInstance = Pass(nil, 0, "left", nil)
local drawRichText

---Draw rich text.
---@param txt text.ParsedText|string Formatted rich text string or parsed rich text data.
---@param font love.Font Font object to use
---@param limit number Maximum width before word-wrapping.
---@param align love.AlignMode (justify is not supported)
---@param transform love.Transform Transformation stack to apply.
---@return boolean,(string|nil)
---@diagnostic disable-next-line: missing-return
function drawRichText(txt, font, transform, limit, align) end

---Draw rich text directly without state.
---@param txt text.ParsedText|string Formatted rich text string or parsed rich text data.
---@param font love.Font Font object to use
---@param x number
---@param y number
---@param limit number Maximum width before word-wrapping.
---@param align love.AlignMode (justify is not supported)
---@param rot number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
---@param kx number?
---@param ky number?
---@return boolean,(string|nil)
function drawRichText(txt, font, x, y, limit, align, rot, sx, sy, ox, oy, kx, ky)
    if typecheck.isType(x, "love:Transform") then
        align = limit
        limit = y
        y, rot = nil, nil
        sx, sy = nil, nil
        ox, oy = nil, nil
        kx, ky = nil, nil
    end

    love.graphics.push("all")
    love.graphics.applyTransform(x, y, rot, sx, sy, ox, oy, kx, ky)

    local r, g, b, a = love.graphics.getColor()
    local passInstance = Pass(font, limit, align, {r, g, b, a})

    for _, data in ipairs(assert(parser.ensure(txt))) do
        if type(data) == "table" then
            passInstance:updateEffect(data)
        else
            for _, c in utf8.codes(data) do
                passInstance:add(utf8.char(c))
            end
        end
    end

    passInstance:add(nil) -- flush

    love.graphics.pop()
    return true
end

return drawRichText
