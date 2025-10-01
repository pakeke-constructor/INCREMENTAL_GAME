
--[[

INTUITION VISUALS:

- LOCKED: EVERY COLOR is gray, locked-icon

- Hasnt been purchased: Icon is black!


- Cant afford: Everything made slightly darker. Red-border.
- Can afford:  Regular colors, Regular border. Occasionally shakes

- SHOULD BUY:  Rapidly shakes, pulses in scale

- Can afford + Hasnt-been-purchased:  Green Plus hovering in bottom-right

- Token-Upgrade: transparent-ish background behind token-image
- Misc-Upgrade: white-border


]]

local lg = love.graphics




---@param uinfo g.UpgradeInfo
---@param level number
---@param color objects.Color
local function adjustColor(uinfo, level, color)
    -- if locked: fully-gray (saturation=0)
    local isLocked = false
    if isLocked then
        -- hasnt been purchased.
        color.s = 0
        color.l = color.l/2
        return
    end

    if not g.canAffordUpgrade(uinfo) then
        -- make it red.
        local lerped = objects.Color.lerp(color, g.COLORS.CANT_AFFORD,0.8)
        color:setRGBA(lerped:getRGBA())
    end
end


---@param uinfo g.UpgradeInfo
---@return boolean isHovered
---@return boolean wasJustClicked
local function upgradeBoxUI(uinfo, level, x,y,w,h)
    local cpy = objects.Color
    local UPCOLS = g.COLORS.UPGRADE_KINDS
    local cx,cy = x+w/2, y+h/2

    --------------------
    -- draw background:
    --------------------
    local col = cpy(UPCOLS[uinfo.kind])
    col.l = col.l - 0.2
    adjustColor(uinfo,level,col)
    if uinfo.kind == "TOKEN" then
        -- tokens have transparent bg
        col.a = 0.3
    end
    lg.setColor(col)
    lg.rectangle("fill", x,y,w,h)


    --------------------
    -- draw border:
    --------------------
    local borderCol
    if g.canAffordUpgrade(uinfo) then
        borderCol = cpy(UPCOLS[uinfo.kind] or g.COLORS.UPGRADE_KINDS.MISC)
    else
        borderCol = cpy(g.COLORS.CANT_AFFORD)
    end
    adjustColor(uinfo, level, borderCol)
    local lw = lg.getLineWidth()
    lg.setLineWidth(2)
    lg.setColor(0,0,0)
    lg.rectangle("line",x-1,y-1,w+2,h+2)
    lg.setLineWidth(2)
    lg.setColor(borderCol)
    lg.rectangle("line",x,y,w,h)


    --------------------
    -- draw image/icon:
    --------------------
    if level > 0 then
        lg.setColor(1,1,1)
    else
        lg.setColor(0,0,0)
    end
    g.drawImage(uinfo.image, cx, cy)


    --------------------
    -- draw level:
    --------------------
    if level > 0 then
        --love.graphics.rectangle("line",xx,yy,ww,hh)
        local font = g.getBigFont(16)
        richtext.printRich("{o thickness=1}"..tostring(level), font, math.floor(cx+w/4), math.floor(cy), 0xfffff, "left")
    end

    lg.setLineWidth(lw)
    return iml.isHovered(x,y,w,h), iml.wasJustClicked(x,y,w,h)
end


return upgradeBoxUI

