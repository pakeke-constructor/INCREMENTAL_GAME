
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
        assert(type(FreeCameraScene[k]) ~= "function", "Attempted to overwrite method!")
        rawset(t,k,v)
    end
}


FreeCameraScene.panSpeed = 300
FreeCameraScene._isCamAttached = false
FreeCameraScene.allowMousePan = true


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



local MAP_BUTTON = "{wavy}{c r=0.9 g=0.8 b=0.85}{o}" .. loc("Back to Map", {}, {
    context = "A button that leads back to the game-map"
}) .. "{/o}{/c}{/wavy}"

function FreeCameraScene:renderMapButton()
    local r = ui.getScreenRegion()
    local header,_ = r:splitVertical(1,5)

    local left, right = header:moveUnit(0,16):splitHorizontal(7,1)
    local mapButton = right:padRatio(0.2)

    lg.setColor(1,1,1)
    if iml.isHovered(mapButton:get()) then
        g.drawImageContained("map_button_hover", mapButton:get())
    end
    g.drawImageContained("map_button", mapButton:get())
    local _,txtR = right:splitVertical(3,1)
    richtext.printRichContained(MAP_BUTTON, g.getSmallFont(16), txtR:get())
    if iml.wasJustClicked(mapButton:get()) then
        g.gotoScene("map_scene")
    end

    return right
end



local function resume()
    if g.hasSession() then
        g.getSn().paused = false
    end
end

local function settings()
    g.gotoScene("setting_scene")
end

local function exit()
    g.gotoScene("title_scene")
end

local PAUSE_BUTTONS = {
    {loc"Resume", objects.Color("#" .. "FFE0AC35"), objects.Color("#" .. "FFD78F0A"), resume},
    {loc"Settings", objects.Color("#" .. "FF9F14F6"), objects.Color("#" .. "FF3B12A4"), settings},
    {loc"Exit", objects.Color("#".."FFF26957"), objects.Color("#".."FF4E0E05"), exit}
}
local PAUSE_BUTTON_SIZE = {144, 40}
local PAUSE_BUTTON_PAD = 4
local PAUSE_TEXT = "{w}{o thickness=2}"..loc("PAUSED").."{/o}{/w}"

function FreeCameraScene:renderPause()
    if g.hasSession() and g.getSn().paused then
        local r = ui.getScreenRegion()
        iml.panel(r:get()) -- Prevent propagation to bottom panels

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", r:get())

        -- Setup layout
        local buttonGridR = Kirigami(0, 0, PAUSE_BUTTON_SIZE[1], PAUSE_BUTTON_SIZE[2] * #PAUSE_BUTTONS)
            :center(r)
        local pauseFont = g.getBigFont(64)
        local pauseTextWidth = richtext.getWidth(PAUSE_TEXT, pauseFont)
        local pauseTextR = Kirigami(0, 0, pauseTextWidth, pauseFont:getHeight())
            :center(r:set(nil, nil, nil, buttonGridR.y))

        -- Draw pause text
        love.graphics.setColor(1, 1, 1)
        richtext.printRich(PAUSE_TEXT, pauseFont, pauseTextR.x, pauseTextR.y, pauseTextR.w, "center")

        -- Draw pause buttons
        local buttonGrid = buttonGridR:grid(1, #PAUSE_BUTTONS)
        for i, v in ipairs(PAUSE_BUTTONS) do
            local buttonR = buttonGrid[i]:padUnit(PAUSE_BUTTON_PAD)

            love.graphics.setColor(1, 1, 1)
            if ui.Button("{o thickness=0.5}"..v[1].."{/o}", v[2], v[3], buttonR) then
                v[4]()
            end
        end
    end
end





---@param dt number
function FreeCameraScene:updateCamera(dt)
    local camera = self.camera
    camera:setViewport(0, 0, love.graphics.getDimensions())

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


---@param x number
function FreeCameraScene:scaleFromZoom(x)
    return math.exp(x)
end

---@param x number
function FreeCameraScene:zoomFromScale(x)
    return math.log(x)
end

---@param z number
function FreeCameraScene:setZoom(z)
    self._zoomIndex = z
    self.camera:setZoom(self:scaleFromZoom(self._zoomIndex))
end



---@param x number
---@param y number
---@param dx number
---@param dy number
function FreeCameraScene:defaultMousemoved(x, y, dx, dy)
    if self.allowMousePan and love.mouse.isDown(2, 3) then
        local cx, cy = self.camera:getPos() --[[@as number]]
        local z = self:scaleFromZoom(self._zoomIndex)

        self.camera:setPos(cx - dx / z, cy - dy / z)
    end
end



function FreeCameraScene:defaultWheelmoved(dx,dy)
    return self:setZoom(self._zoomIndex + dy/5)
end



function FreeCameraScene:defaultKeyreleased(k)
end



local function newFreeCameraScene()
    local scene = setmetatable({
        camera = Camera(),
        _isCamAttached = false,
        _zoomIndex = 0,
        allowMousePan = true,
    }, FreeCameraScene_mt)
    scene.camera:setViewport(0, 0, love.graphics.getDimensions())

    return scene
end


return newFreeCameraScene


