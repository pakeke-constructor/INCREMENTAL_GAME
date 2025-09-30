


---@class g.UpgradeDescription: objects.Class
local UpgradeDescription = objects.Class("g:UpgradeDescription")


local UPGRADE_DESC_MAX_WIDTH = 200

function UpgradeDescription:init(title, uinfo)
    self.w = 0
    self.y = 0

    self.font = g.getSmallFont(24)
    self.titleFont = g.getBigFont(32)

    self.boxWidth = 100

    self.elements = objects.Array()
end


function UpgradeDescription:addText(txt)
    local stripped = richtext.stripEffects(txt)
    local fw,fh = self.font:getWidth(stripped), self.font:getHeight()
    if fw > UPGRADE_DESC_MAX_WIDTH then
        local w,wtxt = self.font:getWrap(stripped, UPGRADE_DESC_MAX_WIDTH)
        fh = fh*(#wtxt)
        self.boxWidth = math.max(self.boxWidth, w)
    end

    self:addBox(fw,fh, function(x,y,w,h)
        richtext.printRich(txt, self.font, x,y, self.boxWidth, "center")
    end)
end



---comment
---@param w number
---@param h number
---@param render fun(x,y,w,h)
function UpgradeDescription:addBox(w,h, render)
    
end


---@param bundle g.Bundle
function UpgradeDescription:addPrice(bundle)
    -- adds the price at the bottom
end


function UpgradeDescription:draw()
    
end


return UpgradeDescription
