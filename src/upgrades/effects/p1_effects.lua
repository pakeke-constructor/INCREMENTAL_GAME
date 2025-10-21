g.defineEffect("thick_grass", "Thick Grass", {
    description = loc"Grass tokens yield 2x more resources",
    duration = 10,

    ---@param dur number
    ---@param tok g.Token
    getTokenResourceMultiplier = function(dur, tok)
        return tok.category == "grass" and 2 or 1
    end
})

g.defineEffect("happy_cat", "Happy Cat", {
    description = loc"Cats yield 2x more damage",
    duration = 10,

    ---@param dur number
    ---@param tok g.Token
    getTokenDamageMultiplier = function(dur, tok)
        return tok.category == "cat" and 2 or 1
    end
})
