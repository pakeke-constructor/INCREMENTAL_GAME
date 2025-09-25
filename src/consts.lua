

---@class consts
local consts = {

    DEV_MODE = not not love.filesystem.getInfo(".git", "directory"),

    FILE_LOG_LEVEL = "warn",
    CONSOLE_LOG_LEVEL = "trace",

    ATLAS_SIZE = 4096,

    UPGRADE_IMAGE_SIZE = 24,
    UPGRADE_GRID_SPACING = 8, -- spaced 8 units apart

    HARVEST_AREA_LEEWAY = 4, -- harvest area extends by this amount so it "feels good"

    TEST = true
}



return consts
