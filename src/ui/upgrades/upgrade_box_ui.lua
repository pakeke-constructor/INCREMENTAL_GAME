
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
local godrays = require("src.modules.godrays.godrays")


local RAY_COLOR = objects.Color("#".."FFF2E46C")

---@param tree g.Tree
---@param upg g.Tree.Upgrade
---@param level integer
---@param cx number
---@param cy number
---@param isBlackedOut boolean
---@return boolean isHovered
---@return boolean wasJustClicked
---@return boolean wasJustHovered
local function upgradeBoxUI(tree, upg, level, cx, cy, isBlackedOut)
    local time = love.timer.getTime()
    local uinfo = g.getUpgradeInfo(upg.id)

    local maxLevel = tree:getUpgradeMaxLevel(upg)
    local hasBought = level > 0
    local isMaxLevel = upg.level >= maxLevel
    local canAfford = level < maxLevel and tree:canAffordUpgrade(upg, level+1)

    ------------------------------
    -- define background and frame
    ------------------------------
    local background = nil
    local frame
    if uinfo.kind == "TOKEN" then
        if canAfford then
            frame = "upgradeborder_token_golden"
        elseif isMaxLevel then
            frame = "upgradeborder_token"
        else
            frame = "upgradeborder_token_gray"
        end
    else
        if canAfford then
            background = "upgradebackground_golden"
            frame = "upgradeborder_golden"
        elseif isMaxLevel then
            background = "upgradebackground_upgrade"
            frame = "upgradeborder_upgrade"
        else
            background = "upgradebackground_gray"
            frame = "upgradeborder_cantafford"
        end
    end

    -- For button
    local x, y, w, h = g.getImageQuad(frame):getViewport()
    x = cx - w / 2
    y = cy - h / 2

    ---------------------------------------
    -- return early if we are drawing black
    ---------------------------------------
    if isBlackedOut then
        lg.setColor(0,0,0, 0.8)
        if background then
            g.drawImage(background, cx, cy)
        end
        g.drawImage(frame, cx, cy)
        return false, false, false
        -- return iml.isHovered(x,y,w,h), iml.wasJustClicked(x,y,w,h), iml.wasJustHovered(x,y,w,h)
    end

    ---------------
    -- draw godrays
    ---------------
    love.graphics.setColor(1, 1, 1)
    if canAfford and not hasBought then
        local t = time % (2 * math.pi)
        local t2 = (time * 0.8 + 1) % (2 * math.pi)
        godrays.drawRays(cx, cy, t, {color = RAY_COLOR, rayCount = 6, startWidth = 2, length = 32, fadeTo=0.15})
        godrays.drawRays(cx, cy, -t2, {color = RAY_COLOR, rayCount = 4, startWidth = 2, length = 32, fadeTo=0.15})
        love.graphics.setColor(1, 1, 1)
    end

    ----------------------------
    -- draw background and frame
    ----------------------------
    if background then
        g.drawImage(background, cx, cy)
    end
    g.drawImage(frame, cx, cy)

    --------------------
    -- draw image/icon/custom shit:
    --------------------
    if level > 0 then
        lg.setColor(1,1,1)
    else
        lg.setColor(0,0,0)
    end
    if uinfo.kind == "TOKEN" then
        local tinfo = g.getTokenInfo(uinfo.tokenType)
        g.drawTokenImage(tinfo, cx, cy)
    else
        g.drawImage(uinfo.image, cx, cy)
    end

    -- custom rendering:
    if uinfo.drawUI then
        uinfo:drawUI(level, x,y,w,h)
    end

    --------------------
    -- draw level:
    --------------------
    if level > 0 then
        --love.graphics.rectangle("line",xx,yy,ww,hh)
        local font = g.getBigFont(16)
        love.graphics.setColor(1, 1, 1)
        if level == tree:getUpgradeMaxLevel(upg) then
            love.graphics.setColor(0.1, 0.7, 0)
        end
        local txtDy = 0
        if not isMaxLevel then
            txtDy = math.sin(love.timer.getTime()*4) - 1
        end
        helper.printTextOutlineSimple(tostring(level), font, 1, math.floor(cx+w/4), math.floor(cy)+txtDy)
    end

    return iml.isHovered(x,y,w,h), iml.wasJustClicked(x,y,w,h), iml.wasJustHovered(x,y,w,h)
end


return upgradeBoxUI

