

## ARCHITECTURE PLANNING:


Everything in `src` is loaded once.
It represents all the engine stuff.
```
src/
    es/ entity-system stuff
    objects/ common data-structures
    g.lua  core API, exposed to world-files

    systems/ 
        Any code that makes the game "work" is here.
        Eg. draw, input, physics, enemy-spawning, etc
    entities/
        characters/ (includes ability-definitions!)
```



-------------


ECS, except ents are added to systems manually.
EG:
```lua
local e = {x=1, y=1, image="bullet"}


-- ALL entities have an x,y component
local EType = g.EntityType("my_ent", {
    init = function(ent, x, y)
    end,

    name = "foo",
    maxHealth = 1
})



local Sys = g.System()

function Sys:init()
    self.data = 5 
    -- store any data you want here.
    -- will be saved alongside the world.

    -- when a new world is created, 
    -- the `:init` function will be called again
end

function Sys:drawEntity(ent)
    -- called when you do `world:call("drawEntity", ent)`
end


g.getSystem(SystemClass) -- gets the system-instance from a SystemClass
g.getWorld()




-- attachments can hook onto callbacks, called automatically :call()
local a = attachments
e:attach(a.Buff("health", {time = 10, potency = 2}))
e:attach(a.Fire({time = 200})) -- fire lasts for 200 seconds

e:attach(a.Explosive(3)) -- entity explodes on death






local DrawSys = g.ComponentSystem("drawable")
-- component-systems can only take 1 component. 
-- This works for like 95% of the use cases, in practice


function DrawSys:onAdded(ent)
end
function DrawSys:onRemove(ent)
end


function DrawSys:draw()
    for _,e in self:ipairs() do
        drawEntity(e)
    end
end

DrawSys:flush()
-- does all addition operations, and all removal operations.
-- (called automaticaly)



```

