

local harvest = {}



local SAPLING = {
    -- x,y,w,h
    80,80,20,20
}


local MONEY_INTERP = localization.newInterpolator("{wavy}{outline}MONEH: %{money}")

function harvest:draw()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)

    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    local txt = MONEY_INTERP({
        money = (math.floor(g.getMoney()))
    })
    richtext.printRichContained(txt, love.graphics.getFont(), 10, 10, 80, 20)

    local _,map = body:padRatio(0.3):splitHorizontal(2,1)
    if ui.Button("MAP", map:padRatio(0.1):get()) then
        g.gotoScene("map")
    end

    love.graphics.rectangle("fill", unpack(SAPLING))
end


function harvest:update(dt)
    local mx,my = love.mouse.getPosition()

    local x,y,w,h = unpack(SAPLING)
    if mx >= x and mx <= x + w and my >= y and my <= y + h then
        g.addMoney(5 * dt)
    end
end


return harvest

