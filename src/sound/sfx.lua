local sceneManager = require("src.scenes.sceneManager")
local simulation = require("src.world.simulation")


local MAX_SOURCE_POOL = 4
local VALID_EXTENSIONS = {
    wav = true,
    mp3 = true,
    ogg = true,
    flac = true
}


---@class _sfx
local sfx = {}

local sfxVolume = 100
---@type table<string, love.Source[]>
local sourcePool = {} -- first source always the one to clone
---@type table<string, boolean?>
local hadPlayedThisFrame = {}

function sfx.getVolume()
    return sfxVolume
end

---@param vol integer
function sfx.setVolume(vol)
    sfxVolume = helper.clamp(math.floor(vol + 0.5), 0, 100)
end

function sfx.defineSound(path)
    local pathrev = path:reverse()
    local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

    if VALID_EXTENSIONS[ext] then
        local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

        if #basename > 0 then
            local name = basename:sub(1, -#ext - 2)
            local mainSource = love.audio.newSource(path, "static")
            sourcePool[name] = {mainSource}
        end
    end
end

function sfx.updateState()
    table.clear(hadPlayedThisFrame)
end


---@param name string
local function getSourceFromPool(name)
    local sources = sourcePool[name]
    if not sources then
        error("invalid sound '"..name.."'")
    end

    -- Linear search won't be expensive as long as source pool is low
    for _, s in ipairs(sources) do
        if not s:isPlaying() then
            s:stop()
            return s
        end
    end

    if #sources < MAX_SOURCE_POOL then
        -- first source always the one to clone
        local s = sources[1]:clone()
        sources[#sources+1] = s
        s:stop()
        return s
    end

    return nil
end

---@param scene string|nil Only play if scene is equal to this (or nil to always play)
---@param soundname string
---@param pitch number?
---@param volume number?
---@param pitchVar number?
---@param volumeVar number?
function sfx.play(scene, soundname, pitch, volume, pitchVar, volumeVar)
    if simulation.isSimulating() then
        return false
    end

    if scene and select(2, sceneManager.getCurrentScene()) ~= scene then
        return false
    end

    if hadPlayedThisFrame[soundname] then
        return false
    end

    local s = getSourceFromPool(soundname)
    if not s then
        return false
    end

    local dv = (volumeVar or 0) * (love.math.random()-0.5)*2
    local dp = (pitchVar or 0) * (love.math.random()-0.5)*2

    pitch = (pitch or 1) + dp
    volume = math.max((volume or 1) + dv, 0) * (sfxVolume / 100)
    if pitch <= 0 then
        error("invalid pitch "..pitch)
    end

    s:setPitch(pitch)
    s:setVolume(volume)
    s:play()
    hadPlayedThisFrame[soundname] = true
    return true
end

return sfx
