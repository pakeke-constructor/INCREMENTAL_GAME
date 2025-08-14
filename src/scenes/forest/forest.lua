

local forest = {}



local SAPLING = {
    -- x,y,w,h
    80,80,20,20
}


function forest:draw()
    love.graphics.setColor(0,1,0)
    love.graphics.print("MONEH: " .. tostring(math.floor(g.getMoney())), 20, 20)

    love.graphics.rectangle("fill", unpack(SAPLING))
end


function forest:update(dt)
    local mx,my = love.mouse.getPosition()

    local x,y,w,h = unpack(SAPLING)
    if mx >= x and mx <= x + w and my >= y and my <= y + h then
        g.addMoney(5 * dt)
    end
end


return forest

