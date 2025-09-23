
--[[

===============================================================
===============================================================

FreeCameraScene

A base-class for a Scene with a free-moving camera.
Contains a bunch of lil helpers n stuff

===============================================================
===============================================================

]]


---@class FreeCameraScene
---@field camera Camera
---@field panSpeed number
local FreeCameraScene = {}
local FreeCameraScene_mt = {
    __index = FreeCameraScene,
    __newindex = function(t,k,v)
        assert(not FreeCameraScene[k], "Attempted to overwrite method!")
        rawset(t,k,v)
    end
}


FreeCameraScene.panSpeed = 300
FreeCameraScene._isCamAttached = false
FreeCameraScene.allowMousePan = true
FreeCameraScene._moneyFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 32, "mono")
FreeCameraScene._resourceFont = love.graphics.newFont("assets/fonts/Smart 9h.ttf", 24, "mono")


local Camera = require("lib.cam11")



function FreeCameraScene:setCamera()
    self:resetCamera()
    self.camera:attach()
    self._isCamAttached = true
    iml.pushTransform(self.camera:getTransform())
end


function FreeCameraScene:resetCamera()
    if self._isCamAttached then
        self._isCamAttached = false
        self.camera:detach()
        iml.popTransform()
    end
end



local sceneManager

local function navTab(text, sceneName, x,y,w,h)
    sceneManager = sceneManager or require("src.scenes.sceneManager")
    local _, name = sceneManager.getCurrentScene()

    love.graphics.setColor(1,1,1)
    if iml.isHovered(x,y,w,h) then
        love.graphics.setColor(0.5,0.5,0.5)
    elseif sceneName == name then
        love.graphics.setColor(0.6,0.6,0.6)
    end

    local f = w/4
    love.graphics.polygon("fill", x,y, x+w,y, x+w-f,y+h, x+f,y+h)
    love.graphics.setColor(0,0,0)

    local txtR = Kirigami(x,y,w,h):padRatio(0.,0.7,0.,0.7)
    richtext.printRichContainedNoWrap(text, love.graphics.getFont(), txtR:get())

    if iml.wasJustClicked(x,y,w,h) then
        g.gotoScene(sceneName)
    end
end


function FreeCameraScene:renderNavbar()
    local r = Kirigami(0,0,love.graphics.getDimensions())
    local header,_ = r:splitVertical(1,6)

    local left, right = header:splitHorizontal(1,1)
    right = right:padRatio(0.2,0.0,0.2,0.1)

    local map, upgrades, harvest = right:splitHorizontal(1,1,1)

    navTab("MAP", "map_scene", map:get())
    navTab("UPGRADES ", "upgrade_scene", upgrades:get())
    navTab("HARVEST ", "harvest_scene", harvest:get())
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

function FreeCameraScene:renderResource()
    if not g.getSn() then return end

    local r = Kirigami(0,0,love.graphics.getDimensions())
    local leftR = r:splitHorizontal(1, 1, 1, 1, 1)
    local moneyR = leftR:shrinkToAspectRatio(2, 1):attachToTopOf(r):moveRatio(0, 1):padRatio(0.05)
    local resourcesR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(moneyR):padRatio(0.05)
    local profileR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(r):moveRatio(0, -1):padRatio(0.05)

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

    -- Draw dummy profile picture
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", profileR:get())
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("line", profileR:get())
end



---@param dt number
function FreeCameraScene:updateCamera(dt)
    local camera = self.camera
    local spd = self.panSpeed / math.sqrt(camera:getZoom())
    local movX,movY = 0,0
    if love.keyboard.isScancodeDown("w") then
        movY = movY - spd*dt
    end
    if love.keyboard.isScancodeDown("a") then
        movX = movX - spd*dt
    end
    if love.keyboard.isScancodeDown("s") then
        movY = movY + spd*dt
    end
    if love.keyboard.isScancodeDown("d") then
        movX = movX + spd*dt
    end
    local x,y = camera:getPos()
    camera:setPos(x+movX,y+movY)
end


local function zoom(x, k)
    k = k or 1.0  -- growth/decay rate
    return math.exp(k * x)
end


function FreeCameraScene:wheelmoved(dx,dy)
    self._zoomIndex = self._zoomIndex + dy/5
    self.camera:setZoom(zoom(self._zoomIndex, 1))
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function FreeCameraScene:mousemoved(x, y, dx, dy)
    if self.allowMousePan and love.mouse.isDown(2, 3) then
        local cx, cy = self.camera:getPos() --[[@as number]]
        local z = zoom(self._zoomIndex, 1)

        self.camera:setPos(cx - dx / z, cy - dy / z)
    end
end



local function newFreeCameraScene()
    local scene = setmetatable({
        camera = Camera(),
        _isCamAttached = false,
        _zoomIndex = 0,
        allowMousePan = true,
    }, FreeCameraScene_mt)

    return scene
end


return newFreeCameraScene


