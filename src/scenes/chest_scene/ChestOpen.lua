local cosmetics = require("src.cosmetics.cosmetics")

local lg = love.graphics

local REEL_SIZE = 60
local REEL_DURATION = 3.0 -- seconds

local RAY_COLOR = objects.Color("#".."FFEFC52C")

--- Ease-out cubic: fast start, decelerates to stop.
--- Returns index [1, reelSize] based on elapsed time.
local function getReelIndex(elapsed, reelSize)
    local t = math.min(elapsed / REEL_DURATION, 1)
    local curve = 1 - (1 - t)^3
    return math.floor(1 + curve * (reelSize - 1) + 0.5)
end

local function buildReel(resultCosmetic)
    local all = cosmetics.getAll()
    local reel = {}
    for i = 1, REEL_SIZE - 1 do
        reel[i] = all[love.math.random(#all)]
    end
    reel[REEL_SIZE] = resultCosmetic
    return reel
end


---@class ChestOpen: objects.Class
---@field startTime number
---@field reel string[]
---@field cosmetic string the final cosmetic ID
---@field done boolean true when click-to-close
local ChestOpen = objects.Class("chest_scene:ChestOpen")

---@param cosmeticId string the won cosmetic
function ChestOpen:init(cosmeticId)
    self.startTime = love.timer.getTime()
    self.reel = buildReel(cosmeticId)
    self.cosmetic = cosmeticId
    self.done = false
end

--- Returns true when the player has dismissed the popup.
function ChestOpen:isDone()
    return self.done
end

function ChestOpen:draw()
    local elapsed = love.timer.getTime() - self.startTime
    local reelIndex = getReelIndex(elapsed, #self.reel)
    local settled = reelIndex >= #self.reel

    local r = ui.getFullScreenRegion()

    -- Click to close
    if iml.wasJustPressed(r:get()) and settled then
        self.done = true
        return
    end

    -- Darken background
    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", r:get())

    local rx, ry = r:getCenter()
    local currentId = self.reel[reelIndex]
    local info = g.getCosmeticInfo(currentId)

    if settled then
        -- TODO: draw godrays
        -- TODO: draw final cosmetic image
        -- TODO: draw cosmetic name
        -- TODO: draw "Click anywhere to close"
    else
        -- TODO: draw flashing cosmetic image
        -- TODO: draw cosmetic name below
    end
end

return ChestOpen
