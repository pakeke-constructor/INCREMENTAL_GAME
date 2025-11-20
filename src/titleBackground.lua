local TILE_SIZE = 64
local BACKGROUND_DIAG1 = objects.Color("#".."FFCF5ED9")
local BACKGROUND_DIAG2 = objects.Color("#".."FF1862D8")

local canvas = love.graphics.newCanvas(TILE_SIZE, TILE_SIZE)
local time = love.math.random()
local backgroundMesh = love.graphics.newMesh({
    {0, 0, 0, 0, unpack(BACKGROUND_DIAG1)},
    {1, 0, 1, 0, unpack(BACKGROUND_DIAG2)},
    {1, 1, 1, 1, unpack(BACKGROUND_DIAG1)},
    {0, 1, 0, 1, unpack(BACKGROUND_DIAG2)},
}, "fan", "static")

local titleBackground = {}

---@param dt number
function titleBackground.update(dt)
    time = (time + dt * 0.2) % 1

    -- Update canvas
    love.graphics.push("all")

    love.graphics.origin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 1, 1, 0)
    love.graphics.setColor(1, 1, 1)

    -- Draw cat
    local catX = (1 - time) * TILE_SIZE
    local catY = (1 - time) * TILE_SIZE
    -- This double loop emulates wrapping
    for oy = -1, 1 do
        for ox = -1, 1 do
            g.drawImage("happy_cat", catX + ox * TILE_SIZE, catY + oy * TILE_SIZE, -math.pi / 4, 1.5)
        end
    end

    -- Draw text "CaT"
    local text = "CaT"
    local font = g.getSmallFont(32)
    local tx = time * TILE_SIZE
    local ty = (1 - time) * TILE_SIZE
    local tw = font:getWidth(text)
    local th = font:getHeight()
    -- This double loop emulates wrapping
    for oy = -1, 1 do
        for ox = -1, 1 do
            -- Ok the previous dual loop is for the corners of the canvas.
            -- This one is to emulate "thick" text without {o} richtext.
            for offx = -1, 1, 1 do
                for offy = -1, 1, 1 do
                    love.graphics.print(
                        text,
                        font,
                        tx + ox * TILE_SIZE + offx,
                        ty + oy * TILE_SIZE + offy,
                        -math.pi / 4,
                        1, 1,
                        tw / 2, th / 2
                    )
                end
            end
        end
    end

    love.graphics.pop()
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

    love.graphics.setColor(0, 0, 0, 0.3)
    for y = 0, tileH - 1 do
        for x = 0, tileW - 1 do
            love.graphics.draw(canvas, x * TILE_SIZE - tileOffX, y * TILE_SIZE - tileOffY)
        end
    end
end

return titleBackground
