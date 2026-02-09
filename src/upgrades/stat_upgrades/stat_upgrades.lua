




---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end


local DEFAULT_WEIGHT = 2

---@class _.upgrades
local upgrades = {
    {
        id = "more_damage",
        title = "More Damage",
        desc = "%{1} scythe damage",
        stat = "HitDamage",
        flat = {2, 3, 5},
        percentage = {5, 10},
    },
    {
        id = "more_speed",
        title = "More Speed",
        desc = "%{1} scythe speed",
        stat = "HitSpeed",
        flat = {1, 2, 3},
        percentage = {5, 10}
    },
    {
        id = "more_area",
        title = "More Area",
        desc = "%{1} area",
        stat = "HarvestArea",
        flat = {2, 4},
        percentage = {5, 10}
    },
    {
        id = "better_lightning",
        needs = "mushroom_blue",
        title = "Better Lightning",
        desc = "%{1} Lightning damage",
        stat = "LightningDamage",
        flat = {2, 4},
        percentage = {20}
    },
    {
        id = "sharper_knives",
        needs = "knife_bush",
        title = "Sharper Knives",
        desc = "%{1} Knife damage",
        stat = "KnifeDamage",
        flat = {2, 4},
        percentage = {20}
    },
    {
        id = "more_xp",
        weight = DEFAULT_WEIGHT / 2,
        title = "More XP",
        desc = "%{1} xp gain",
        stat = "XpMultiplier",
        percentage = {5, 10}
    }
}


local function makeDrawUI(txt)
    local font = g.getSmallFont(16)
    local fh = font:getHeight()
    return function(uinfo, level, x, y, w, h)
        local r, g, b, a = lg.getColor()
        lg.setColor(1, 0, 0, 1)
        local dy = 3 * math.sin(love.timer.getTime() * 2) -- Added a multiplier for faster bobbing
        helper.printTextOutline(txt, font, 1, x, y - fh / 2 + dy, 100, "left")
        lg.setColor(r, g, b, a)
    end
end


for _, u in ipairs(upgrades) do
    local percentage = u.percentage or {}
    for _, pct in ipairs(percentage) do
        local id = "percentage_" .. tostring(pct) .. "_" .. tostring(u.id)
        defUpgrade(id, u.title, {
            image = u.id,
            description = u.desc,
            drawUI = makeDrawUI(pct .. "%"),
            valueFormatter = {"+%d%%"},

            getValues = function(self, level)
                return level * pct
            end,

            ["get" .. u.stat .. "Multiplier"] = function(self, level)
                return 1 + (self:getValues(level) / 100)
            end,

            procGen = {
                weight = u.weight or DEFAULT_WEIGHT,
                needs = u.needs,
                distance = {10,20}
            },
        })
    end

    local flat = u.flat or {}
    for i, amount in ipairs(flat) do
        defUpgrade("flat_" .. tostring(amount) .. "_" .. u.id, u.title, {
            image = u.id,
            description = u.desc,
            drawUI = makeDrawUI("+" .. amount),
            valueFormatter = {"+%.1f"},

            getValues = function(self, level)
                return level * amount
            end,

            ["get" .. u.stat .. "Modifier"] = function(self, level)
                return self:getValues(level)
            end,

            procGen = {
                weight = u.weight or DEFAULT_WEIGHT,
                needs = u.needs,
                distance = {2,10}
            },
        })
    end
end



---@class _.p1harv.CATEGORIES
local CATEGORIES = {
    {category = "grass", image="grass_3", name="Grass Crops", needs="grass_1"},
    {category = "berry", image="red_berry", name="Berry Crops", needs="blue_berry_1"},
    --{category = "fish", image="fish", name="Fish"},
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

        procGen = {
            weight = 1,
            distance = {10,20},
            needs = c.needs
        },

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

    procGen = {
        weight = 2,
        distance = {5,8}
    },

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



