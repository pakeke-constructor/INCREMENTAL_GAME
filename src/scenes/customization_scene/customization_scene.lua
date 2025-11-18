local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")



local COSMETIC_TILE_SIZE = 48
local COSMETIC_PADDING = 4
local COSMETIC_COLUMNS = 4

local CATEGORY_SIZE = 40
local CATEGORY_DIVIDER = 8

local AVATAR_SCALE = 8


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
local SELECTED_COLOR = {
    AVATAR = objects.Color("#".."FFDEBAE7"),
    BACKGROUND = objects.Color("#".."FFB1D8EA"),
    HAT = objects.Color("#".."FFEAB5B1"),
}

---@param categoryId integer
local function getWornCosmeticId(categoryId)
    local s = g.getSn()

    if categoryId == 2 then
        return s.avatar.avatar
    elseif categoryId == 3 then
        return s.avatar.background
    elseif categoryId == 4 then
        return s.avatar.hat
    end

    return nil
end


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


---@param cinfo g.CosmeticInfo
local function isCosmeticSelected(cinfo)
    local s = g.getSn()

    if cinfo.type == "AVATAR" then
        return s.avatar.avatar == cinfo.id
    elseif cinfo.type == "BACKGROUND" then
        return s.avatar.background == cinfo.id
    elseif cinfo.type == "HAT" then
        return s.avatar.hat == cinfo.id
    end
end

---@type (fun(cinfo:g.CosmeticInfo):boolean)[]
local filters = {
    function(cinfo) return true end, -- All
    function(cinfo) return cinfo.type == "AVATAR" end, -- Cats
    function(cinfo) return cinfo.type == "BACKGROUND" end, -- Backgrounds
    function(cinfo) return cinfo.type == "HAT" end, -- Hats
}

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

    -- Prepare text layout for the cosmetic name
    local cosmeticNameR = Kirigami(0, 0, 32, 32)
        :attachToLeftOf(categoryBaseR)
        :attachToTopOf(categoryBaseR)
        :moveRatio(0, 1)
        :moveUnit(-8, 0)

    -- Prepare cosmetic cell
    local categoryfilter = filters[self.activeCategory]
    local cellSize = COSMETIC_TILE_SIZE + COSMETIC_PADDING
    local cellR = Kirigami(0, 0, cellSize, cellSize)
        :attachToRightOf(cosmeticNameR)
        :attachToBottomOf(cosmeticNameR)
        :moveRatio(-COSMETIC_COLUMNS, 0)
        :moveUnit(0, 8)
    local cellBaseR = cellR -- for centering the profile HUD display later

    -- Draw cosmetic cell by category
    -- TODO: Scrollbar or a way to display more cosmetics later.
    local column = 0
    for _, v in ipairs(g.getUnlockedCosmetics()) do
        local cinfo = g.getCosmeticInfo(v)
        if categoryfilter(cinfo) then
            column = column + 1

            local clickableR = cellR:padUnit(COSMETIC_PADDING)
            local selected = isCosmeticSelected(cinfo)

            -- Draw  background
            local alpha = selected and 1 or 0.1
            love.graphics.setColor(helper.multiplyAlpha(SELECTED_COLOR[cinfo.type], alpha))
            love.graphics.rectangle("fill", clickableR:get())

            if iml.isHovered(clickableR:get()) then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", cellR:get())
            end

            local cx, cy = cellR:getCenter()
            local s = cinfo.type == "BACKGROUND" and 1 or 2
            love.graphics.setColor(cinfo.color)
            assert(#cinfo.image > 0, cinfo.id)
            g.drawImage(cinfo.image, cx, cy, 0, s * cinfo.upscale)

            if iml.wasJustClicked(clickableR:get()) then
                local s = g.getSn()
                -- Select this avatar
                if cinfo.type == "AVATAR" then
                    s.avatar.avatar = cinfo.id
                elseif cinfo.type == "BACKGROUND" then
                    s.avatar.background = cinfo.id
                elseif cinfo.type == "HAT" then
                    if selected then
                        s.avatar.hat = nil
                    else
                        s.avatar.hat = cinfo.id
                    end
                end
            end

            -- Advance next cell
            cellR = cellR:moveRatio(1, 0)
            if column >= COSMETIC_COLUMNS then
                column = 0
                cellR = cellR:moveRatio(-4, 1)
            end
        end
    end

    -- Draw category name and the selected cosmetic
    local textDisplay = "{o}"..CATEGORIES[self.activeCategory][1].."{/o}"
    if self.activeCategory > 1 then -- "all" category doesn't make sense to have this
        local cosmeticid = getWornCosmeticId(self.activeCategory)

        if cosmeticid then
            local cinfo = g.getCosmeticInfo(cosmeticid)
            textDisplay = helper.wrapRichtextColor(
                SELECTED_COLOR[cinfo.type],
                -- Why this? to make the outline in effect with the wavy
                textDisplay.."{o} - {/o}{w}{o}"..cinfo.name.."{/o}{/w}"
            )
        end
    end
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(
        textDisplay,
        g.getSmallFont(32),
        cosmeticNameR.x + cosmeticNameR.w - 1000,
        cosmeticNameR.y,
        1000, "right"
    )

    -- Draw avatar with background
    local drawBg = self.activeCategory == 1 or self.activeCategory == 3
    local avatarX, avatarY = math.floor(cellBaseR.x / 2), math.floor(select(2, ui.getScaledUIDimensions()) / 2)
    local avatarSize = consts.AVATAR_SIZE * AVATAR_SCALE
    if drawBg then
        love.graphics.setStencilMode("draw", 3)
        love.graphics.rectangle("fill", avatarX - avatarSize / 2, avatarY - avatarSize / 2, avatarSize, avatarSize)
        love.graphics.setStencilMode("test", 3)
    end
    g.drawPlayerAvatar(avatarX, avatarY, AVATAR_SCALE, drawBg)
    if drawBg then
        love.graphics.setStencilMode()
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", avatarX - avatarSize / 2, avatarY - avatarSize / 2, avatarSize, avatarSize)
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
