local objects = require("src.modules.objects.objects")

---@class FSCanvas: objects.Class
local FSCanvas = objects.Class("fscanvas:FSCanvas")


---@param format love.PixelFormat?
function FSCanvas:init(format)
    ---@type love.PixelFormat
    self.format = format or "normal"
    ---@type love.Texture|nil
    self.canvas = nil
    self.width = -1
    self.height = -1
end

if false then
    ---@param format love.PixelFormat?
    ---@return FSCanvas
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function FSCanvas(format) end
end

---@return love.Texture
function FSCanvas:get()
    local w, h = love.graphics.getDimensions()
    if self.width ~= w or self.height ~= h or not self.canvas then
        if self.canvas then
            self.canvas:release()
            self.canvas = nil
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        self.canvas = love.graphics.newCanvas(nil, nil, {format = self.format})
        self.width = w
        self.height = h
    end

    return self.canvas
end

return FSCanvas
