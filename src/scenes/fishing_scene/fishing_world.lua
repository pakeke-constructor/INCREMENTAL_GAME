---@class g.FishingWorld: objects.Class
local FishingWorld = objects.Class("g:FishingWorld")

---@alias g.FishingRarity
---| "common"
---| "rare"
---| "epic"


local img = love.graphics.newImage("src/scenes/fishing_scene/fishing_wharf.png")

local WHARF_IMAGE_REGION = Kirigami(169,148, 124,56)



---@param self g.FishingWorld
---@return number,number
local function getImagePos(self)
    local ix = -self.worldArea.w/2 - 20
    local iy = -self.worldArea.h/2
    return ix,iy
end


function FishingWorld:init()
    ---@type g.FisherCat[]
    self.managedFishercat = {}
    ---@type g.FisherCat|nil
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
        :padRatio(0.3)
end



if false then
    ---@return g.FishingWorld
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

---@param a g.FisherCat
---@param b g.FisherCat
local function sortOrder(a, b)
    return a.y < b.y
end



function FishingWorld:draw()
    ---@type g.FisherCat[]
    local objlist = {}

    if self.mainFishercat then
        objlist[#objlist+1] = self.mainFishercat
    end

    for _, v in ipairs(self.managedFishercat) do
        objlist[#objlist+1] = v
    end

    table.sort(objlist, sortOrder)

    love.graphics.draw(img,getImagePos(self))

    love.graphics.setColor(1,1,1)
    for _, v in ipairs(objlist) do
        v:draw()
    end
end


function FishingWorld:getRandomCastPosition()
    local x,y,w,h = self.castArea:get()
    local xx = helper.lerp(x,x+w, love.math.random())
    local yy = helper.lerp(y,y+h, love.math.random())
    return xx, yy
end


---@param rarity g.FishingRarity
function FishingWorld:giveLootRewardFor(rarity)
    print("Got a(n) "..rarity.." fish")
end

return FishingWorld
