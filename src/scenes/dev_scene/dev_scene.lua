local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

---@class DevScene: FreeCameraScene
local dev = FreeCameraScene()

function dev:init()
end



---@param font love.Font
---@param width number
---@param text string
local function regionFromText(font, width, text)
    local maxwidth, lines = font:getWrap(richtext.stripEffects(text), width)
    return Kirigami(0, 0, maxwidth, #lines * font:getHeight())
end


---------------------
-- Resource Mod scene
---------------------

---@param r layout.Region
---@param resId string
local function drawResourceType(r, resId)
    local b1, b2, b3, b4 = r:splitVertical(1, 1, 1, 1)
    local limit = g.getResourceLimit(resId)

    if ui.Button("MAX "..resId, b1:padUnit(4):get()) then
        g.addResource(resId, limit)
    end
    if ui.Button("+10% "..resId, b2:padUnit(4):get()) then
        g.addResource(resId, math.floor(limit/10+0.5))
    end
    if ui.Button("-10% ".. resId, b3:padUnit(4):get()) then
        g.addResource(resId, -math.floor(limit/10+0.5))
    end
    if ui.Button("ZERO "..resId, b4:padUnit(4):get()) then
        g.addResource(resId, -limit)
    end
end

---@param r layout.Region
local function drawResourceSceneUI(r)
    local grid = r:padRatio(0.05):grid(#g.RESOURCE_LIST, 1)

    for i, resId in ipairs(g.RESOURCE_LIST) do
        drawResourceType(grid[i], resId)
    end
end


----------------
-- Harvest scene
----------------

---@param dt number
local function updateHarvestScene(dt)
    local world = g.getMainWorld()
    world:_update(dt)
end

local function drawHarvestScene()
    local world = g.getMainWorld()
    world:_draw()
end

local harvestTokenSpawnText = table.concat({
    "Token Spawner",
    "[Up Arrow] = Select Above",
    "%d. %s",
    "> {wavy}%d. %s{/wavy} <",
    "%d. %s",
    "[Down Arrow] = Select Below",
    "[T | MB4] = Spawn @ Mouse Pos"
}, "\n")

local selectedTokenIndex = 1

---@param r layout.Region
local function drawHarvestSceneUI(r)
    local font = g.getSmallFont(16)
    local tokenPrev = (selectedTokenIndex - 2) % #g.TOKEN_LIST + 1
    local tokenNext = selectedTokenIndex % #g.TOKEN_LIST + 1
    local fmt = string.format(
        harvestTokenSpawnText,
        tokenPrev, g.TOKEN_LIST[tokenPrev],
        selectedTokenIndex, g.TOKEN_LIST[selectedTokenIndex],
        tokenNext, g.TOKEN_LIST[tokenNext]
    )
    local finalText = "{o}"..fmt.."{/o}"
    local textR = regionFromText(font, 500, finalText)
        :attachToBottomOf(r)
        :attachToRightOf(r)
        :moveRatio(-1, -1)
        :moveUnit(-4, -4)
    richtext.printRich(finalText, font, textR.x, textR.y, textR.w, "left")
end




local function dummy() end
local SCENES = {
    -- Update, draw, drawUI
    {dummy, dummy, drawResourceSceneUI},
    {updateHarvestScene, drawHarvestScene, drawHarvestSceneUI}
}
local currentSceneNumber = 1



local helpText = table.concat({
    "[H] = Show Harvest Area",
    "[U] = Show Upgrade Editor",
    "[R] = Toggle Resource Modification Mode"
}, "\n")


local function drawDevUI()
    SCENES[currentSceneNumber][3](g.getHUD():getSafeArea())

    local font = g.getSmallFont(16)
    local finalText = "{o}"..helpText.."{/o}"
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())
    local textR = regionFromText(font, 500, finalText)
        :attachToBottomOf(r)
        :attachToLeftOf(r)
        :moveRatio(1, -1)
        :moveUnit(4, -4)

    love.graphics.setColor(1, 1, 1)
    richtext.printRich(finalText, font, textR.x, textR.y, textR.w, "left")
end

function dev:draw()
    local COL = objects.Color("#FF00A2E8")
    love.graphics.clear(COL)

    self:setCamera()

    SCENES[currentSceneNumber][2]()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    drawDevUI()
    self:renderNavbar()
    g.getHUD():drawResourceHUD(self.camera)
    ui.endUI()
end

function dev:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
    SCENES[currentSceneNumber][1](dt)
end

---@param scene FreeCameraScene
local function trySpawnTokenAtMouse(scene)
    local world = g.getMainWorld()
    local mx, my = love.mouse.getPosition()
    local wx, wy = scene.camera:toWorld(mx, my)

    if wx >= 0 and wy >= 0 and wx < world.WIDTH and wy < world.HEIGHT then
        g.spawnToken(g.TOKEN_LIST[selectedTokenIndex], wx, wy)
    end
end

rawset(dev, "keyreleased", function(self, k)
    if k == "h" then
        currentSceneNumber = 2
    elseif k == "r" then
        currentSceneNumber = 1
    elseif currentSceneNumber == 2 then
        if k == "up" then
            selectedTokenIndex = (selectedTokenIndex - 2) % #g.TOKEN_LIST + 1
        elseif k == "down" then
            selectedTokenIndex = selectedTokenIndex % #g.TOKEN_LIST + 1
        elseif k == "t" then
            trySpawnTokenAtMouse(self)
        end
    end
end)

rawset(dev, "mousereleased", function(self, _, _, m)
    if currentSceneNumber == 2 and m == 4 then
        trySpawnTokenAtMouse(self)
    end
end)

return dev
