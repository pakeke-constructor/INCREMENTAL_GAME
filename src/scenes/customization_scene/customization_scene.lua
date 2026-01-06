local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")



local COSMETIC_TILE_SIZE = 48
local COSMETIC_PADDING = 4
local COSMETIC_COLUMNS = 4
local COSMETIC_ROWS = 5

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

local SCROLLBAR_BACKGROUND = objects.Color("#".."40FFFFFF")
local SCROLLBAR_COLOR = objects.Color("#".."90C9DE75")

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
    self.rowOffset = 0
    self.scrollbarClicked = false
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

---@param mapButtonR kirigami.Region
function custom:_drawUI(mapButtonR)
    local r = ui.getScreenRegion()

    -- Compute right center cosmetic category.
    local categoryHeight = (CATEGORY_SIZE + CATEGORY_DIVIDER) * #CATEGORIES - CATEGORY_DIVIDER
    local allCategoryR = Kirigami(0, 0, CATEGORY_SIZE, categoryHeight)
        :attachToRightOf(r)
        :centerY(r)
        :moveRatio(-1, 0)
        :moveUnit(-8, 0)
    local categoryR = Kirigami(0, 0, CATEGORY_SIZE, CATEGORY_SIZE)
        :attachToTopOf(allCategoryR)
        :attachToLeftOf(allCategoryR)
        :moveRatio(1, 1)

    -- Draw categories
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

    -- Prepare scrollbar
    local cellSize = COSMETIC_TILE_SIZE + COSMETIC_PADDING
    local scrollbarHeight = cellSize * COSMETIC_ROWS
    local scrollbarR = Kirigami(0, 0, 16, scrollbarHeight)
        :attachToLeftOf(categoryR)
        -- Take the map button into account
        :centerY(r:padUnit(0, mapButtonR.y + mapButtonR.h, 0, 0))
        :moveUnit(-8, 0)
    scrollbarR.x = math.floor(scrollbarR.x)
    scrollbarR.y = math.floor(scrollbarR.y)

    -- Prepare cosmetic cell
    local categoryfilter = filters[self.activeCategory]
    local baseCosmeticGridR = Kirigami(0, 0, cellSize * COSMETIC_COLUMNS, scrollbarHeight)
        :attachToLeftOf(scrollbarR)
        :centerY(scrollbarR)
        :moveUnit(-8, 0)
    local cosmeticGrid = baseCosmeticGridR:grid(COSMETIC_COLUMNS, COSMETIC_ROWS)

    -- Get cosmetic infos of unlocked cosmetics, possibly in the current category
    -- We need to do it in 2-pass to be able to show scrollbar.
    ---@type g.CosmeticInfo[]
    local cosmetics = {}
    for _, v in ipairs(g.getUnlockedCosmetics()) do
        local cinfo = g.getCosmeticInfo(v)
        if categoryfilter(cinfo) then
            cosmetics[#cosmetics+1] = cinfo
        end
    end
    -- Draw scrollbar background
    love.graphics.setColor(SCROLLBAR_BACKGROUND)
    love.graphics.rectangle("fill", scrollbarR:padUnit(-1):get())
    -- Draw slider
    local scrollCount = math.max(math.ceil(#cosmetics / COSMETIC_COLUMNS) - COSMETIC_ROWS, 0) + 1
    self.rowOffset = ui.Slider(
        "custom:accessorySlider",
        "vertical",
        SCROLLBAR_COLOR,
        self.rowOffset + 1,
        scrollCount,
        math.max(1 / scrollCount, 0.1),
        scrollbarR
    ) - 1


    -- Draw cosmetic cell
    -- TODO: Scrollbar or a way to display more cosmetics later.
    for i = 1, #cosmeticGrid do
        local cinfo = cosmetics[i + self.rowOffset * COSMETIC_COLUMNS]
        if not cinfo then break end

        local cellR = cosmeticGrid[i]
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
        local scale = cinfo.type == "BACKGROUND" and 1 or 2
        love.graphics.setColor(cinfo.color)
        assert(#cinfo.image > 0, cinfo.id)
        g.drawImage(cinfo.image, cx, cy, 0, scale * cinfo.upscale)

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
    end

    -- Prepare text layout for the cosmetic name
    local cosmeticNameR = Kirigami(0, 0, 0, 32)
        :attachToTopOf(baseCosmeticGridR)
        :attachToRightOf(baseCosmeticGridR)
        :moveUnit(0, -4)

    -- Draw category name and the selected cosmetic
    local textDisplay = "{o}"..CATEGORIES[self.activeCategory][1].."{/o}"
    if self.activeCategory > 1 then -- "all" category doesn't make sense to have this
        local cosmeticid = getWornCosmeticId(self.activeCategory)

        if cosmeticid then
            local cinfo = g.getCosmeticInfo(cosmeticid)
            -- Why this {o} tag abomination? to make the outline in effect with the wavy
            local coloredCosmeticName = helper.wrapRichtextColor(SELECTED_COLOR[cinfo.type], "{w}{o}"..cinfo.name.."{/o}{/w}")
            textDisplay = textDisplay.."{o} - {/o}"..coloredCosmeticName
        end
    end
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(
        textDisplay,
        g.getSmallFont(32),
        cosmeticNameR.x - 1000,
        cosmeticNameR.y,
        1000, "right"
    )

    -- Draw avatar with background
    local drawBg = self.activeCategory == 1 or self.activeCategory == 3
    local safeArea = g.getHUD():getSafeArea()
    local avatarX = helper.lerp(safeArea.x, baseCosmeticGridR.x, 0.5)
    local avatarY = math.floor(select(2, ui.getScaledUIDimensions()) / 2)
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
    local mapButtonR = self:renderMapButton()
    self:_drawUI(mapButtonR)
    g.getHUD():draw({profile = false, xpbar = false})
    self:renderPause()
    ui.endUI()
end

function custom:wheelmoved(dx, dy)
    local dir = helper.sign(dy)
    self.rowOffset = self.rowOffset - dir
end

function custom:keyreleased(k)
    if k == "escape" then
        local s = g.getSn()
        s.paused = not s.paused
    end
end

return custom
