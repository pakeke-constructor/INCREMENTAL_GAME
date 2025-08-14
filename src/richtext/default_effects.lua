return function(text)
    local function colorEffect(args, char)
        local color = objects.Color(args.r or 1, args.g or 1, args.b or 1, args.a or 1)
        char:setColor(color)
    end
    text.defineEffect("color", colorEffect)
    text.defineEffect("c", colorEffect)

    text.defineEffect("i", function(args, char)
        local skewness = args.skew or 1
        char:setShear(-skewness / 4, 0)
    end)
end
