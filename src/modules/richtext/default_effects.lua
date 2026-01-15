---@param text text
return function(text)
    local outlineMap = consts.IS_MOBILE and {
        {-1, -1},
        {1, -1},
        {-1, 2},
        {1, 2},
    } or {
        {-1, -1},
        {0, -1},
        {1, -1},
        {-1, 0},
        {1, 0},
        {-1, 1},
        {0, 1},
        {1, 1},
        {-1, 2},
        {0, 2},
        {1, 2},
    }
    ---@param args richtext.EffectArgs
    ---@param x number
    ---@param y number
    ---@param context richtext.Context
    ---@param next richtext.NextFunc
    local function outline(args, x, y, context, next)
        local r, g, b, a = love.graphics.getColor()
        local cr = args.r or 0
        local cg = args.g or 0
        local cb = args.b or 0
        local ca = (args.a or 1) * a
        local thickness = args.thickness or 1
        local obj = context.textOrDrawable

        love.graphics.setColor(cr, cg, cb, ca)
        for _, oxoy in ipairs(outlineMap) do
            local ox, oy = oxoy[1], oxoy[2]
            if type(obj) == "string" then
                love.graphics.print(obj, context.font, x + ox * thickness, y + oy * thickness)
            else
                if context.quad then
                    love.graphics.draw(obj, context.quad, x + ox * thickness, y + oy * thickness)
                else
                    love.graphics.draw(obj, x + ox * thickness, y + oy * thickness)
                end
            end
        end

        love.graphics.setColor(r, g, b, a)
        return next(context.textOrDrawable, x, y)
    end
    text.defineEffect("outline", outline)
    text.defineEffect("o", outline)

    ---@param args richtext.EffectArgs
    ---@param x number
    ---@param y number
    ---@param context richtext.Context
    ---@param next richtext.NextFunc
    local function color(args, x, y, context, next)
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(args.r or 1, args.g or 1, args.b or 1, (args.a or 1) * a)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, g, b, a)
    end
    text.defineEffect("color", color)
    text.defineEffect("c", color)

    ---@param args richtext.EffectArgs
    ---@param x number
    ---@param y number
    ---@param context richtext.Context
    ---@param next richtext.NextFunc
    local function wavy(args, x, y, context, next)
        local f = args.freq or 1
        local amp = args.amp or 1
        local k = args.k or 1 -- `k` determines how "different" the letter are.
        -- k = 0 indicates all letters bob up and down, in sync.
        local offset = context.index * k
        local dy = math.sin(2 * math.pi * f * love.timer.getTime() + offset) * amp
        return next(context.textOrDrawable, x, y + dy)
    end
    text.defineEffect("wavy", wavy, {perCharacter = true})
    text.defineEffect("w", wavy, {perCharacter = true})

    local rainbow = {
        {0.85, 0.15, 0.15, 1.0},  -- Red
        {0.90, 0.55, 0.20, 1.0},  -- Orange
        {0.90, 0.90, 0.30, 1.0},  -- Yellow
        {0.20, 0.80, 0.20, 1.0},  -- Green
        {0.20, 0.60, 0.80, 1.0},  -- Light Blue
        {0.25, 0.25, 0.80, 1.0},  -- Blue
        {0.60, 0.20, 0.80, 1.0},  -- Violet
    }
    ---@param args richtext.EffectArgs
    ---@param x number
    ---@param y number
    ---@param context richtext.Context
    ---@param next richtext.NextFunc
    local function rainbowEffect(args, x, y, context, next)
        local i = math.floor(context.index/3 - love.timer.getTime()/2)
        local index = (i % (#rainbow))+1
        local rb = rainbow[index]
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(rb[1], rb[2], rb[3], rb[4] * a)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, g, b, a)
    end
    text.defineEffect("rainbow", rainbowEffect, {perCharacter = true})
end
