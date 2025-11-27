

---@class consts
local consts = {

    DEV_MODE = not not (love.filesystem.getInfo(".git", "directory") and os.getenv("DISABLE_DEV_MODE") ~= "1"),

    FILE_LOG_LEVEL = "warn",
    CONSOLE_LOG_LEVEL = "trace",

    TARGET_TIME_PER_LEVEL_UP = 25,

    ATLAS_SIZE = 1024,

    UPGRADE_IMAGE_SIZE = 28,
    UPGRADE_GRID_SPACING = 8, -- spaced 8 units apart
    UPGRADE_CONNECTOR_WIDTH = 8,

    HARVEST_AREA_LEEWAY = 4, -- Mouse-harvest extends by this amount so it "feels good"


    DEFAULT_UPGRADE_PRICE_SCALING = 2,
    -- upgrade-price is multiplied by this amount every level (unless specified)

    DEFAULT_UPGRADE_MAX_LEVEL = 10,

    TEST = true,

    LAGGED_HEALTHBAR_DURATION = 0.3, -- the "healtbar lag" on tokens, (purely visual effect)

    WORLD_TILE_SIZE = 16, -- World tile size on both width and height.

    AVATAR_SIZE = 24, -- Size of the avatar with background
    DEFAULT_CAT_AVATAR = "cat",
    DEFAULT_BACKGROUND_AVATAR = "white"
}



return consts
