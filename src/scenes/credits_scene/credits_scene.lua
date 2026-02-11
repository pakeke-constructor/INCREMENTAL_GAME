local FreeCameraScene = require("src.scenes.FreeCameraScene")
local titleBackground = require("src.scenes.titleBackground")

---@class CreditsScene: FreeCameraScene
local credits = FreeCameraScene()

local creditsctx = {context = "Text shown during in-game credits roll"}

---Need to change how the credits should look like? Change it here!
---Size defaults to 32, underline defaults to false. image takes precedence over [1].
---Empty table means vertical spacing/newline.
---@type {[1]:string?,size:integer?,image:string?,underline:boolean?,font?:"small"|"big"}[]
local CREDITS_STRING = {
    {image="src/scenes/credits_scene/catx11.png"},
    {"CAT CAT CAT CAT CAT CAT CAT CAT CAT CAT CAT", size=48},
    {},
    {},
    {loc("Developed By", nil, creditsctx), size=48, underline=true},
    {"CodeTheory Ltd."},
    {},
    {},
    {loc("Lead Programmer", nil, creditsctx), size=48, underline=true},
    {"Oli"},
    {"Miku AuahDark"},
    {},
    {},
    {loc("Image Artist", nil, creditsctx), size=48, underline=true},
    {"Leo"},
    {},
    {},
    {loc("Music Artist", nil, creditsctx), size=48, underline=true},
    {"Miguel Angel"},
    {},
    {},
    {},
    {},
    {},
    {},
    {loc("Thank you for playing!", nil, creditsctx), size=48},
}
local BACK_MAIN_MENU = "{o}"..loc("Click/tap anywhere to back to main menu", nil, creditsctx).."{/o}"
local CREDITS_MAX_WIDTH = 500
local SCROLL_SPEED = 32 -- pixels per second

function credits:init()
    -- Build credits drawing code.
    ---@type (fun(ox:number,oy:number))[]
    self.drawFuncs = {}
    self.creditsHeight = 0
    for _, v in ipairs(CREDITS_STRING) do
        if v.image then
            local image = love.graphics.newImage(v.image)
            local y = self.creditsHeight
            local w, h = image:getDimensions()
            self.creditsHeight = self.creditsHeight + h

            ---@param ox number
            ---@param oy number
            local function drawImage(ox, oy)
                love.graphics.draw(image, CREDITS_MAX_WIDTH / 2 + ox, y + oy, 0, 1, 1, w / 2, 0)
            end
            self.drawFuncs[#self.drawFuncs+1] = drawImage
        else
            local parsed = richtext.parseRichText("{o thickness=2}"..(v[1] or "").."{/o}")
            local fonttype = v.font or "small"
            local font
            if fonttype == "small" then
                font = g.getSmallFont(v.size or 32)
            elseif fonttype == "big" then
                font = g.getBigFont(v.size or 32)
            else
                return error("invalid font type credits")
            end

            local y = self.creditsHeight
            local w, lines = richtext.getWrap(parsed, font, CREDITS_MAX_WIDTH)
            local fh = font:getHeight()
            local lx = (CREDITS_MAX_WIDTH - w) / 2
            local h = fh * math.max(lines, 1)
            self.creditsHeight = self.creditsHeight + h

            ---@param ox number
            ---@param oy number
            local function drawText(ox, oy)
                richtext.printRich(parsed, font, ox, y + oy, CREDITS_MAX_WIDTH, "center")

                if v.underline then
                    local lw = love.graphics.getLineWidth()
                    local r, g, b, a = love.graphics.getColor()
                    love.graphics.setColor(0, 0, 0, a)
                    love.graphics.setLineWidth(8)
                    love.graphics.line(ox + lx, y + oy + h, ox + lx + w, y + oy + h)
                    love.graphics.setColor(r, g, b, a)
                    love.graphics.setLineWidth(4)
                    love.graphics.line(ox + lx, y + oy + h, ox + lx + w, y + oy + h)
                    love.graphics.setLineWidth(lw)
                end
            end
            self.drawFuncs[#self.drawFuncs+1] = drawText
        end
    end
    -- Needs to start somewhere positive, then scroll up to negative
    self.creditsYOffset = 480
    self.creditsFinished = false
end

function credits:enter()
    self.creditsYOffset = select(2, ui.getScaledUIDimensions()) + 32
    self.creditsFinished = false
end

---@param dt number
function credits:update(dt)
    titleBackground.update(dt)

    local maxScroll = -self.creditsHeight + select(2, ui.getScaledUIDimensions()) / 2 + 32
    self.creditsYOffset = math.max(self.creditsYOffset - SCROLL_SPEED * dt, maxScroll)
    self.creditsFinished = self.creditsYOffset <= maxScroll
end

function credits:draw()
    ui.startUI()

    titleBackground.draw()
    love.graphics.setColor(1, 1, 1)
    local width, height = ui.getScaledUIDimensions()
    local ox = (width - CREDITS_MAX_WIDTH) / 2
    for _, f in ipairs(self.drawFuncs) do
        f(ox, self.creditsYOffset)
    end

    if self.creditsFinished then
        richtext.printRich(BACK_MAIN_MENU, g.getSmallFont(16), 0, height / 2 + 48, width, "center")

        if iml.wasJustClicked(ui.getFullScreenRegion():get()) then
            g.gotoScene("title_scene")
        end
    end

    ui.endUI()
end

return credits
