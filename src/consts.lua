

---@class consts
local consts = {

    DEV_MODE = not not (love.filesystem.getInfo(".git", "directory") and os.getenv("DISABLE_DEV_MODE") ~= "1"),
    PROFILING = false,

    ANALYTICS_URL = nil, -- URL, without trailing slash.
    -- How long it should take before sending "update" event to analytics server (in seconds)?
    ANALYTICS_UPDATE_INTERVAL = 60,
    GAME_VERSION = 0,

    FILE_LOG_LEVEL = "warn",
    CONSOLE_LOG_LEVEL = "trace",

    FILE_SEP = "/",

    DEV_UPGRADE_TREE_PATH = "trees",

    TARGET_TIME_PER_LEVEL_UP = 25,

    ATLAS_SIZE = 2048,

    MAX_PLAYING_SOURCES = 14,

    UPGRADE_IMAGE_SIZE = 28,
    UPGRADE_GRID_SPACING = 8, -- spaced 8 units apart
    UPGRADE_CONNECTOR_WIDTH = 8,

    HARVEST_AREA_LEEWAY = 4, -- Mouse-harvest extends by this amount so it "feels good"


    DEFAULT_UPGRADE_PRICE_SCALING = 1,
    -- upgrade-price is multiplied by this amount every level (unless specified)
    -- 1 => upgrade price doesnt change per level

    DEFAULT_UPGRADE_MAX_LEVEL = 10,

    MAX_HIT_DURATION = 0.125,

    BOSSFIGHT_DURATION = 4,

    TEST = true,

    LAGGED_HEALTHBAR_DURATION = 0.3, -- the "healtbar lag" on tokens, (purely visual effect)

    WORLD_TILE_SIZE = 16, -- World tile size on both width and height.

    AVATAR_SIZE = 24, -- Size of the avatar with background
    DEFAULT_CAT_AVATAR = "cat",
    DEFAULT_BACKGROUND_AVATAR = "white",
    DEFAULT_SCYTHE = "starting_scythe",

    ORBIT_RING_DISTANCE = 20, -- Radius of each orbit ring.

    -- Resource multipler on combo increase
    COMBO_MULTIPLIER = 0.01,
}



return consts
