local LightWorld = {}
LightWorld.__index = LightWorld

local DEFAULT_AMBIENT = {0.2, 0.2, 0.4}
local DEFAULT_SIZE = 50
local DEFAULT_COLOR = {1, 1, 1}

local function newLightWorld(args)
    args = args or {}
    local self = setmetatable({}, LightWorld)

    -- todo; use atlas for this.
    args.lightImagePath = args.lightImagePath or "src/modules/lighting/default_light.png"
    args.lightImagePath = args.lightImagePath or "src/modules/lighting/default_light.png"

    self.light_image = love.graphics.newImage(args.lightImagePath)
    self.imageWidth, self.imageHeight = self.light_image:getDimensions()

    local w, h = love.graphics.getDimensions()
    self.canvas = love.graphics.newCanvas(w + 20, h + 20)

    self.lights = {}
    self.nextId = 1

    return self
end

function LightWorld:resize()
    local w, h = love.graphics.getDimensions()
    local cw, ch = self.canvas:getDimensions()
    if cw<w or ch<h then
        -- only construct new canvas if it needs to grow
        self.canvas = love.graphics.newCanvas(w + 20, h + 20)
    end
end


function LightWorld:addLight(x, y, size, color)
    local light = {
        id = self.nextId,
        x = x or 0,
        y = y or 0,
        size = size or DEFAULT_SIZE,
        color = color or DEFAULT_COLOR,
    }
    self.nextId = self.nextId + 1
    self.lights[light.id] = light
    return light
end

function LightWorld:remove(light)
    self.lights[light.id] = nil
end

function LightWorld:render(ambientColor)
    ambientColor = ambientColor or DEFAULT_AMBIENT
    local mode, alphamode = love.graphics.getBlendMode()

    love.graphics.push()
    local canv = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(ambientColor[1], ambientColor[2], ambientColor[3])

    for _, light in pairs(self.lights) do
        local scale = light.size / self.imageWidth
        local c = light.color
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.draw(self.light_image, light.x, light.y, 0, scale, scale, 
                          self.imageWidth/2, self.imageHeight/2)
    end

    love.graphics.setCanvas(canv)
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(self.canvas)
    love.graphics.setBlendMode(mode, alphamode)
    love.graphics.pop()
end


function LightWorld:clear()
    self.lights = {}
end


return newLightWorld

