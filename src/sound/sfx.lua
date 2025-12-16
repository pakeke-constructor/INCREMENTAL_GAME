

local MAX_SOURCE_POOL = 4

local MAX_SOUNDS_PER_FRAME = 10


---@class _sfx
local sfx = {}

local sfxVolume = 100
---@type table<string, love.Source[]>
local sourcePool = {} -- first source always the one to clone

---@type table<string, boolean?>
local hadPlayedThisFrame = {}
local numSoundsPlayedThisFrame = 0

---@param vol integer
function sfx.setVolume(vol)
    sfxVolume = helper.clamp(math.floor(vol + 0.5), 0, 100)
end

---@param name string
---@param path string
function sfx.defineSound(name, path)
    local mainSource = love.audio.newSource(path, "static")
    sourcePool[name] = {mainSource}
end


function sfx.update()
    numSoundsPlayedThisFrame = 0
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

---@param soundname string
---@param pitch number?
---@param volume number?
---@param pitchVar number?
---@param volumeVar number?
function sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
    if g.isBeingSimulated() then
        return false
    end

    if numSoundsPlayedThisFrame > MAX_SOUNDS_PER_FRAME then
        return
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
    numSoundsPlayedThisFrame = numSoundsPlayedThisFrame + 1
    return true
end

return sfx
