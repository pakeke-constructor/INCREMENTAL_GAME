---@class _title.InteractiveCat: objects.Class
local InteractiveCat = objects.Class("title:InteractiveCat")

local RANDOM_TEXT = {
    loc"Meow!",
    loc"Woof, Wo- oh wait.",
    loc"Join our cat Discord server below!",
    loc"Wishlist our game on Steam!", -- TODO: Remove once we release the game
    loc"PAT PAT PAT",
    loc("CAT "..("CAT"):rep(10, " ")),
    loc"{fish} FISH! {fish} FISH! {fish}",
}
local CAT_IMAGE = "happy_cat"
local CAT_SIZE = 64
local JUMP_DURATION = 0.4
local JUMP_HEIGHT = 64
local SQUISH_DURATION = 0.3


---f(0) = 0; f(1) = 0; f(0.5) = 1;
---@param x number
local function quadraticJump(x)
    return 4 * (x - x * x)
end

---@param flip boolean
function InteractiveCat:init(flip)
    self.flip = not not flip
    self.text = ""
    self.textDisplayDuration = 0.
    self.jumpDuration = 0.
    self.squishDuration = 0.

    self.drawFunc = function(x, y, w, h)
        local oy = JUMP_HEIGHT * quadraticJump(self.jumpDuration / JUMP_DURATION)
        local sy = (1 - self.squishDuration / SQUISH_DURATION * 0.3)
        local _, _, iw, ih = g.getImageQuad(CAT_IMAGE):getViewport()
        g.drawImageOffset(CAT_IMAGE, x, y - oy, 0, w / iw, sy * h / ih, 0, 0)
    end
end

if false then
    ---@param flip boolean
    ---@return _title.InteractiveCat
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function InteractiveCat(flip) end
end

function InteractiveCat:_onClick()
    self.squishDuration = 0
    self.jumpDuration = 0

    -- Cat is clicked. Pick either from jumping or squish
    -- TODO: Play meow SFX
    if love.math.random() >= 0.5 then
        -- Squish
        self.squishDuration = SQUISH_DURATION
        self.text = helper.randomChoice(RANDOM_TEXT)
        self.textDisplayDuration = 1
    else
        -- Jump
        self.jumpDuration = JUMP_DURATION
    end
end

---@param dt number
function InteractiveCat:update(dt)
    self.textDisplayDuration = math.max(self.textDisplayDuration - dt, 0)
    self.jumpDuration = math.max(self.jumpDuration - dt, 0)
    self.squishDuration = math.max(self.squishDuration - dt, 0)
end

---@param r kirigami.Region
function InteractiveCat:draw(r)
    -- Setup region
    local catR = Kirigami(0, 0, CAT_SIZE, CAT_SIZE)
        :center(r)

    -- Draw cat
    love.graphics.setColor(1, 1, 1)
    do
        local offy = JUMP_HEIGHT * quadraticJump(self.jumpDuration / JUMP_DURATION)
        local sy = (1 - quadraticJump(self.squishDuration / SQUISH_DURATION) * 0.3)
        local sx = self.flip and -1 or 1
        local _, _, iw, ih = g.getImageQuad(CAT_IMAGE):getViewport()
        g.drawImageOffset(CAT_IMAGE, catR.x + catR.w / 2, catR.y + catR.h - offy, 0, sx * catR.w / iw, sy * catR.h / ih, 0.5, 1)
    end

    if iml.wasJustClicked(catR:get()) then
        self:_onClick()
    end

    if self.textDisplayDuration > 0 then
        local font = g.getSmallFont(16)
        local textR = Kirigami(0, 0, CAT_SIZE * 2, font:getHeight() * 2)
            :centerX(catR)
            :attachToTopOf(catR)
        richtext.printRich("{o}"..self.text.."{/o}", font, textR.x, textR.y, textR.w, "center")
    end
end

return InteractiveCat
