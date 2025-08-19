
local PATH = (...):gsub('%.[^%.]+$', '')
local binpack = require(PATH..".binpack")

local lg = love.graphics

local Atlas = {}

local Atlas_mt = {__index = Atlas}

local function newAtlas(w, h, maxSprites)
    maxSprites = maxSprites or 15000
    w = w or 2048
    h = h or 2048
    local image = lg.newTexture(w, h, {dpiscale = 1})--lg.newImage(love.image.newImageData(w,h))

    return setmetatable({
        width = w, height = h,
        binpack = binpack(w, h),
        image = image,
        path = "",
        imageData = {}
    }, Atlas_mt)
end


local lg_draw = lg.draw


local function draw(self, quad, x, y, r, sx, sy, ox, oy, kx, ky)
    lg_draw(self.image, quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

local function batchedDraw(self, quad, x, y, r, sx, sy, ox, oy, kx, ky)
    -- Batch draw
    self.batch:add(quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

Atlas.draw = draw


function Atlas:flushBatch()
    if not(self.using_batch) then
        return
    end
    self.batch:flush()
    lg_draw(self.batch)
    self.batch:clear()
end


function Atlas:useBatch(bool)
    --[[
        Atlas:useBatch(true) -- if we want to use batches.
    ]]
    self.using_batch = bool
    if bool then
        self.draw = batchedDraw
    else
        self.draw = draw
    end
end


local function getSize(imageData)
    return imageData:getWidth(), imageData:getHeight()
end



local function getXY(self, width, height)
    -- gets the x,y position of where the new quad should sit in the atlas.
    local obj = self.binpack:insert(width+1, height+1)
    if not obj then
        return nil
    end
    return obj.x, obj.y
end




local function addToAtlas(self, imageData)
    local width, height = getSize(imageData)
    local x, y = getXY(self, width, height)
    if not x then
        return nil -- texture atlas ran out of space!
    end
    -- ImageData w/ Image:replacePixels
    self.image:replacePixels(imageData, nil, 1, x, y)
    lg.pop()
    return lg.newQuad(x, y, width, height, self.width, self.height)
end



function Atlas:add(imageData)
    lg.push("all")
    lg.reset()

    -- Is path:
    if type(imageData) == "string" then
        local path = self.image
        imageData = lg.newImageData(path)
    end

    assert(imageData:type("ImageData"))
    return addToAtlas(self, imageData)
end


function Atlas:getTexture()
    return self.image
end


return newAtlas

