

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


local function rerollTimer()
    return helper.lerp(GOOD_REEL_IN_TIME_RANGE[1], GOOD_REEL_IN_TIME_RANGE[2], love.math.random())
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

    self.reelPos = 0 -- between 0 and 1
end


local CATCH_SPEED = 0.5

local function triangleWave(t, freq)
  local phase = (t * freq) % 1
  return (1 - 4 * math.abs(phase - 0.5)) / 2 + 0.5
end


---@param dt number
function fishing:update(dt)
    self.world:update(dt)

    self.reelPos = triangleWave(love.timer.getTime(), CATCH_SPEED)
end


---@param self FishingScene
local function drawReelMeter(self)
    local r,_ = Kirigami(0,0,ui.getScaledUIDimensions())
    _,r = r:splitVertical(3,2)
    _,r = r:splitHorizontal(1,2)
    r = r:padRatio(0.3,0.4,0.4,0.4)

    local x, y, w, h = r:get()
    local xsize = w / 2

    -- Draw outline of the catch meter
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", x, y, w, h)

    -- Draw catch ranges
    -- Note: The defined spacing is from lowest to highest. We want to render from highest to lowest.
    for i = #SPACING, 1, -1 do
        local index = (#SPACING - i) / (#SPACING - 1)
        local rc, gc, bc = objects.Color.HSLtoRGB(helper.lerp(22, 90, index), 1, 0.6)

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
    local linepos = self.reelPos * w
    love.graphics.setColor(0, 0, 0)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(4)
    love.graphics.line(x + linepos, y, x + linepos, y + h)
    love.graphics.setLineWidth(lw)
end



local CAST_ROD = loc("Cast fishing rod!")
local WAITING_FOR_FISH = loc("Waiting for fishy...")


function fishing:drawUI()
    love.graphics.clear(0.4,0.5,0.9)
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())

    local startButtonR = Kirigami(0, 0, 120, 74)
        :attachToBottomOf(r)
        :attachToRightOf(r)
        :moveRatio(-1, -1)
        :moveUnit(-8, -8)

    if self.mainCat.state == "idle" then
        if ui.Button(CAST_ROD, startButtonR:get()) then
            self.mainCat:cast()
        end

    elseif self.mainCat.state == "fishing" then
        love.graphics.setColor(0,0,0)
        richtext.printRich(WAITING_FOR_FISH, g.getSmallFont(32), r.x+r.w/2, r.y+r.h/2, 200, "center")
        if love.math.random()*5 < love.timer.getAverageDelta() then
            self.mainCat.state = "reeling"
        end

    elseif self.mainCat.state == "reeling" then
        drawReelMeter(self)
    end


    local function catch()
        local accuracy, rarity = error("todo calculate")

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
    end

    -- Debug
    local w, h = ui.getScaledUIDimensions()
    local f = g.getSmallFont(16)
end



function fishing:draw()
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

function fishing:mousepressed(mx,my,button)
    if self.mainCat.state == "reeling" and button == 1 then
        print("catch fish!!!")
        self.mainCat:reset()
    end
end

fishing.keyreleased = fishing.defaultKeyreleased

return fishing
