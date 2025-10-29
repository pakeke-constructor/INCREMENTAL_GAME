

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")
local FishingWorld = require(".fishing_world")
local FisherCat = require(".FisherCat")

---@class FishingScene: FreeCameraScene
local fishing = FreeCameraScene()

local lg = love.graphics



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
    local x,y = helper.randomInRegion(self.world:getWharfArea():get())
    self.mainCat = FisherCat(x,y)
    self.world.mainFishercat = self.mainCat

    self.timeSinceCatch = 0xfffffff

    self.reelPos = 0 -- between 0 and 1
end


local CATCH_SPEED = 0.5

local function triangleWave(t, freq)
  local phase = (t * freq) % 1
  return (1 - 4 * math.abs(phase - 0.5))
end


---@param dt number
function fishing:update(dt)
    self.world:update(dt)

    self.timeSinceCatch = self.timeSinceCatch + dt
    self.reelPos = triangleWave(love.timer.getTime(), CATCH_SPEED)
end




local SPINNING_FISH = lg.newImage("src/scenes/fishing_scene/spinning_orange_fish.png")

---@param self FishingScene
local function drawReelMeter(self)
    local r,_ = Kirigami(0,0,ui.getScaledUIDimensions())
    _,r = r:splitVertical(3,2)
    _,r = r:splitHorizontal(1,2)
    r = r:padRatio(0.3,0.7,0.4,0.7)

    local x, y, w, h = r:get()
    local xsize = w / 2

    -- Draw catch ranges
    -- Note: The defined spacing is from lowest to highest. We want to render from highest to lowest.
    for i = #SPACING, 1, -1 do
        local index = (#SPACING - i) / (#SPACING - 1)
        local rc, gc, bc = objects.Color.HSLtoRGB(helper.lerp(22, 90, index), 1, 0.6)

        lg.setColor(rc, gc, bc)
        local x1 = x + xsize * (1 - SPACING[i].window)
        local w1 = 2 * xsize * SPACING[i].window
        lg.rectangle("fill", x1,y, w1,h)

        if i ~= #SPACING then
            local GAP = 4
            local lw = lg.getLineWidth()
            lg.setLineWidth(2)
            lg.line(x1-GAP,y, x1-GAP,y+h)
            lg.line(x1-GAP*2,y, x1-GAP*2,y+h)
            lg.line(x1+w1+GAP,y, x1+w1+GAP,y+h)
            lg.line(x1+w1+GAP*2,y, x1+w1+GAP*2,y+h)
            lg.setLineWidth(lw)
        end
    end

    -- Draw reel catch position
    local linepos = self.reelPos * w/2
    lg.setColor(0, 0, 0)
    local lw = lg.getLineWidth()
    lg.setLineWidth(4)
    local reelX = x + w/2 + linepos
    lg.line(reelX, y, reelX, y + h)

    -- Draw outline
    lg.setColor(0, 0, 0)
    lg.rectangle("line", x, y, w, h)
    lg.setLineWidth(lw)

    -- draw a pair of funny fishies
    do
    lg.push()
    lg.setColor(1,1,1)
    local SC=2
    local t = love.timer.getTime() * 8
    local ww,hh = SPINNING_FISH:getDimensions()
    lg.draw(SPINNING_FISH, reelX,y, t, SC,SC, ww/2,hh/2)
    lg.draw(SPINNING_FISH, reelX,y+h, -t, SC,SC, ww/2,hh/2)
    lg.pop()
    end
end



local CAST_ROD = loc("{o}{c r=0.7 g=0.8 b=1}Fish!{/c}{/o}")
local WAITING_FOR_FISH = loc("{o}{c r=0.7 g=0.8 b=1}Waiting for fishy...{/c}{/o}")
local CAUGHT_FISH = loc("{o}{c r=0.7 g=0.8 b=1}CAUGHT!{/c}{/o}")

local HIRE_FISHERCAT = loc("{o}{c r=0.7 g=0.8 b=1}Hire fishercat!{/c}{/o}")
local UPGRADE_ROD = loc("{o}{c r=0.7 g=0.8 b=1}Upgrade Rod!{/c}{/o}")


local function getFisherCatPrice()
    local sn = g.getSn()
    local t = sn.fisherCatCount
    return 2000 + 2*t
end


local function getFishingRodUpgradePrice()
    local sn = g.getSn()
    local t = sn.fishingRodLevel
    return 500 + 3*t
end




function fishing:drawUI()

    local buttonR, castR, upgradeRodR, hireFishercatR
    do
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())
    local r2,_
    _,r2 = r:splitVertical(1,2)
    _,r2 = r2:splitHorizontal(1,1)

    buttonR = r2
        :attachToBottomOf(r)
        :attachToRightOf(r)
        :moveRatio(-1,-1)
        :padRatio(0.1)

    local top, bot = buttonR:splitVertical(1,1)
    local left,right = bot:splitHorizontal(1,1)

    castR = top:padRatio(0.5,0,0.5,0):padRatio(0.15)
    upgradeRodR = left:padRatio(0.4)
    hireFishercatR = right:padRatio(0.4)
    end

    local W1,W2 = objects.Color.WHITE, objects.Color({0.76,0.78,0.82})

    if self.timeSinceCatch < 0.45 then
        lg.setColor(1,1,1)
        richtext.printRichContained(CAUGHT_FISH, g.getSmallFont(16), buttonR:get())

    elseif self.mainCat.state == "idle" then
        if ui.Button(CAST_ROD, W1,W2, castR:get()) then
            local cx,cy = helper.randomInRegion(self.world.castArea:get())
            self.mainCat:cast(cx,cy)
        end

        local font = g.getSmallFont(16)
        local function upgradeWidget(mainText, price, level, maxLevel, x,y,w,h)
            local r = Kirigami(x,y,w,h)
            local top,bot = r:splitVertical(1,1)
            richtext.printRichContained(mainText, font, top:padRatio(0.1):get())
            if level < maxLevel then
                local botleft,botright = bot:splitHorizontal(1,1)
                richtext.printRichContained("{wavy}{o}{MONEY}$" .. tostring(price), font, botleft:padRatio(0.15):get())
                richtext.printRichContained("{c r=0.6 g=0.7 b=0.75}" .. tostring(level) .. "/" .. tostring(maxLevel), font, botright:padRatio(0.15):get())
            else
                richtext.printRichContained("{o}{c r=0.2 g=0.8 b=0.3}" .. tostring(maxLevel).."/"..tostring(maxLevel), font, bot:padRatio(0.15):get())
            end
        end

        local sn = g.getSn()
        local MAX_FISHERCATS = self.world.MAX_FISHERCATS
        local MAX_ROD_LEVEL = self.world.MAX_ROD_LEVEL

        do
        local price = getFisherCatPrice()
        local function hireFisherCat(x,y,w,h)
            upgradeWidget(HIRE_FISHERCAT, price, sn.fisherCatCount,MAX_FISHERCATS, x,y,w,h)
        end
        if ui.CustomButton(hireFisherCat, W1,W2, hireFishercatR:get()) then
            if g.trySubtractResources({money = price}) then
                sn.fisherCatCount = math.min(sn.fisherCatCount + 1, MAX_FISHERCATS)
            end
        end
        end

        do
        local price = getFishingRodUpgradePrice()
        local function upgradeRod(x,y,w,h)
            upgradeWidget(UPGRADE_ROD, 1000, sn.fishingRodLevel,self.world.MAX_ROD_LEVEL, x,y,w,h)
        end
        if ui.CustomButton(upgradeRod, W1,W2, upgradeRodR:get()) then
            if g.trySubtractResources({money = price}) then
                sn.fishingRodLevel = math.min(sn.fishingRodLevel + 1, MAX_ROD_LEVEL)
            end
        end
        end

    elseif self.mainCat.state == "fishing" then
        lg.setColor(1,1,1)
        richtext.printRichContained(WAITING_FOR_FISH, g.getSmallFont(16), buttonR:moveUnit(0,4*math.sin(love.timer.getTime()*10)):get())
        if (self.mainCat:getTimeSinceCast() > 4) and (love.math.random()*3 < love.timer.getAverageDelta()) then
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
        
    end

    -- Debug
    local w, h = ui.getScaledUIDimensions()
    local f = g.getSmallFont(16)
end



function fishing:draw()
    lg.clear(0.4,0.5,0.9)
    lg.setColor(1,1,1)

    self.camera:focusOnArea(self.world.worldArea, g.getHUD():getSafeArea())
    self:setCamera()

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
        -- Player catches fish!
        self.timeSinceCatch = 0
        local accuracy = math.abs(self.reelPos)
        local rarity
        for _, spc in ipairs(SPACING) do
            if accuracy <= spc.window then
                rarity = spc.rarity()
                break
            end
        end

        self.mainCat:catch(rarity)
        self.mainCat:reset()
    end
end

fishing.keyreleased = fishing.defaultKeyreleased

return fishing
