
--[[

World

The world is a container for harvestable tokens, and other stuff.  
Used by the harvest-scene

]]


local world = {}


function world.init()
    world.tokens = objects.Set()

    world.thingAddBuffer = objects.Set()
    world.things = objects.Set()
    world.thingRemBuffer = objects.Set()
end



function world.addThing(thing)
    assert(type(thing) == "table")
    assert(thing.update)
    assert(thing.type)
    assert(thing.draw)
end


function world.removeThing(thing)
end




function world.draw()
    drawGround()

    drawTokens()
    drawThings()
end




function world.update(dt)
    for _, area in ipairs(self.areas) do
        -- if area:
        local objs = getOverlappingObjs(area)
        for _,o in ipairs(objs) do
            g.damage(o, 1)
        end
    end
end




return world

