

---@class consts
local consts = {

    DEV_MODE = not not (love.filesystem.getInfo(".git", "directory") and os.getenv("DISABLE_DEV_MODE") ~= "1"),

    FILE_LOG_LEVEL = "warn",
    CONSOLE_LOG_LEVEL = "trace",

    ATLAS_SIZE = 4096,

    UPGRADE_IMAGE_SIZE = 24,
    UPGRADE_GRID_SPACING = 8, -- spaced 8 units apart

    HARVEST_AREA_LEEWAY = 4, -- harvest area extends by this amount so it "feels good"

    DEFAULT_UPGRADE_PRICE_SCALING = 1.4,
    -- upgrade-price is multiplied by this amount every level (unless specified)

    TEST = true
}



return consts
