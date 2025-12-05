assert((...):sub(-5) ~= ".init")

local subpixel = {}

subpixel.shader = love.graphics.newShader("src/modules/subpixel/subpixel_grad.frag")

return subpixel
