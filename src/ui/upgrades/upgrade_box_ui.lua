
--[[

INTUITION VISUALS:

- LOCKED: EVERY COLOR is gray, locked-icon
- Hasnt been purchased: Icon is black. Background is darker.

- Cant afford: Everything made slightly darker. Red-border.

- Can afford:  Regular colors, Regular border. Occasionally shakes
- SHOULD BUY:  Rapidly shakes, pulses in scale


- Token-Upgrade: transparent-ish background behind token-image
- Misc-Upgrade: white-border


]]

local lg = love.graphics


---@param uinfo g.UpgradeInfo
local function upgradeBoxUI(uinfo, x,y,w,h)
    local cols = g.COLORS.UPGRADE_KINDS

    -- draw background:
    local col = objects.Color(cols[uinfo.kind])
    if uinfo.kind == "TOKEN" then
        -- tokens have transparent bg
        col.a = 0.3
        g.drawImage(uinfo.image, x+w/2,y+h/2)
    end
    lg.setColor(col)
    lg.rectangle("fill", x,y,w,h)

    -- draw border:
    
end


