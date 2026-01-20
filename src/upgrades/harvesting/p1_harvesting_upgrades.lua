




---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end


---@class _.upgrades
local upgrades = {
    {
        id = "more_damage",
        title = "More Damage",
        desc = "%{1} scythe damage",
        stat = "HitDamage",
        increase_1 = 0.3,
        increase_2 = 0.5,
        increase_3 = 1,
    },
    {
        id = "more_speed",
        title = "More Speed",
        desc = "%{1} scythe speed",
        stat = "HitSpeed",
        increase_1 = 0.5,
        increase_2 = 1,
        increase_3 = 2
    },
    {
        id = "more_area",
        title = "More Area",
        desc = "%{1} area",
        stat = "HarvestArea",
        increase_1 = 1,
        increase_2 = 2,
        increase_3 = 4
    },
    {
        id = "better_lightning",
        title = "Better Lightning",
        desc = "%{1} Lightning damage",
        stat = "LightningDamage",
        increase_2 = 2,
        increase_3 = 4
    },
    {
        id = "sharper_knives",
        title = "Sharper Knives",
        desc = "%{1} Knife damage",
        stat = "KnifeDamage",
        increase_2 = 2,
        increase_3 = 4
    },
    {
        id = "more_xp",
        title = "More XP",
        desc = "%{1} xp gain",
        stat = "XpMultiplier",
    }
}


local function makeDrawUI(txt)
    local font = g.getSmallFont(16)
    local fh = font:getHeight()
    return function(uinfo, level, x, y, w, h)
        local r,g,b,a = lg.getColor()
        lg.setColor(1,0,0,1)
        local dy = 3*math.sin(love.timer.getTime())
        --helper.printTextOutline(txt, font, 1, x, y-fh/2, 100, "left")
        --lg.printf(txt, font, x,y-fh/2, 100, "left")
        helper.printTextOutline(txt, font, 1, x,y-fh/2+dy, 100, "left")
        lg.setColor(r,g,b,a)
    end
end


for _, u in ipairs(upgrades) do
    defUpgrade("percentage_"..u.id, u.title, {
        image = u.id,

        getValues = function(self, level)
            return level*2
        end,
        valueFormatter = {"+%d%%"},
        description = u.desc,

        drawUI = makeDrawUI("2%"),

        ["get" .. u.stat .. "Multiplier"] = function(self, level)
            local a = self:getValues(level)
            return 1 + (a / 100)
        end
    })

    defUpgrade("big_percentage_"..u.id, u.title, {
        image = u.id,

        getValues = function(self, level)
            return level*5
        end,
        valueFormatter = {"+%d%%"},
        description = u.desc,

        drawUI = makeDrawUI("5%"),

        ["get" .. u.stat .. "Multiplier"] = function(self, level)
            local a = self:getValues(level)
            return 1 + (a / 100)
        end
    })

    for i=1, 3 do
        local increase = (u["increase_"..tostring(i)])
        if increase then
            defUpgrade("flat_" .. tostring(i) .. "_"..u.id, u.title, {
                image = u.id,

                getValues = function(self, level)
                    return level*increase
                end,

                drawUI = makeDrawUI("+"..tostring(increase)),

                valueFormatter = {"+%.1f"},
                description = u.desc,

                ["get" .. u.stat .. "Modifier"] = function(self, level)
                    return self:getValues(level)
                end
            })
        end
    end
end



---@class _.p1harv.CATEGORIES
local CATEGORIES = {
    {category = "grass", image="grass_3", name="Grass Crops"},
    {category = "berry", image="red_berry", name="Berry Crops"},
    {category = "fish", image="fish", name="Fish"},
}


for _, c in ipairs(CATEGORIES) do
    assert(g.isImage(c.image))

    defUpgrade(c.category .. "_damage_upgrade", "Weaker "..c.name, {
        image = "null_image",
        getValues = function(self, level)
            return level*10
        end,
        valueFormatter = {"+%d%%"},
        description =  "ALL " .. c.name .. " take %{1} extra damage!",

        getTokenDamageMultiplier = function(self, level)
            local a = self:getValues(level)
            return 1 + (a / 100)
        end,

        drawUI = function (uinfo, level, x, y, w, h)
            local t1 = love.timer.getTime()*2

            local cx,cy = x+w/2, y+h/2
            local rad = w/6

            local x1,y1 = cx+5, cy-rad*math.cos(t1)
            local x2,y2 = cx-5, cy+rad*math.cos(t1)

            g.drawImage("upgrade_damage_icon", x2,y2)
            g.drawImage(c.image, x1,y1)
        end
    })
end



defUpgrade("lucky_hit", "Lucky Hit", {
    getValues = function(self,level)
        return level*3
    end,
    description = "When a crop is hit, +%{1}% chance to hit another crop",

    tokenHit = function(self,level)
        local r = love.math.random()
        local a=self:getValues(level)
        local chance = (a/100)
        if r < chance then
            local tok = g.getRandomToken(function (tok)
                return not g.isBeingHit(tok)
            end)
            if tok then
                g.tryHitToken(tok)
            end
        end
    end
})



