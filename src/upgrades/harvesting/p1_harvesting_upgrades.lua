




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
        increase = 0.3
    },
    {
        id = "more_speed",
        title = "More Speed",
        desc = "%{1} scythe speed",
        stat = "HitSpeed",
        increase = 1
    },
    {
        id = "more_area",
        title = "More Area",
        desc = "%{1} area",
        stat = "HarvestArea",
        increase = 2
    }
}

for _, u in ipairs(upgrades) do
    defUpgrade("percentage_"..u.id, u.title, {
        image = u.id,

        getValues = function(self, level)
            return level
        end,
        valueFormatter = {"+%d%%"},
        description = u.desc,

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

        ["get" .. u.stat .. "Multiplier"] = function(self, level)
            local a = self:getValues(level)
            return 1 + (a / 100)
        end
    })

    defUpgrade("flat_"..u.id, u.title, {
        image = u.id,

        getValues = function(self, level)
            return level*u.increase
        end,

        valueFormatter = {"+%.1f"},
        description = u.desc,

        ["get" .. u.stat .. "Modifier"] = function(self, level)
            return self:getValues(level)
        end
    })
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



