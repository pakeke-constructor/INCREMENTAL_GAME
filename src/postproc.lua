---@class postproc
local postproc = {}

---@type {[1]:love.Texture,depthstencil:love.Texture}|nil
local canvas = nil
local crt = love.graphics.newShader("src/crt.frag")
crt:send("CRT_CURVE_AMNT", {0.05, 0.05})
crt:send("SCAN_LINE_MULT", 625)
crt:send("SCAN_LINE_STRENGTH", 0.02)

function postproc.start()
    love.graphics.push("all")

    -- If dimension is mismatched, rebuild canvas.
    if canvas then
        local w, h = love.graphics.getDimensions()
        if canvas[1]:getWidth() ~= w or canvas[1]:getHeight() ~= h then
            canvas[1]:release()
            canvas.depthstencil:release()
            canvas = nil
        end
    end
    if not canvas then
        canvas = {
            love.graphics.newCanvas(),
            ---@diagnostic disable-next-line: param-type-mismatch
            depthstencil = love.graphics.newCanvas(nil, nil, {format = "stencil8"})
        }
        canvas[1]:setFilter("linear", "linear")
        canvas.depthstencil:setFilter("linear", "linear")
    end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(true, true, true)
end

function postproc.finish()
    assert(canvas, "postproc not begin?")
    love.graphics.pop()

    love.graphics.push("all")
    love.graphics.setShader(crt)
    love.graphics.draw(canvas[1])
    love.graphics.pop()
end

return postproc
