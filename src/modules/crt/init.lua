assert((...):sub(-5) ~= ".init")

local FSCanvas = require("src.modules.fscanvas.fscanvas")

---@class CRT
local crt = {}

crt.mainCanvas = FSCanvas()
crt.depthCanvas = FSCanvas("depth24stencil8")
crt.started = false
crt.shader = love.graphics.newShader("src/modules/crt/crt.frag")
crt.shader:send("CRT_CURVE_AMNT", {0.05, 0.05})
crt.shader:send("SCAN_LINE_MULT", 625)
crt.shader:send("SCAN_LINE_STRENGTH", 0.02)

function crt.start()
    assert(not crt.started, "crt already begin?")
    love.graphics.push("all")
    love.graphics.setCanvas({crt.mainCanvas:get(), depthstencil = crt.depthCanvas:get()})
    love.graphics.clear(true, true, true)
    crt.started = true
end

function crt.finish()
    assert(crt.started, "crt not begin?")
    love.graphics.pop()

    love.graphics.push("all")
    love.graphics.setShader(crt.shader)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(crt.mainCanvas:get())
    love.graphics.pop()
    crt.started = false
end

return crt
