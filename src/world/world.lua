
--[[

World

The world is a container for harvestable tokens, and other stuff.  
Used by the harvest-scene

]]


local World = {}


function World:init()
    self.tokens = objects.Set()

    self.rembuffer = objects.Set()
    self.addbuffer = objects.Set()
end


---@param tabl table
function World:addObject(tabl)
    assert(tabl.x and tabl.y)
    self.rembuffer:remove(tabl)
    self.addbuffer:add(tabl)
end


---@param tabl table
function World:removeObject(tabl)
    self.rembuffer:add(tabl)
    self.addbuffer:remove(tabl)
end


function World:draw()
    self:drawGround()

    self:drawStuff()
end


function World:update(dt)
    self:drawGround()

    self:drawStuff()
end




return World

