

-- bit of a hack;
-- this is a token that works with ANY kind of effect/duration


g.defineToken("abstract_potion_token", "ABSTRACT DEV TOKEN", {
    maxHealth = 100,
    resources = {},

    tokenDestroyed = function(tok)
        ---@diagnostic disable-next-line
        if tok._effectDuration and tok._effect then
            ---@diagnostic disable-next-line
            g.grantEffect(tok._effect, tok._effectDuration)
        end
    end
})

