local effectDescription = interp("Spawn +%{count} more %{token}", {
    context = "Example result: \"Spawn +15 more Blueberry\""
})

local function defInfest(toktype, name, count)
    local tokinfo = g.getTokenInfo(toktype)
    return g.defineEffect(toktype.."_infestation", name, {
        nameContext = "A option that increase the limit of something being spawned.",
        rawDescription = effectDescription {count = count, token = tokinfo.name},
        image = tokinfo.image,
        isDebuff = false,

        populateTokenPool = function(_, tp)
            tp:add(toktype, count)
        end
    })
end

defInfest("grass_1", "Grass (I) Infestation", 30)
defInfest("grass_2", "Grass (II) Infestation", 20)
defInfest("blue_grass_1", "Blue Grass (I) Infestation", 30)
defInfest("blue_grass_2", "Blue Grass (II) Infestation", 20)
