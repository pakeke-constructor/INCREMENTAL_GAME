

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")
local FishingWorld = require("src.world.fishing.fishing_world")
local FisherCat = require("src.world.fishing.fisher_cat")

---@class FishingScene: FreeCameraScene
local fishing = FreeCameraScene()

-- Random time to choose from
local GOOD_REEL_IN_TIME_RANGE = {5, 60}
-- Reel in timing window in seconds to get a catch
local CATCH_TIMING_WINDOW = 1

-- We should have this in like a helper function
local function rerollTimer()
    local r = love.math.random()
    local diff = GOOD_REEL_IN_TIME_RANGE[2] - GOOD_REEL_IN_TIME_RANGE[1]
    return GOOD_REEL_IN_TIME_RANGE[1] + diff * r
end

function fishing:init()
    self.allowMousePan = false
    -- Not sure if this should be session or here but let's put it here for now.
    self.world = FishingWorld()
    self.mainCat = FisherCat(0, 0)
    self.world.mainFishercat = self.mainCat
    self.catchTime = -CATCH_TIMING_WINDOW
end

---@param dt number
function fishing:update(dt)
    self.world:update(dt)

    if self.mainCat.animationState == "fishing" then
        self.catchTime = self.catchTime - dt
        if self.catchTime < -CATCH_TIMING_WINDOW then
            -- Reroll
            self.catchTime = rerollTimer()
        end
    end
end

function fishing:_isCatchHit()
    if self.mainCat.animationState == "fishing" then
        return self.catchTime < 0 and self.catchTime > -CATCH_TIMING_WINDOW
    end

    return false
end

function fishing:drawUI()
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())

    if self.mainCat.animationState == "idle" or self.mainCat.animationState == "fishing" then
        local startButtonR = Kirigami(0, 0, 120, 74)
            :attachToBottomOf(r)
            :attachToRightOf(r)
            :moveRatio(-1, -1)
            :moveUnit(-8, -8)

        local text = "Cast Fishing Rod"
        if self.mainCat.animationState == "fishing" then
            text = "Pull Fishing Rod"
        end

        if ui.Button(text, startButtonR:get()) then
            if self.mainCat.animationState == "idle" then
                self.mainCat:startFishing()
            elseif self.mainCat.animationState == "fishing" then
                if self:_isCatchHit() then
                    -- TODO: Minigame
                    print("Hit it")
                end
                self.mainCat:pullRod()
                self.catchTime = -1
            end
        end
    end

    -- Debug
    local f = g.getSmallFont(16)
    local debugR = r:set(nil, nil, nil, f:getHeight())
        :attachToBottomOf(r)
        :moveRatio(0, -1)
    richtext.printRich(tostring(self.catchTime), f, debugR.x, debugR.y, debugR.w, "left")
end

function fishing:draw()
    if fishing:_isCatchHit() then
        love.graphics.clear(0.92, 0.35, 0.2, 1)
    else
        love.graphics.clear(0, 0.64, 0.91, 1)
    end
    love.graphics.setColor(1,1,1)

    self:setCamera()
    self.camera:setPos(0, 0)
    self.world:draw()

    self:resetCamera()

    vignette.draw()

    ui.startUI()

    self:drawUI()
    self:renderNavbar()

    g.getHUD():draw(self.camera, {profile = false})
    ui.endUI()
end

fishing.keyreleased = fishing.defaultKeyreleased

return fishing
