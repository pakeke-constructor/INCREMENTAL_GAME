

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")
local FishingWorld = require("src.world.fishing.fishing_world")
local FisherCat = require("src.world.fishing.fisher_cat")

---@class FishingScene: FreeCameraScene
local fishing = FreeCameraScene()

-- Random time to choose from
local GOOD_REEL_IN_TIME_RANGE = {3, 5}
-- Reel in timing window in seconds to get a catch
local CATCH_TIMING_WINDOW = 1

-- We should have this in like a helper function

---@param a number
---@param b number
---@param t number
local function lerp(a, b, t)
    return (1 - t) * a + t * b
end

local function rerollTimer()
    return lerp(GOOD_REEL_IN_TIME_RANGE[1], GOOD_REEL_IN_TIME_RANGE[2], love.math.random())
end

---@param x number value between [0, 1]. At 0.5, return value is 1.
local function pingpong(x)
    return 2 * math.min(x, 1 - x)
end

-- Note: this table MUSt be sorted by lowest window to highest.
---@type {window:number,name:string,rarity:(fun():g.FishingRarity?)}[]
local SPACING = {
    {
        window = 0.1,
        rarity = function()
            return "epic"
        end
    },
    {
        window = 0.3,
        rarity = function()
            return "rare"
        end
    },
    {
        window = 0.55,
        rarity = function()
            return "common"
        end
    },
    {
        window = 0.7,
        rarity = function()
            if love.math.random() <= 0.5 then
                return "common"
            end
            return nil
        end
    },
    {
        window = 1.0,
        rarity = function()
            return nil
        end
    }
}

function fishing:init()
    self.allowMousePan = false
    -- Not sure if this should be session or here but let's put it here for now.
    self.world = FishingWorld()
    self.mainCat = FisherCat(0, 0)
    self.world.mainFishercat = self.mainCat
    self.catchTime = -CATCH_TIMING_WINDOW
    self.reelInMeterPosition = 0 -- between 0 and 1 but will be translated to 0..1 in ping pong manner.
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

    self.reelInMeterPosition = (self.reelInMeterPosition + dt * 0.5) % 1
end

function fishing:_isCatchHit()
    if self.mainCat.animationState == "fishing" then
        return self.catchTime < 0 and self.catchTime > -CATCH_TIMING_WINDOW
    end

    return false
end

local ALLOWED_STATE = {
    idle = true,
    fishing = true,
    reeling = true
}

function fishing:drawUI()
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())

    if ALLOWED_STATE[self.mainCat.animationState] then
        local startButtonR = Kirigami(0, 0, 120, 74)
            :attachToBottomOf(r)
            :attachToRightOf(r)
            :moveRatio(-1, -1)
            :moveUnit(-8, -8)

        local text = "Cast Fishing Rod"
        if self.mainCat.animationState == "fishing" then
            text = "Pull Fishing Rod"
        elseif self.mainCat.animationState == "reeling" then
            text = "Catch!"

            local catchMeterR = startButtonR:set(nil, nil, nil, 30)
                :moveRatio(0, -1)
                :moveUnit(0, -4)
            local x, y, w, h = catchMeterR:get()
            local xsize = w / 2

            -- Draw outline of the catch meter
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", x, y, w, h)

            -- Draw catch ranges
            -- Note: The defined spacing is from lowest to highest. We want to render from highest to lowest.
            for i = #SPACING, 1, -1 do
                local index = (#SPACING - i) / (#SPACING - 1)
                local rc, gc, bc = objects.Color.HSLtoRGB(lerp(22, 90, index), 1, 0.6)

                love.graphics.setColor(rc, gc, bc)
                love.graphics.rectangle(
                    "fill",
                    x + xsize * (1 - SPACING[i].window),
                    y,
                    2 * xsize * SPACING[i].window,
                    h
                )
            end

            -- Draw reel catch position
            local linepos = pingpong(self.reelInMeterPosition) * w
            love.graphics.setColor(0, 0, 0)
            love.graphics.line(x + linepos, y, x + linepos, y + h)
        end

        if ui.Button(text, startButtonR:get()) then
            if self.mainCat.animationState == "idle" then
                self.mainCat:startFishing()
            elseif self.mainCat.animationState == "fishing" then
                if self:_isCatchHit() then
                    -- TODO: Minigame
                    print("Hit it")
                    self.mainCat:reelIn()
                else
                    self.mainCat:pullRod()
                end

                self.catchTime = -1
            elseif self.mainCat.animationState == "reeling" then
                local accuracy = 2 * math.abs(pingpong(self.reelInMeterPosition) - 0.5)
                local rarity = nil
                for _, spc in ipairs(SPACING) do
                    if accuracy <= spc.window then
                        rarity = spc.rarity()
                        break
                    end
                end

                print("Rarity", rarity)
                if rarity then
                    self.world:giveLootRewardFor(rarity)
                else
                    print("No fish :pensivebear:")
                end
                self.mainCat:pullRod()
            end
        end
    end

    -- Debug
    local w, h = ui.getScaledUIDimensions()
    local f = g.getSmallFont(16)
    richtext.printRich("catchtime\n"..tostring(self.catchTime), f, 4, h / 2, w, "left")
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
    self:setZoom(1)
    self.world:draw()

    self:resetCamera()

    vignette.draw()

    ui.startUI()

    self:drawUI()
    self:renderNavbar()

    g.getHUD():draw(self.camera)
    ui.endUI()
end

fishing.keyreleased = fishing.defaultKeyreleased

return fishing
