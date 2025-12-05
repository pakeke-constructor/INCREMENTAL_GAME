---@class _title.InteractiveCat: objects.Class
local InteractiveCat = objects.Class("title:InteractiveCat")

local RANDOM_TEXT = {
    loc"Meow",
    loc"Meow, Meow",
    loc"Meow Meow.",
}

local CAT_IMAGE = "happy_cat"
local CAT_SIZE = 64
local JUMP_DURATION = 0.4
local JUMP_HEIGHT = 48
local SQUISH_DURATION = 0.3
local RANDOM_ACTION_DURATION = {3, 10}


---f(0) = 0; f(1) = 0; f(0.5) = 1;
---@param x number
local function quadraticJump(x)
    return 4 * (x - x * x)
end


---@alias _title.InteractiveCat.Args {flip: boolean?, image:string?}

---@param args _title.InteractiveCat.Args
function InteractiveCat:init(args)
    self.flip = not not args.flip
    self.image = args.image
    if not args.image then
        self.image = "happy_cat"
    end
    assert(g.getImageQuad(self.image))
    self.text = ""
    self.textDisplayDuration = 0.
    self.jumpDuration = 0.
    self.squishDuration = 0.
    self.nextRandomAction = helper.lerp(RANDOM_ACTION_DURATION[1], RANDOM_ACTION_DURATION[2], love.math.random())
end

if false then
    ---@param args _title.InteractiveCat.Args
    ---@return _title.InteractiveCat
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function InteractiveCat(args) end
end

function InteractiveCat:_onClick()
    self.squishDuration = 0
    self.jumpDuration = 0
    self.nextRandomAction = helper.lerp(RANDOM_ACTION_DURATION[1], RANDOM_ACTION_DURATION[2], love.math.random())

    -- Cat is clicked. Pick either from jumping or squish
    -- TODO: Play meow SFX
    if love.math.random() >= 0.5 then
        -- Squish
        self.squishDuration = SQUISH_DURATION
    else
        -- Jump
        self.jumpDuration = JUMP_DURATION
    end

    self.text = helper.randomChoice(RANDOM_TEXT)
    self.textDisplayDuration = 2
end

---@param dt number
function InteractiveCat:update(dt)
    self.textDisplayDuration = math.max(self.textDisplayDuration - dt, 0)
    self.jumpDuration = math.max(self.jumpDuration - dt, 0)
    self.squishDuration = math.max(self.squishDuration - dt, 0)
    self.nextRandomAction = self.nextRandomAction - dt

    if self.nextRandomAction <= 0 then
        self:_onClick()
    end
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
        local rot = math.sin(love.timer.getTime()/2) / 8
        g.drawImageOffset(CAT_IMAGE, catR.x + catR.w / 2, catR.y + catR.h - offy, rot, sx * catR.w / iw, sy * catR.h / ih, 0.5, 1)
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
