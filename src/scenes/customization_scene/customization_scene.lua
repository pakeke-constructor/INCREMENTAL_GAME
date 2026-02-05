local FreeCameraScene = require("src.scenes.FreeCameraScene")

local vignette = require("src.modules.vignette.vignette")

local CustomSelect = require(".CustomSelect")

local cosmetics = require("src.cosmetics.cosmetics")



local function getHats()
    local hats = g.getUnlockedCosmetics("HAT")
    table.insert(hats, 1, "")
    return hats
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

    self.bgSelect = CustomSelect(g.getUnlockedCosmetics("BACKGROUND"), function (item, reg)
        local cinfo = g.getCosmeticInfo(item)
        g.drawImageContained(cinfo.image, reg:get())
    end)
    self.hatSelect = CustomSelect(g.getUnlockedCosmetics("HAT"), function (item, reg)
        if #item > 0 then
            local cinfo = g.getCosmeticInfo(item)
            g.drawImageContained(cinfo.image, reg:get())
        end
    end)
    self.catSelect = CustomSelect(g.getUnlockedCosmetics("AVATAR"), function (item, reg)
        local cinfo = g.getCosmeticInfo(item)
        g.drawImageContained(cinfo.image, reg:get())
    end)
end



function custom:enter()
    cosmetics.tryRefresh()
    local sn = g.getSn()

    local bgs = g.getUnlockedCosmetics("BACKGROUND")
    self.bgSelect:setItems(bgs)
    for i, item in ipairs(bgs) do
        if sn.avatar.background == item then
            self.bgSelect:setSelectionIndex(i)
            break
        end
    end

    local cats = g.getUnlockedCosmetics("AVATAR")
    self.catSelect:setItems(cats)
    for i, item in ipairs(cats) do
        if sn.avatar.avatar == item then
            self.catSelect:setSelectionIndex(i)
            break
        end
    end

    local hats = getHats()
    self.hatSelect:setItems(hats)
    for i, item in ipairs(hats) do
        if (sn.avatar.hat or "") == item then
            self.hatSelect:setSelectionIndex(i)
            break
        end
    end
end




local TOWN_GROUND = {
    -- BIG DECOR:
    {image = "decor_big_1", x = 0.15, y = 0.2},
    {image = "decor_big_3", x = 0.82, y = 0.48},
    {image = "decor_big_2", x = 0.4, y = 0.9},
    {image = "decor_big_4", x = 0.93, y = 0.3},
    {image = "decor_big_1", x = 0.07, y = 0.62},
    {image = "decor_big_2", x = 0.55, y = 0.12},
    {image = "decor_big_3", x = 0.68, y = 0.78},
    {image = "decor_big_4", x = 0.24, y = 0.44},
    {image = "decor_big_1", x = 0.5, y = 0.6},
    {image = "decor_big_2", x = 0.88, y = 0.07},
    {image = "decor_big_3", x = 0.31, y = 0.26},
    {image = "decor_big_4", x = 0.73, y = 0.55},
    {image = "decor_big_1", x = 0.19, y = 0.85},
    {image = "decor_big_2", x = 0.61, y = 0.36},
    {image = "decor_big_3", x = 0.46, y = 0.18},
    {image = "decor_big_4", x = 0.97, y = 0.72},
    {image = "decor_big_1", x = 0.28, y = 0.58},
    {image = "decor_big_2", x = 0.77, y = 0.41},
    {image = "decor_big_3", x = 0.12, y = 0.33},
    {image = "decor_big_4", x = 0.6, y = 0.95},

    {image = "decor_big_2", x = 0.34, y = 0.11},
    {image = "decor_big_4", x = 0.9, y = 0.52},
    {image = "decor_big_1", x = 0.06, y = 0.73},
    {image = "decor_big_3", x = 0.58, y = 0.27},
    {image = "decor_big_2", x = 0.79, y = 0.88},
    {image = "decor_big_4", x = 0.21, y = 0.49},
    {image = "decor_big_1", x = 0.47, y = 0.05},
    {image = "decor_big_3", x = 0.99, y = 0.34},
    {image = "decor_big_2", x = 0.63, y = 0.6},
    {image = "decor_big_4", x = 0.14, y = 0.92},
    {image = "decor_big_1", x = 0.52, y = 0.39},
    {image = "decor_big_3", x = 0.83, y = 0.16},
    {image = "decor_big_2", x = 0.25, y = 0.7},
    {image = "decor_big_4", x = 0.71, y = 0.46},
    {image = "decor_big_1", x = 0.38, y = 0.83},
    {image = "decor_big_3", x = 0.95, y = 0.58},
    {image = "decor_big_2", x = 0.18, y = 0.24},
    {image = "decor_big_4", x = 0.67, y = 0.74},
    {image = "decor_big_1", x = 0.44, y = 0.57},
    {image = "decor_big_3", x = 0.86, y = 0.03},

}

local TOWN_GROUND_DETAIL = {
    -- DECOR:
    {image = "decor_tex_3", x = 0.52, y = 0.71},
    {image = "decor_tex_1", x = 0.12, y = 0.34},
    {image = "decor_tex_5", x = 0.77, y = 0.22},
    {image = "decor_tex_2", x = 0.43, y = 0.88},
    {image = "decor_tex_1", x = 0.91, y = 0.47},
    {image = "decor_tex_3", x = 0.25, y = 0.63},
    {image = "decor_tex_1", x = 0.68, y = 0.15},
    {image = "decor_tex_5", x = 0.36, y = 0.79},
    {image = "decor_tex_2", x = 0.84, y = 0.05},
    {image = "decor_tex_1", x = 0.18, y = 0.56},
    {image = "decor_tex_3", x = 0.59, y = 0.92},

    {image = "decor_tex_2", x = 0.07, y = 0.44},
    {image = "decor_tex_1", x = 0.95, y = 0.12},
    {image = "decor_tex_1", x = 0.33, y = 0.67},
    {image = "decor_tex_5", x = 0.81, y = 0.73},
    {image = "decor_tex_3", x = 0.48, y = 0.21},
    {image = "decor_tex_2", x = 0.14, y = 0.9},
    {image = "decor_tex_1", x = 0.62, y = 0.38},
    {image = "decor_tex_1", x = 0.29, y = 0.52},
    {image = "decor_tex_5", x = 0.74, y = 0.31},
    {image = "decor_tex_3", x = 0.57, y = 0.08},

    {image = "decor_tex_2", x = 0.41, y = 0.6},
    {image = "decor_tex_1", x = 0.88, y = 0.83},
    {image = "decor_tex_1", x = 0.05, y = 0.27},
    {image = "decor_tex_5", x = 0.69, y = 0.49},
    {image = "decor_tex_3", x = 0.22, y = 0.75},
    {image = "decor_tex_2", x = 0.97, y = 0.41},
    {image = "decor_tex_1", x = 0.53, y = 0.58},
    {image = "decor_tex_1", x = 0.31, y = 0.14},
    {image = "decor_tex_5", x = 0.79, y = 0.66},
    {image = "decor_tex_3", x = 0.11, y = 0.37},

    {image = "decor_tex_2", x = 0.46, y = 0.95},
    {image = "decor_tex_1", x = 0.83, y = 0.18},
    {image = "decor_tex_1", x = 0.27, y = 0.7},
    {image = "decor_tex_5", x = 0.6, y = 0.26},
    {image = "decor_tex_3", x = 0.35, y = 0.82},
    {image = "decor_tex_2", x = 0.9, y = 0.54},
    {image = "decor_tex_1", x = 0.16, y = 0.61},
    {image = "decor_tex_1", x = 0.72, y = 0.09},
    {image = "decor_tex_5", x = 0.5, y = 0.45},
    {image = "decor_tex_3", x = 0.24, y = 0.97},

    {image = "decor_tex_2", x = 0.38, y = 0.19},
    {image = "decor_tex_1", x = 0.86, y = 0.69},
    {image = "decor_tex_1", x = 0.02, y = 0.48},
    {image = "decor_tex_5", x = 0.66, y = 0.87},
    {image = "decor_tex_3", x = 0.55, y = 0.33},
    {image = "decor_tex_2", x = 0.19, y = 0.8},
    {image = "decor_tex_1", x = 0.93, y = 0.24},
    {image = "decor_tex_1", x = 0.44, y = 0.57},
    {image = "decor_tex_5", x = 0.76, y = 0.11},
    {image = "decor_tex_3", x = 0.3, y = 0.64},

    {image = "decor_tex_2", x = 0.58, y = 0.04},
    {image = "decor_tex_1", x = 0.99, y = 0.76},
    {image = "decor_tex_1", x = 0.21, y = 0.55},
    {image = "decor_tex_5", x = 0.63, y = 0.2},
    {image = "decor_tex_3", x = 0.47, y = 0.89},
    {image = "decor_tex_2", x = 0.08, y = 0.68},
    {image = "decor_tex_1", x = 0.82, y = 0.36},
    {image = "decor_tex_1", x = 0.54, y = 0.13},
    {image = "decor_tex_5", x = 0.7, y = 0.59},
    {image = "decor_tex_3", x = 0.26, y = 0.42},

    {image = "decor_tex_2", x = 0.49, y = 0.77},
    {image = "decor_tex_1", x = 0.87, y = 0.29},
    {image = "decor_tex_1", x = 0.17, y = 0.93},
    {image = "decor_tex_5", x = 0.61, y = 0.4},
    {image = "decor_tex_3", x = 0.34, y = 0.17},
    {image = "decor_tex_2", x = 0.92, y = 0.62},
    {image = "decor_tex_1", x = 0.23, y = 0.5},
    {image = "decor_tex_1", x = 0.75, y = 0.07},
    {image = "decor_tex_5", x = 0.56, y = 0.84},
    {image = "decor_tex_3", x = 0.4, y = 0.28},
}

local TOWN_BUILDINGS = {
    -- HOUSES:
    {image = "bighouse", x = 0.8, y = 0.1},
    {image = "longhouse", x = 0.6, y = 0.0},
    {image = "barbershop", x = 0.4, y = 0.05},
    {image = "smallhouse", x = 0.0, y = 0.8},
    {image = "smallhouse", x = 0.1, y = 0.5},
    {image = "smallhouse", x = 0.15, y = 0.1},
    {image = "longhouse", x = 0.95, y = 0.6},
    {image = "bighouse", x = 0.0, y = 0.0},
    --{image = "barbershop", x = 0.8, y = 0.1},
    --{image = "well", x = 0.5, y = 0.5},
    {image = "well", x = 0.5, y = 0.5},
    {image = "town_board", x = 0.6, y = 0.55},
}


local GRASSES = {}
local rng = love.math.newRandomGenerator(889323)
for _=1, 70 do
    local img = "grass_"..rng:random(1,3)
    local g = {image=img, x=rng:random(), y=rng:random()}
    local bad=false
    for _,t in ipairs(TOWN_BUILDINGS)do
        local dist = helper.magnitude(g.x-t.x, g.y-t.y)
        if dist < 0.02 then
            bad=true
            break
        end
    end
    if not bad then
        table.insert(GRASSES, g)
    end
end



local GROUND_COLOR = objects.Color("#" .. "FF1DAE65")
local DARK_COLOR = objects.Color("#" .. "FF20A362")
local LIGHT_COLOR = objects.Color("#" .. "FF35BA64")

---@param self CustomizationScene
---@param reg kirigami.Region
local function drawTown(self,reg)
    lg.setColor(GROUND_COLOR)
    lg.setStencilMode("draw", 4)
    lg.setColorMask(true, true, true, true)
    lg.rectangle("fill", reg:get())

    lg.setStencilMode("test", 4)
    lg.setColor(DARK_COLOR)
    for _,b in ipairs(TOWN_GROUND)do
        local x = math.floor(reg.x + (reg.w*b.x))
        local y = math.floor(reg.y + (reg.h*b.y))
        g.drawImage(b.image, x,y, 0, 2,2)
    end
    lg.setColor(LIGHT_COLOR)
    for _,b in ipairs(TOWN_GROUND_DETAIL)do
        local x = math.floor(reg.x + (reg.w*b.x))
        local y = math.floor(reg.y + (reg.h*b.y))
        g.drawImage(b.image, x,y)
    end
    lg.setColor(1,1,1)
    for i,b in ipairs(GRASSES)do
        local x = math.floor(reg.x + (reg.w*b.x))
        local y = math.floor(reg.y + (reg.h*b.y))
        local scc = math.sin(i + love.timer.getTime()*2)/8
        local quad = g.getImageQuad(b.image)
        local _,_,w,h = quad:getViewport()
        local oy = scc*h/2
        g.drawImage(b.image, x,y-oy, 0, 1,1+scc, 0,0)
    end
    lg.setColor(1,1,1)
    for _,b in ipairs(TOWN_BUILDINGS)do
        local x = math.floor(reg.x + (reg.w*b.x))
        local y = math.floor(reg.y + (reg.h*b.y))
        g.drawImage(b.image, x,y)
    end
    lg.setStencilMode()
end



---@param bot kirigami.Region
function custom:_drawCosmeticUI(bot)
    local a,b,c = bot:splitHorizontal(3, 7, 2)

    -- Draw avatar with background
    local avatarR = a:shrinkToAspectRatio(1, 1):padUnit(18)
    local avatarSize = math.min(avatarR.w, avatarR.h) / consts.AVATAR_SIZE
    local avatarX, avatarY = avatarR:getCenter()
    love.graphics.setStencilMode("draw", 3)
    love.graphics.rectangle("fill", avatarR:get())
    love.graphics.setStencilMode("test", 3)
    g.drawPlayerAvatar(avatarX, avatarY, avatarSize, true, true)
    love.graphics.setStencilMode()
    love.graphics.setColor(0, 0, 0)

    local hat, cat, bg = b:padRatio(0.1):splitVertical(1,1,1)
    self.hatSelect:draw(hat:padRatio(0.2))
    self.catSelect:draw(cat:padRatio(0.2))
    self.bgSelect:draw(bg:padRatio(0.2))
end


---@param dt number
function custom:update(dt)
    local sn = g.getSn()
    g.getHUD():update(dt)
    g.requestBGM(g.BGMID.CUSTOMIZATION)
    self.bgSelect:setItems(g.getUnlockedCosmetics("BACKGROUND"))
    self.catSelect:setItems(g.getUnlockedCosmetics("AVATAR"))
    self.hatSelect:setItems(getHats())

    sn.avatar.background = self.bgSelect:getSelected()
    sn.avatar.avatar = self.catSelect:getSelected()
    local hat = self.hatSelect:getSelected()
    if #hat > 0 then
        sn.avatar.hat = hat
    else
        sn.avatar.hat = nil
    end
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
    local r = ui.getScreenRegion()
    local top,bot = r:splitVertical(3,2)
    drawTown(self, top)
    self:_drawCosmeticUI(bot)
    self:renderMapButton()
    self:renderPause()
    ui.endUI()
end

function custom:keyreleased(k)
    if k == "escape" then
        local s = g.getSn()
        s.paused = not s.paused
    end
end

return custom
