local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")



local COSMETIC_TILE_SIZE = 48
local COSMETIC_PADDING = 4
local COSMETIC_COLUMNS = 4

local CATEGORY_SIZE = 40
local CATEGORY_DIVIDER = 8


local CATEGORIES = {
    {"All", "cosmetic_category_all"},
    {"Cats", "cosmetic_category_cats"},
    {"Backgrounds", "cosmetic_category_backgrounds"},
    {"Hats", "cosmetic_category_hats"}
}
local CATEGORY_COLOR = {
    -- boolean is if the category is active
    -- 1st value is the area color, 2nd value is the icon color
    [true] = {objects.Color.WHITE, objects.Color("#".."FF797568")},
    [false] = {objects.Color.TRANSPARENT, objects.Color.WHITE}
}


---@class CustomizationScene: FreeCameraScene
local custom = FreeCameraScene()


function custom:init()
    self.allowMousePan = false
    self.background = helper.newGradientMesh(
        "vertical",
        objects.Color("#".."FF090372"),
        objects.Color("#".."FF2B6CB6")
    )
    self.activeCategory = 2
end



function custom:_drawUI()
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())

    -- Draw categories
    local categoryBaseR = Kirigami(0, 0, CATEGORY_SIZE, CATEGORY_SIZE)
        :attachToTopOf(r)
        :attachToRightOf(r)
        :moveRatio(-1, 1)
        :moveUnit(-8, 64)
    -- The one above will be used for name placement, so have separate variable for actual category loop
    local categoryR = categoryBaseR

    for i, v in ipairs(CATEGORIES) do
        local color = CATEGORY_COLOR[i == self.activeCategory]

        -- Draw category
        -- For now, use rounded rectangle.
        -- TODO: Use proper assets
        local cx, cy, cw, ch = categoryR:get()
        love.graphics.setColor(color[1])
        love.graphics.rectangle("fill", cx, cy, cw, ch, 8, 8)
        -- Draw icon
        love.graphics.setColor(color[2])
        local s = math.floor(CATEGORY_SIZE / 16)
        g.drawImage(v[2], cx + cw / 2, cy + ch / 2, 0, s, s)
        -- Draw hover outline
        if iml.isHovered(cx, cy, cw, ch) then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", cx, cy, cw, ch, 8, 8)
            -- TODO: Draw tooltip, probably
        end

        if iml.wasJustClicked(cx, cy, cw, ch) then
            self.activeCategory = i
        end

        if i < #CATEGORIES then
            -- Draw divider
            local y = cy + ch + CATEGORY_DIVIDER / 2
            love.graphics.setColor(1, 1, 1)
            love.graphics.line(cx, y, cx + cw, y)
        end
        categoryR = categoryR:moveRatio(0, 1):moveUnit(0, CATEGORY_DIVIDER)
    end
end



---@param dt number
function custom:update(dt)
    g.getHUD():update(dt)
end

function custom:draw()
    local w, h = love.graphics.getDimensions()

    -- Draw background
    love.graphics.draw(self.background, 0, 0, 0, w, h)

    -- Draw vignette
    vignette.draw()

    -- Draw UI
    ui.startUI()
    self:renderMapButton()
    self:_drawUI()
    g.getHUD():draw({profile = false, xpbar = false})
    ui.endUI()
end

return custom
