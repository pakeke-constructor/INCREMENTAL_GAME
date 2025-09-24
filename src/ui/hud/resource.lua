local objects = require("src.modules.objects.objects")

---@class g.hud.Resources: objects.Class
local Resources = objects.Class("g.hud:Resources")
Resources._moneyFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 32, "mono")
Resources._resourceFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 24, "mono")

function Resources:init()
end

if false then
    ---@return g.hud.Resources
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Resources() end
end

---@param dt number
function Resources:update(dt)
end

---@param text string
---@param font love.Font
---@param region layout.Region
---@param align love.AlignMode
local function printTextAt(text, font, region, align)
    local x, y, w, h = region:get()
    local maxw, lines = font:getWrap(text, w)

    local th = #lines * font:getHeight()
    local ty = y + (h - th) / 2
    love.graphics.printf(text, font, x, ty, w, align)
end

---@param camera Camera
function Resources:drawHUD(camera)
    if not g.getSn() then return end

    local r = Kirigami(0,0,love.graphics.getDimensions())
    local leftR = r:splitHorizontal(1, 1, 1, 1, 1)
    local moneyR = leftR:shrinkToAspectRatio(2, 1):attachToTopOf(r):moveRatio(0, 1):padRatio(0.05)
    local resourcesR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(moneyR):padRatio(0.05)

    -- Draw money
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", moneyR:get())
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("line", moneyR:get())
    love.graphics.setColor(0, 0, 0)
    printTextAt("$"..g.getMoney(), self._moneyFont, moneyR, "center")

    -- Draw resources
    local logsR, rocksR, bonesR = resourcesR:splitVertical(1, 1, 1)
    love.graphics.setColor(1, 1, 1)
    printTextAt("Logs: "..g.getLogs(), self._resourceFont, logsR, "left")
    printTextAt("Rocks: "..g.getRocks(), self._resourceFont, rocksR, "left")
    printTextAt("Bones: "..g.getBones(), self._resourceFont, bonesR, "left")
end

---@param camera Camera
function Resources:drawParticles(camera)
end

---@param camera Camera
function Resources:draw(camera)
    self:drawHUD(camera)
    return self:drawParticles(camera)
end

function Resources:reset()
end

---@param kind "money"|"logs"|"rocks"|"bones"
---@param x number Position of the token in world-space.
---@param y number Position of the token in world-space.
---@param amount number Amount to add to the display once it's done.
function Resources:spawnParticle(kind, x, y, amount)
end

return Resources
