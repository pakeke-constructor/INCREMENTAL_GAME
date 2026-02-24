local TILE_SIZE = 96

local time = love.math.random()
local backgroundMesh = love.graphics.newMesh({
    {0, 0, 0, 0, unpack(objects.Color("#".."FF050390"))},
    {1, 0, 1, 0, unpack(objects.Color("#".."FF7115B7"))},
    {1, 1, 1, 1, unpack(objects.Color("#".."FF1862D8"))},
    {0, 1, 0, 1, unpack(objects.Color("#".."FF142DCD"))},
}, "fan", "static")


-- hmm, what ones the best?
-- local CAT = "CaT"
-- local CAT = "CaT CaT"
-- local CAT = "CAT"
local CAT = "CAT CAT"

local titleBackground = {}

---@param dt number
function titleBackground.update(dt)
    time = (time + dt * 0.125) % 1
end

function titleBackground.draw()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(backgroundMesh, 0, 0, 0, love.graphics.getDimensions())
    love.graphics.pop()

    -- Draw canvas tiles
    local uiW, uiH = ui.getScaledUIDimensions()
    local tileW = math.ceil(uiW / TILE_SIZE)
    local tileH = math.ceil(uiH / TILE_SIZE)
    local tileOffX = (tileW * TILE_SIZE - uiW) / 2
    local tileOffY = (tileH * TILE_SIZE - uiH) / 2

    love.graphics.setColor(1, 1, 1, 0.3)

    -- Draw cat silhouette
    for ty = -1, tileH do
        for tx = -1, tileW do
            local i = (tx + ty % 2) % 2
            local x, y
            if i == 0 then
                -- Bottom-left to top-right
                x = time * TILE_SIZE
                y = (1 - time) * TILE_SIZE
            else
                -- Top-right to bottom-left
                x = (1 - time) * TILE_SIZE
                y = time * TILE_SIZE
            end
            g.drawImage("cat_silhouette", tx * TILE_SIZE - tileOffX + x, ty * TILE_SIZE - tileOffY + y, -math.pi/4, 2, 2)
        end
    end

    -- Draw cat text
    local text = CAT
    local font = g.getSmallFont(16)
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local j = (time + 0.5) % 1
    for ty = -1, tileH do
        for tx = -1, tileW do
            local i = (tx + ty % 2) % 2
            local x, y
            if i == 0 then
                -- Bottom-left to top-right
                x = j * TILE_SIZE
                y = (1 - j) * TILE_SIZE
            else
                -- Top-right to bottom-left
                x = (1 - j) * TILE_SIZE
                y = j * TILE_SIZE
            end
            love.graphics.print(
                text,
                font,
                tx * TILE_SIZE - tileOffX + x,
                ty * TILE_SIZE - tileOffY + y,
                -math.pi / 4,
                2, 2,
                tw / 2, th / 2
            )
        end
    end
end

return titleBackground
