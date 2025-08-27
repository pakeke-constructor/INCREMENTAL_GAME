
--[[

World

The world is a container for harvestable tokens, and other stuff.  
Used by the harvest-scene

]]


local world = {}


function world.init()
    world.tokens = objects.Set()
end



function world.draw()
    self:drawGround()

    drawTokens()
    drawTools()
end




function world.update(dt)
    self:drawGround()

    self:drawStuff()

    for _, area in ipairs(self.areas) do
        -- if area:
        local objs = getOverlappingObjs(area)
        for _,o in ipairs(objs) do
            g.damage(o, 1)
        end
    end
end




return world

