---@class FishingWorld: objects.Class
local FishingWorld = objects.Class("FishingWorld")

local FisherCat = require(".FisherCat")

---@alias _FishingRarity
---| "common"
---| "rare"
---| "epic"

FishingWorld.FISHING_RARITIES = {
    common=true,
    rare=true,
    epic=true,
}


local img = love.graphics.newImage("src/scenes/fishing_scene/fishing_wharf.png")

local WHARF_IMAGE_REGION = Kirigami(175,150, 96,54)


FishingWorld.MAX_FISHERCATS = 4
FishingWorld.MAX_ROD_LEVEL = 9



---@param self FishingWorld
---@return number,number
local function getImagePos(self)
    local ix = -self.worldArea.w/2
    local iy = -self.worldArea.h/2
    return ix,iy
end


function FishingWorld:init()
    ---@type _FisherCat[]
    self.managedFishercat = {}
    ---@type _FisherCat|nil
    self.mainFishercat = nil -- This is player's fishercat

    self.worldArea = Kirigami(0,0,300,200)

    do
    local ix,iy = getImagePos(self)
    local castX = img:getWidth()+ix
    self.castArea = Kirigami(castX, 0, self.worldArea.w-castX, self.worldArea.h)
        :padRatio(0.3)
        :moveRatio(0,0.3)
    end
end


function FishingWorld:getWharfArea()
    local x,y = getImagePos(self)
    return WHARF_IMAGE_REGION
        :moveUnit(x,y)
        :padRatio(0.1)
end



if false then
    ---@return FishingWorld
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function FishingWorld() end
end

---@param dt number
function FishingWorld:update(dt)
    if self.mainFishercat then
        self.mainFishercat:update(dt)
    end

    for _, v in ipairs(self.managedFishercat) do
        v:update(dt)
    end
end

---@param a _FisherCat
---@param b _FisherCat
local function sortOrder(a, b)
    return a.y < b.y
end


---@param self FishingWorld
local function addFisherCat(self)
    local x,y = helper.randomInRegion(self:getWharfArea():get())
    table.insert(self.managedFishercat, FisherCat(x,y, self, false))
end


function FishingWorld:draw()
    ---@type _FisherCat[]
    local objlist = {}

    if self.mainFishercat then
        objlist[#objlist+1] = self.mainFishercat
    end

    local len = #self.managedFishercat
    local sn = g.getSn()
    if sn.fisherCatCount > len then
       addFisherCat(self)
    end

    for _, v in ipairs(self.managedFishercat) do
        objlist[#objlist+1] = v
    end

    table.sort(objlist, sortOrder)

    love.graphics.draw(img,getImagePos(self))

    for _, v in ipairs(objlist) do
        love.graphics.setColor(1,1,1)
        v:draw()
    end

    love.graphics.setColor(0.2,0.2,1)
    love.graphics.rectangle("line", self.castArea:get())
end



function FishingWorld:getRandomCastPosition()
    local x,y,w,h = self.castArea:get()
    local xx = helper.lerp(x,x+w, love.math.random())
    local yy = helper.lerp(y,y+h, love.math.random())
    return xx, yy
end



return FishingWorld
