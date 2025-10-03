
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


---@param x number
local function triangleWave(x)
    return 2 * math.min(x, 1 - x)
end

---@param x number
local function easeInOutSine(x)
    return -(math.cos(math.pi * x) - 1) / 2;
end

---@param uinfo g.UpgradeInfo
---@param level integer
---@param x number
---@param y number
---@param w number
---@param h number
---@param isRecommended boolean
---@return boolean isHovered
---@return boolean wasJustClicked
local function upgradeBoxUI(uinfo, level, x,y,w,h, isRecommended)
    local cpy = objects.Color
    local UPCOLS = g.COLORS.UPGRADE_KINDS
    local cx,cy = x+w/2, y+h/2
    local time = love.timer.getTime()

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
    lg.setColor(0,0,0)
    lg.setLineWidth(2)
    lg.rectangle("line",x-1,y-1,w+2,h+2)
    lg.setColor(borderCol)
    lg.rectangle("line",x,y,w,h)

    if isRecommended then
        local alpha = (1+math.sin(time*8))/2
        local cr, cg, cb = g.COLORS.RECOMMENDED:getRGBA()
        lg.setLineWidth(4)
        lg.setColor(cr, cg, cb, alpha^2)
        -- lg.rectangle("line",x-2,y-2,w+4,h+4)
        lg.rectangle("line",x,y,w,h)
    end

    --------------------
    -- draw image/icon:
    --------------------
    local sc=1
    if level > 0 then
        lg.setColor(1,1,1)
    else
        lg.setColor(0,0,0)
    end
    if isRecommended then
        sc = 1+math.abs(math.sin(time*4+4))/5
    end
    g.drawImage(uinfo.image, cx, cy, 0,sc,sc)


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

