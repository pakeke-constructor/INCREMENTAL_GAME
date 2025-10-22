


---@param id string
---@param name string
---@param typedef {token:g.TokenDefinition, effect:g.EffectDefinition}
local function defTokenEffect(id, name, typedef)
    g.defineToken(id, name, typedef.token)
    g.defineEffect(id, name, typedef.effect)
end



defTokenEffect("thick_grass", "Thick Grass", {
    effect = {
        description = loc"Grass tokens yield 2x more resources",

        ---@param dur number
        ---@param tok g.Token
        getTokenResourceMultiplier = function(dur, tok)
            return tok.category == "grass" and 2 or 1
        end
    },
    token = {
        maxHealth = 5,
        resources = {}
    }
})

g.defineEffect("happy_cat", "Happy Cat", {
    effect = {
        description = loc"Cats yield 2x less damage",
        isDebuff = true,

        ---@param dur number
        ---@param tok g.Token
        getTokenDamageMultiplier = function(dur, tok)
            return tok.category == "cat" and 0.5 or 1
        end
    },

    token = {
        maxHealth = 5,
        resources = {}
    }
})
