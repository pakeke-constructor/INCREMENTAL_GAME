

return function(text)
    --[[
    Define default effects:
    ]]
    local function wavyEffect(args, char)
        local f = args.freq or 1
        local amp = args.amp or 1
        local k = args.k or 1 -- `k` determines how "different" the letter are.
        -- k = 0 indicates all letters bob up and down, in sync.
        local offset = (char:getIndex()-1) * k
        local dy = math.sin(2 * math.pi * f * love.timer.getTime() + offset) * amp
        char:setOffset(0, dy)
    end

    text.defineEffect("wavy", wavyEffect)
    text.defineEffect("w", wavyEffect)

    text.defineEffect("u", function(_, char)
        local r, g, b, a = love.graphics.getColor()
        local c1, c2, c3, c4 = char:getColor():getRGBA()
        local x, y = char:getPosition()
        local w, h = char:getDimensions()
        love.graphics.setColor(r * c1, g * c2, b * c3, a * c4)
        love.graphics.line(x, y + h - 0.5, x + w, y + h - 0.5)
        love.graphics.setColor(r, g, b, a)
    end)

    -- dy=-2 because we want a thicker outline at bottom
    local outline = consts.IS_MOBILE and {
        {-1, -2},
        {-1, 1},
        {1, -2},
        {1, 1},
    } or {
        {-1, -2},
        {-1, -1},
        {-1, 0},
        {-1, 1},
        {0, -2},
        {0, -1},
        {0, 1},
        {1, -2},
        {1, -1},
        {1, 0},
        {1, 1},
    }

    ---@param args table<string,number?>
    ---@param char text.Character
    local function outlineEffect(args,char)
        local thickness = args.thickness or 1
        local r, g, b, a = love.graphics.getColor()
        local cr = args.r or 0
        local cg = args.g or 0
        local cb = args.b or 0
        local ca = (args.a or 1) * a

        local ox, oy = char:getOffset()

        for _, dxdy in ipairs(outline) do
            char:setOffset(ox + dxdy[1] * thickness, oy + dxdy[2] * thickness)
            char:draw(cr, cg, cb, ca, true)
        end
        char:setOffset(ox, oy)

        love.graphics.setColor(r, g, b, a)
    end

    text.defineEffect("o", outlineEffect)
    text.defineEffect("outline", outlineEffect)

    local function colorEffect(args, char)
        local color = objects.Color(args.r or 1, args.g or 1, args.b or 1, args.a or 1)
        char:setColor(color)
    end
    text.defineEffect("color", colorEffect)
    text.defineEffect("c", colorEffect)

    local rainbow = {
        {0.85, 0.15, 0.15, 1.0},  -- Red
        {0.90, 0.55, 0.20, 1.0},  -- Orange
        {0.90, 0.90, 0.30, 1.0},  -- Yellow
        {0.20, 0.80, 0.20, 1.0},  -- Green
        {0.20, 0.60, 0.80, 1.0},  -- Light Blue
        {0.25, 0.25, 0.80, 1.0},  -- Blue
        {0.60, 0.20, 0.80, 1.0},  -- Violet
    }
    local function rainbowEffect(args, char)
        local i = math.floor(char.start/3 - love.timer.getTime()/2)
        local index = (i % (#rainbow))+1
        char:setColor(rainbow[index])
    end
    text.defineEffect("rainbow", rainbowEffect)

    text.defineEffect("i", function(args, char)
        local skewness = args.skew or 1
        char:setShear(-skewness / 4, 0)
    end)
end



