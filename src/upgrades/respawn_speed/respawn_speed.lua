
---@param id string
---@param name string
---@param descname string
---@param image string
---@param tokcat g.Category
local function defRespawnSpeedUpgrade(id, name, descname, image, tokcat)
    return g.defineUpgrade(id, name, {
        description = descname.." spawn %{1} faster.",
        kind = "HARVESTING",
        image = image,

        getValues = helper.percentageGetter(10),
        valueFormatter = {"%d%%"},

        ---@param uinfo g.UpgradeInfo
        ---@param level integer
        ---@param toktype string
        getPerTokenRespawnTimeMultiplier = function(uinfo, level, toktype)
            local tinfo = g.getTokenInfo(toktype)

            if tinfo.category == tokcat then
                return 1 / (1 + uinfo:getValues(level) / 100)
            end
            return 1
        end,

        drawUI = function (uinfo, level, x, y, w, h)
            local dy = math.sin(love.timer.getTime()*3 + 2.1)*2
            g.drawImage("clock_icon", x+w/4,y+h/4+dy)
        end,
        procGen = {weight = 2, distance = {8, 14}}
    })
end

defRespawnSpeedUpgrade("grass_respawn", "Faster Grass Spawn", "Grass crops", "grass_3", "grass")
defRespawnSpeedUpgrade("berry_respawn", "Faster Berries Spawn", "Berries", "red_berry", "berry")

g.defineUpgrade("fast_respawn", "Faster Crop Spawn", {
    description = "Crops respawn %{1} faster.",
    kind = "HARVESTING",
    image = "horticulture_book", -- TODO: Replace

    getValues = helper.percentageGetter(5),
    valueFormatter = {"%d%%"},

    ---@param uinfo g.UpgradeInfo
    ---@param level integer
    getPerTokenRespawnTimeMultiplier = function(uinfo, level)
        return 1 / (1 + uinfo:getValues(level) / 100)
    end,

    drawUI = function (uinfo, level, x, y, w, h)
        local dy = math.sin(love.timer.getTime()*3 + 2.1)*2
        g.drawImage("clock_icon", x+w/4,y+h/4+dy)
    end,
    procGen = {weight = 2, distance = {2, 6}}
})
