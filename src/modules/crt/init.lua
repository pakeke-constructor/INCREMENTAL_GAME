assert((...):sub(-5) ~= ".init")

---@class CRT
local crt = {}

---@type {[1]:love.Texture,depthstencil:love.Texture}|nil
crt.canvas = nil
crt.shader = love.graphics.newShader("src/modules/crt/crt.frag")
crt.shader:send("CRT_CURVE_AMNT", {0.05, 0.05})
crt.shader:send("SCAN_LINE_MULT", 625)
crt.shader:send("SCAN_LINE_STRENGTH", 0.02)

function crt.start()
    love.graphics.push("all")

    -- If dimension is mismatched, rebuild canvas.
    if crt.canvas then
        local w, h = love.graphics.getDimensions()
        if crt.canvas[1]:getWidth() ~= w or crt.canvas[1]:getHeight() ~= h then
            crt.canvas[1]:release()
            crt.canvas.depthstencil:release()
            crt.canvas = nil
        end
    end
    if not crt.canvas then
        crt.canvas = {
            love.graphics.newCanvas(),
            ---@diagnostic disable-next-line: param-type-mismatch
            depthstencil = love.graphics.newCanvas(nil, nil, {format = "stencil8"})
        }
        crt.canvas[1]:setFilter("linear", "linear")
        crt.canvas.depthstencil:setFilter("linear", "linear")
    end

    love.graphics.setCanvas(crt.canvas)
    love.graphics.clear(true, true, true)
end

function crt.finish()
    assert(crt.canvas, "crt not begin?")
    love.graphics.pop()

    love.graphics.push("all")
    love.graphics.setShader(crt.shader)
    love.graphics.draw(crt.canvas[1])
    love.graphics.pop()
end

return crt
