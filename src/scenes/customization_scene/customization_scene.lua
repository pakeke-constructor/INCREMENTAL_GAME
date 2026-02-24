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
    local img = "town_grass_"..rng:random(1,2)
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



local CAT_REGS = {
    Kirigami(0.65,0.26, 0.15,0.6),
    Kirigami(0.16,0.22, 0.28,0.7),
    Kirigami(0.3,0.7, 0.4,0.25)
}

local NUM_CATS = 30
local fakeCats = {}

local function spawnFakeCats()
    local cats = cosmetics.getAllAvatars()
    local hats = cosmetics.getAllHats()
    for _=1, NUM_CATS do
        local regionIndex = love.math.random(1, #CAT_REGS)
        local reg = CAT_REGS[regionIndex]

        local cat = {
            x = love.math.random(), y=love.math.random(),
            targX = love.math.random(), targY = love.math.random(),
            waitTime = love.math.random() * 3,
            reg = reg
        }
        cat.avatar = {}
        if love.math.random() > 0.4 then
            cat.avatar.avatar = helper.randomChoice(cats)
        else
            cat.avatar.avatar = consts.DEFAULT_CAT_AVATAR
        end
        if love.math.random() > 0.4 then
            cat.avatar.hat = helper.randomChoice(hats)
        end
        table.insert(fakeCats, cat)
    end
end


local WADDLE_ANIM_SPEED = 6
local function drawFakeCats(reg)
    if spawnFakeCats then
        spawnFakeCats()
        ---@diagnostic disable-next-line
        spawnFakeCats = false
    end
    local dt = love.timer.getAverageDelta()
    for _, cat in ipairs(fakeCats) do
        local r2 = cat.reg
        local x = reg.x+cat.x*reg.w*r2.w + r2.x*reg.w
        local y = reg.y+cat.y*reg.h*r2.h + r2.y*reg.h
        
        -- Calculate movement direction
        local dx = cat.targX - cat.x
        local dy = cat.targY - cat.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        -- Waddle animation
        local sx = 1
        local rot = 0
        local catDy = 0
        
        if dx > 0 then
            sx = 1
        elseif dx < 0 then
            sx = -1
        end
        
        local t = love.timer.getTime() * WADDLE_ANIM_SPEED
        local isMoving = (dx*dx + dy*dy) > 0.01 and cat.waitTime <= 0
        
        if isMoving then
            -- Waddle effect when moving
            local height = math.abs(math.sin(t)) * 7
            rot = math.cos(t) / 6
            catDy = -height
        end

        lg.setColor(0,0,0, 0.4)
        g.drawImage("shadow_medium", x, y+3)

        lg.setColor(1,1,1)
        g.drawAvatar(cat.avatar, x, y, false, rot, sx, 1, catDy)

        if cat.waitTime > 0 then
            cat.waitTime = cat.waitTime - dt
        else
            -- move towards target
            if dist < 0.01 then
                -- arrived!
                if love.math.random() < 0.5 then
                    cat.waitTime = love.math.random(1,5) -- wait a random time
                else
                    cat.targX = love.math.random()
                    cat.targY = love.math.random()
                end
            else
                cat.x = cat.x+dx*0.3*dt/dist
                cat.y = cat.y+dy*0.3*dt/dist
            end
        end
    end
end




local GROUND_COLOR = objects.Color("#" .. "FF1DAE65")
local DARK_COLOR = objects.Color("#" .. "FF20A362")
local LIGHT_COLOR = objects.Color("#" .. "FF35BA64")

local GROUND_COLOR = objects.Color("#" .. "FF6137D3")
local DARK_COLOR   = objects.Color("#" .. "FF5E14B8")
local LIGHT_COLOR  = objects.Color("#" .. "FF6633DC")

local drawEdgeClouds
do
    local CLOUD_VERTICAL_MOVE_AMOUNT = 20
    local CLOUD_MOVE_SPEED = 0.2
    local CLOUD_OFFSET_FROM_CORNER = -5
    local CLOUD_OFFSET_FROM_EDGE = -85
    local CLOUD_OVERLAP_SPACING = 60

    local function drawCornerCloud(cloudName, x, y, seed)
        local t = love.timer.getTime()
        local offsetY = math.sin(t * CLOUD_MOVE_SPEED + seed) * CLOUD_VERTICAL_MOVE_AMOUNT
        g.drawImage(cloudName, x, y + offsetY)
    end

    function drawEdgeClouds(x, y, w, h)
        local o = CLOUD_OFFSET_FROM_CORNER
        local s = CLOUD_OVERLAP_SPACING
        local eo = CLOUD_OFFSET_FROM_EDGE

        drawCornerCloud("bigcloud_fishingzone", x + o, y + o, 1)
        drawCornerCloud("bigcloud_minigamezone", x + o + s, y + o, 2)
        drawCornerCloud("bigcloud_questzone", x + o, y + o + s, 3)

        drawCornerCloud("bigcloud_bosszone", x + w - o, y + o, 4)
        drawCornerCloud("bigcloud_emptyzone", x + w - o - s, y + o, 5)
        drawCornerCloud("bigcloud_fishingzone", x + w - o, y + o + s, 6)

        drawCornerCloud("bigcloud_minigamezone", x + o, y + h - o, 7)
        drawCornerCloud("bigcloud_bosszone", x + o + s, y + h - o, 8)
        drawCornerCloud("bigcloud_emptyzone", x + o, y + h - o - s, 9)

        drawCornerCloud("bigcloud_questzone", x + w - o, y + h - o, 10)
        drawCornerCloud("bigcloud_fishingzone", x + w - o - s, y + h - o, 11)
        drawCornerCloud("bigcloud_minigamezone", x + w - o, y + h - o - s, 12)

        drawCornerCloud("bigcloud_emptyzone", x + w / 2, y + eo, 13)
        drawCornerCloud("bigcloud_bosszone", x + w / 2, y + h - eo, 14)
        drawCornerCloud("bigcloud_fishingzone", x + eo, y + h / 2, 15)
        drawCornerCloud("bigcloud_questzone", x + w - eo, y + h / 2, 16)
    end
end

---@param self CustomizationScene
---@param reg kirigami.Region
local function drawTown(self,reg)
    lg.setColor(GROUND_COLOR)
    lg.setColorMask(true, true, true, true)
    lg.rectangle("fill", reg:get())

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
    drawFakeCats(reg)
end




local GET_SKINS_TEXT = loc("Get Skins!")
local COMMUNITY_MARKET_URL = "https://steamcommunity.com/market/search?appid=4173020"

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

    local btnReg = c:shrinkToAspectRatio(2,1):padUnit(4)
    if ui.DefaultButton(GET_SKINS_TEXT, btnReg) then
        love.system.openURL(COMMUNITY_MARKET_URL)
    end
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
    --love.graphics.draw(self.background, 0, 0, 0, w, h)
    lg.clear(GROUND_COLOR)

    -- Draw UI
    ui.startUI()
    local r = ui.getScreenRegion()
    local top,bot = r:splitVertical(5,2)
    drawTown(self, top)
    drawEdgeClouds(r:get())
    self:_drawCosmeticUI(bot)
    self:renderMapButton()
    self:renderPause()
    ui.endUI()

    vignette.draw()
end

function custom:keyreleased(k)
    if k == "escape" then
        local s = g.getSn()
        s.paused = not s.paused
    end
end

return custom
