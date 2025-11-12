
local n9p = require(".n9p")


local n9slice = {}


---@alias n9slice.StretchType
--- Scale to fit.
---| "stretch"
--- Tile to fit (don't scale).
---| "repeat"



---@class n9slice.Args
---@field public image love.Texture
---@field public padding number[]|number
---@field public quad? love.Quad
---@field public stretchType? n9slice.StretchType



---@param args n9slice.Args
function n9slice.new(args)
    local shouldTile = args.stretchType == "repeat"
    local tW, tH = args.image:getDimensions()

    local subX, subY, subW, subH = 0, 0, tW, tH
    if args.quad then
        subX, subY, subW, subH = args.quad:getViewport()
    end

    local padLeft, padTop, padRight, padBottom
    assert(args.padding, "missing padding")
    if type(args.padding) == "number" then
        padLeft = args.padding
        padTop = args.padding
        padRight = args.padding
        padBottom = args.padding
    else
        if #args.padding == 1 then
            padLeft = args.padding[1]
            padTop = args.padding[1]
            padRight = args.padding[1]
            padBottom = args.padding[1]
        elseif #args.padding == 2 then
            padLeft, padRight = args.padding[1], args.padding[1]
            padTop, padBottom = args.padding[2], args.padding[2]
        elseif #args.padding >= 4 then
            padLeft = args.padding[1]
            padTop = args.padding[2]
            padRight = args.padding[3]
            padBottom = args.padding[4]
        else
            error("invalid number of padding arguments")
        end
    end

    local startX = subX + padLeft
    local startY = subY + padTop
    local endX = subX + subW - padRight
    local endY = subY + subH - padBottom

    local obj = n9p.newBuilder()
        :addHorizontalSlice(startX, endX, shouldTile)
        :addVerticalSlice(startY, endY, shouldTile)
        :setHorizontalPadding(startX, endX)
        :setVerticalPadding(startY, endY)
        :build(tW, tH, subX, subY, subW, subH)

    obj:setTexture(args.image)
    return obj
end


return n9slice
