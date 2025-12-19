local effectDescription = interp("Spawn +%{count} more %{token}", {
    context = "Example result: \"Spawn +15 more Blueberry\""
})

local function defInfest(toktype, name, count)
    local tokinfo = g.getTokenInfo(toktype)
    return g.defineEffect(toktype.."_infestation", name, {
        description = effectDescription {count = count, token = tokinfo.name},
        image = tokinfo.image,
        isDebuff = false,

        populateTokenPool = function(_, tp)
            tp:add(toktype, count)
        end
    })
end

defInfest("grass_1", "Grass (I) Infestation", 15)
defInfest("grass_2", "Grass (II) Infestation", 10)
