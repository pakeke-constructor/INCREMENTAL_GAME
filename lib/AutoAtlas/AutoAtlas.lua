
local PATH = (...):gsub('%.[^%.]+$', '')
local binpack = require(PATH..".binpack")

local lg = love.graphics

local Atlas = {}

local Atlas_mt = {__index = Atlas}

local function newAtlas(w, h, maxSprites)
    maxSprites = maxSprites or 15000
    w = w or 2048
    h = h or 2048
    local image = lg.newTexture(w, h, {canvas = true, dpiscale = 1})--lg.newImage(love.image.newImageData(w,h))

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


---@param imageData love.ImageData
local function getSize(imageData)
    return imageData:getWidth(), imageData:getHeight()
end



local function getXY(self, width, height)
    -- gets the x,y position of where the new quad should sit in the atlas.
    local obj = self.binpack:insert(width, height)
    if not obj then
        return nil
    end
    return obj.x, obj.y
end




---@param imageData love.ImageData
local function addToAtlas(self, imageData)
    local width, height = getSize(imageData)
    -- +2 for the padded 1px quad on all sides.
    local x, y = getXY(self, width + 2, height + 2)
    if not x then
        return nil -- texture atlas ran out of space!
    end

    -- Start adding to texture atlas.
    lg.push("all")
    lg.reset()
    lg.setCanvas(self.image)
    lg.setBlendMode("none")
    -- Make temporary Image object out of ImageData
    local image = lg.newImage(imageData, {dpiscale = 1})
    image:setFilter("nearest", "nearest")
    image:setWrap("clamp", "clamp")
    -- Make padded quad
    local q = lg.newQuad(-1, -1, width + 1, height + 1, width, height)
    -- Add to atlas
    lg.draw(image, q, x, y)
    lg.pop()

    -- Release the temp image object.
    image:release()
    q:release()

    -- Return unpadded quad.
    return lg.newQuad(x + 1, y + 1, width, height, self.width, self.height)
end



---@param imageData love.ImageData|string
---@return love.Quad?
function Atlas:add(imageData)
    -- Is path:
    if type(imageData) == "string" then
        local path = self.image
        imageData = love.image.newImageData(path)
    end

    assert(imageData:typeOf("ImageData"))
    return addToAtlas(self, imageData)
end


function Atlas:getTexture()
    return self.image
end


return newAtlas

