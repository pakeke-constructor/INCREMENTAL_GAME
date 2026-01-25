


g.defineUpgrade("shiny_diamond", "Shiny Diamond", {
    description = "+%{1}% Experience gain!",
    kind = "MISC",

    getValues = helper.percentageGetter(5, 5),

    getXpMultiplierMultiplier = function(self, level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})
