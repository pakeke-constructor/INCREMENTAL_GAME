



local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

---@class ChestScene: FreeCameraScene
---@field chestOpening ChestScene.ChestOpening?
local chestScene = FreeCameraScene()

local lg = love.graphics


---@class ChestScene.ChestOpening
---@field timeOpened number
-- put other data here. Like request-handle maybe? idk.


function chestScene:init()
    self.chestOpening = nil
end


---@param dt number
function chestScene:update(dt)
end





function chestScene:draw()
    local r = ui.getScreenRegion()
    lg.clear(0.7,1,1)
    ui.startUI()
    if ui.DefaultButton("buy chest", r:padRatio(0.6)) then
        -- TODO: REQUEST FROM LUASTEAM HERE.
        self.chestOpening = {
            timeOpened = love.timer.getTime()
        }
    end
    ui.endUI()
end


function chestScene:mousepressed(mx,my,button)
end


chestScene.keyreleased = chestScene.defaultKeyreleased

return chestScene




