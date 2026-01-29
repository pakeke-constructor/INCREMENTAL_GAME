
local FreeCameraScene = require("src.scenes.FreeCameraScene")

local vignette = require("src.modules.vignette.vignette")

local CustomSelect = require(".CustomSelect")




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

    self.bgSelect = CustomSelect(g.getUnlockedCosmetics("BACKGROUND"), function (item, reg)
        local cinfo = g.getCosmeticInfo(item)
        g.drawImageContained(cinfo.image, reg:get())
    end)
    self.hatSelect = CustomSelect(g.getUnlockedCosmetics("HAT"), function (item, reg)
        local cinfo = g.getCosmeticInfo(item)
        g.drawImageContained(cinfo.image, reg:get())
    end)
    self.catSelect = CustomSelect(g.getUnlockedCosmetics("AVATAR"), function (item, reg)
        local cinfo = g.getCosmeticInfo(item)
        g.drawImageContained(cinfo.image, reg:get())
    end)
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

    local top,bot = r:splitVertical(3,2)
    local a,b,c = bot:splitHorizontal(3, 7, 2)

    -- Draw avatar with background
    local avatarSize = consts.AVATAR_SIZE * AVATAR_SCALE
    local avatarX, avatarY = a:getCenter()
    love.graphics.setStencilMode("draw", 3)
    love.graphics.rectangle("fill", avatarX - avatarSize / 2, avatarY - avatarSize / 2, avatarSize, avatarSize)
    love.graphics.setStencilMode("test", 3)
    g.drawPlayerAvatar(avatarX, avatarY, AVATAR_SCALE, true)
    love.graphics.setStencilMode()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", avatarX - avatarSize / 2, avatarY - avatarSize / 2, avatarSize, avatarSize)

    local hat, cat, bg = b:padRatio(0.1):splitVertical(1,1,1)
    self.hatSelect:draw(hat:padRatio(0.2))
    self.catSelect:draw(cat:padRatio(0.2))
    self.bgSelect:draw(bg:padRatio(0.2))
end


---@param dt number
function custom:update(dt)
    g.getHUD():update(dt)
    g.requestBGM(g.BGMID.CUSTOMIZATION)
end

function custom:draw()
    local w, h = love.graphics.getDimensions()

    -- Draw background
    lg.setColor(1,1,1)
    love.graphics.draw(self.background, 0, 0, 0, w, h)

    -- Draw vignette
    vignette.draw()

    -- Draw UI
    ui.startUI()
    local mapButtonR = self:renderMapButton()
    self:_drawUI(mapButtonR)
    --g.getHUD():draw({profile = false, xpbar = false})
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
