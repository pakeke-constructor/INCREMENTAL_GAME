
---@class g.cosmetics
local cosmetics = {}


---------------------------------
--- Accessories/Customization ---
---------------------------------



---@class g.Avatar
---@field public avatar string Cat avatar ID
---@field public background string Background ID of the avatar
---@field public hat string? Cat hat ID



---@class g.CosmeticDef
---@field public image string?
---@field public upscale integer?
---@field public color objects.Color?
---@field public offsetX number? offset: how its positioned in pixels (e.g. hat is up)
---@field public offsetY number? offset: how its positioned in pixels (e.g. hat is up)
---@field public originX number? origin; affects scaling of image [0,1]
---@field public originY number? origin; affects scaling of image [0,1]

---@alias g.CosmeticInfo.Type "HAT"|"BACKGROUND"|"AVATAR"

---@class g.CosmeticInfo: g.CosmeticDef
---@field public id string
---@field public type g.CosmeticInfo.Type
---@field public name string
---@field public image string
---@field public upscale integer
---@field public color objects.Color
---@field public offsetX number offset: how its positioned in pixels (e.g. hat is up)
---@field public offsetY number offset: how its positioned in pixels (e.g. hat is up)
---@field public originX number origin; affects scaling of image [0,1]
---@field public originY number origin; affects scaling of image [0,1]



---@type table<string, g.CosmeticInfo>
local COSMETIC_INFO = nil



---@param type g.CosmeticInfo.Type
---@param id string
---@param name string
---@param def g.CosmeticDef
local function defineCosmetic(type, id, name, def)
    ---@cast def g.CosmeticInfo
    def.type    = type
    def.id      = id
    def.name    = name

    def.image   = def.image   or ""
    def.upscale = def.upscale or 1
    def.color   = def.color   or objects.Color.WHITE

    def.offsetX = def.offsetX or 0
    def.offsetY = def.offsetY or 0

    def.originX = def.originX or 0.5
    def.originY = def.originY or (type == "HAT") and 1 or 0.5
    -- originY=0.5 if normal, originY=1 if HAT.

    COSMETIC_INFO[id] = def
end



-- Load the avatar cosmetics
-- TODO: Load these from Steam API instead of hardcoding.

local function ensureLoaded()
    if COSMETIC_INFO then
        return
    end

    COSMETIC_INFO = {}
    defineCosmetic("AVATAR", "cat", "Happy Cat", {
        image = "happy_cat"
    })
    defineCosmetic("AVATAR", "business_cat", "Business Cat", {})
    defineCosmetic("AVATAR", "evil_cat", "Evil Cat", {})
    defineCosmetic("AVATAR", "grass_farmer_cat", "Grass Farmer Cat", {})
    defineCosmetic("AVATAR", "lumberjack_cat", "Lumberjack Cat", {})

    defineCosmetic("BACKGROUND", "white", "White", {
        image = "1x1",
        upscale = consts.AVATAR_SIZE,
    })
    defineCosmetic("BACKGROUND", "pink", "Pink", {
        image = "1x1",
        upscale = consts.AVATAR_SIZE,
        color = objects.Color("#".."FFDF28B5")
    })

    defineCosmetic("HAT", "farmer_hat", "Farmer Hat", {
        offsetY = 6
    })
end



---@param id string cosmetic-info
---@return g.CosmeticInfo
function cosmetics.getInfo(id)
    ensureLoaded()
    helper.assert(COSMETIC_INFO[id], "cosmetic", id, "is not defined")
    return COSMETIC_INFO[id]
end


---@return string[]
function cosmetics.getUnlocked()
    ensureLoaded()
    local t = {}
    for k,_ in pairs(COSMETIC_INFO) do
        table.insert(t,k)
    end
    return t
end




---Avatar occupy 32x32 in size, with background.
---@param avatar g.Avatar
---@param x number
---@param y number
---@param scale number?
---@param drawBackground boolean?
function cosmetics.drawAvatar(avatar, x, y, scale, drawBackground)
    ensureLoaded()
    local oy = 0
    scale = scale or 1

    -- Not 100% certain if this should be in g, but we can move it later.
    if drawBackground then
        local bginfo = cosmetics.getInfo(avatar.background)
        love.graphics.setColor(bginfo.color)
        g.drawImage(bginfo.image, x, y, 0, scale * bginfo.upscale)
        -- When drawing with background, assume it's for rendering in UI
        oy = math.floor((consts.AVATAR_SIZE - 16) / 2) - 1
    end

    love.graphics.setColor(1, 1, 1)
    local catinfo = cosmetics.getInfo(avatar.avatar)
    g.drawImage(catinfo.image, x, y + oy * scale, 0, scale)

    if avatar.hat then
        local hatinfo = cosmetics.getInfo(avatar.hat)
        local s = scale * hatinfo.upscale
        love.graphics.setColor(hatinfo.color)
        -- Note: This assume cat avatar is 16x16. If not, make this configurable.
        g.drawImageOffset(
            hatinfo.image,
            x + (hatinfo.offsetX) * s,
            y + (hatinfo.offsetY + oy - 8) * s,
            0, s, s,
            hatinfo.originX,
            hatinfo.originY
        )
    end
end

---@param x number
---@param y number
---@param scale number?
---@param drawBackground boolean?
function cosmetics.drawPlayerAvatar(x, y, scale, drawBackground)
    ensureLoaded()
    return cosmetics.drawAvatar(g.getSn().avatar, x, y, scale, drawBackground)
end



return cosmetics
