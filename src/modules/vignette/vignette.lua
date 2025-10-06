

local vignette = {}


local vignetteColor = {1,1,1}
local vignetteStrength = 0.4
local canvasDirty = true



local setColorTC = typecheck.assert("table")

function vignette.setColor(color)
    setColorTC(color)
    canvasDirty = true
end


local setStrengthTC = typecheck.assert("number")


function vignette.setStrength(strength)
    setStrengthTC(strength)
    vignetteStrength = strength
end





local LEIGH = 4

local canvas = love.graphics.newCanvas(
    love.graphics.getWidth() + LEIGH,
    love.graphics.getHeight() + LEIGH
)

-- avoid banding:
canvas:setFilter("linear","linear")



function vignette.resize()
    canvas = love.graphics.newCanvas(
        love.graphics.getWidth() + LEIGH,
        love.graphics.getHeight() + LEIGH
    )
    canvasDirty = true
end



--[[
    important note:
    This image is stored OUTSIDE of assets/images,
    which means that it won't be loaded by the texture atlas.
]]
local DEFAULT_VIGNETTE_IMAGE = "src/modules/vignette/vignette.png"
local vignetteImage = love.graphics.newImage(DEFAULT_VIGNETTE_IMAGE)
-- Explicitly set linear filtering to avoid banding
vignetteImage:setFilter("linear", "linear")



local function setupCanvas()
    if canvasDirty then
        love.graphics.push("all")
        love.graphics.setCanvas(canvas)
        love.graphics.clear(1,1,1,1)

        local r,g,b,a = vignetteColor[1], vignetteColor[2], vignetteColor[3], vignetteStrength
        love.graphics.setColor(r,g,b,a)
        local canvW, canvH = canvas:getDimensions()
        local imgW, imgH = vignetteImage:getDimensions()
        love.graphics.draw(vignetteImage, -LEIGH/2, -LEIGH/2, 0, canvW / imgW, canvH / imgH)

        love.graphics.pop()
        canvasDirty = false
    end
end


local function drawCanvas()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(canvas)
end



function vignette.draw()
    local mode, alphamode = love.graphics.getBlendMode()
    love.graphics.push("all")
    love.graphics.origin()

    setupCanvas()
    drawCanvas()

    love.graphics.pop()
    love.graphics.setBlendMode(mode, alphamode)
end


return vignette


