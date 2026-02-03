
local FSCanvas = require("src.modules.fscanvas.fscanvas")

---@class _cloudService
local cloudService = {}

---@type [string,number][]
local CLOUD_IMAGES = {
    {"bigcloud_bosszone", 1},
    {"bigcloud_emptyzone", 1},
    {"bigcloud_fishingzone", 1},
    {"bigcloud_minigamezone", 1},
    {"bigcloud_questzone", 1},
    {"bigcloud_upgradezone", 1},
    {"smallcloud_dot", 3},
    {"smallcloud_long", 3}
}
local MAX_COUDS = 10
local CLOUD_SPEED_RANGE = {20, 35}
local CLOUD_HEIGHT_RANGE = {80, 130} -- math.floored btw
local CLOUD_LEIGHTWAY = 16

---@class _cloudService.cloud
---@field public image string
---@field public x number cloud shadow position on center
---@field public y number cloud shadow position on center
---@field public flip -1|1
---@field public speed number
---@field public height integer

---@type _cloudService.cloud[]
cloudService.clouds = {}
cloudService.shadowCanvas = FSCanvas() -- for shadow

cloudService.dims = {-1, -1, 0, 0}


---@return _cloudService.cloud
function cloudService.newCloud()
    return {
        x = 0,
        y = 0,
        image = helper.pickWeighted(CLOUD_IMAGES),
        flip = love.math.random() >= 0.5 and 1 or -1,
        speed = helper.lerp(CLOUD_SPEED_RANGE[1], CLOUD_SPEED_RANGE[2], love.math.random()),
        height = math.floor(helper.lerp(CLOUD_HEIGHT_RANGE[1], CLOUD_HEIGHT_RANGE[2], love.math.random()))
    }
end

---Clouds are rebuilt if the window dimension changes.
function cloudService.rebuild(x, y, w, h)
    cloudService.clouds = {}
    local pad = CLOUD_LEIGHTWAY

    for _ = 1, MAX_COUDS do
        local c = cloudService.newCloud()

        -- Randomize position
        c.x = helper.lerp(x + pad, x + w - pad * 2, love.math.random())
        c.y = helper.lerp(y + pad, y + h - pad * 2, love.math.random())

        -- Insert
        cloudService.clouds[#cloudService.clouds+1] = c
    end
end

---@param dt number
---@param camera Camera
function cloudService.update(dt, camera)
    local x, y = camera:toWorld(0, 0)
    local x2, y2 = camera:toWorld(love.graphics.getDimensions())
    local w, h = x2 - x, y2 - y

    if
        cloudService.dims[1] ~= x
        or cloudService.dims[2] ~= y
        or cloudService.dims[3] ~= w
        or cloudService.dims[4] ~= h
    then
        cloudService.rebuild(x, y, w, h)
        cloudService.dims = {x, y, w, h}
        return
    end

    -- Update and remove existing clouds
    for i = #cloudService.clouds, 1, -1 do
        local c = cloudService.clouds[i]
        local cwidth = select(3, g.getImageQuad(c.image):getViewport()) --[[@as number]]

        c.x = c.x + c.speed * dt
        if c.x >= w + cwidth / 2 then
            table.remove(cloudService.clouds, i)
        end
    end

    -- Spawn new clouds
    local pad = CLOUD_LEIGHTWAY
    for i = 1, MAX_COUDS - #cloudService.clouds do
        local c = cloudService.newCloud()
        local cwidth = select(3, g.getImageQuad(c.image):getViewport()) --[[@as number]]

        -- Randomize Y position
        c.x = x - cwidth / 2
        c.y = helper.lerp(y + pad, y2 - pad, love.math.random())

        -- Insert
        cloudService.clouds[#cloudService.clouds+1] = c
    end
end

function cloudService.draw()
    for _, c in ipairs(cloudService.clouds) do
        g.drawImage(c.image, c.x, c.y - c.height, 0, c.flip, 1)
    end
end

function cloudService.drawShadow()
    local canv = cloudService.shadowCanvas:get()
    love.graphics.push("all")
    love.graphics.setBlendMode("alpha", "alphamultiply")

    love.graphics.push("all")
    love.graphics.setCanvas(canv)
    love.graphics.clear(1, 1, 1, 0)
    love.graphics.setColor(1, 1, 1)

    for _, c in ipairs(cloudService.clouds) do
        g.drawImage(c.image, c.x, c.y, 0, c.flip, 1)
    end

    love.graphics.pop()

    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.draw(canv)

    love.graphics.pop()
end

return cloudService
