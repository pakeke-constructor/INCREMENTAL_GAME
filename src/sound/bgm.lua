-- Duration which crossfade occurs.
local CROSSFADE = 1


---@class _bgm.Group: objects.Class
local BGMGroup = objects.Class("bgm.Group")

---@param bgms string[]
---@param isAmbient boolean
function BGMGroup:init(bgms, isAmbient)
    assert(#bgms > 0)
    ---@type love.Source[]
    self.sources = {}

    for _, v in ipairs(bgms) do
        self.sources[#self.sources+1] = love.audio.newSource(v, "stream", "file")
    end

    self.retainPos = isAmbient
    -- This needs to be #self.sources. If this set to 1 instead, the BGMGroup:update()
    -- will think the first song has finished playing and play the 2nd song instead.
    -- So, set it to last song index, so BGMGroup:update() will think the last song
    -- has finished, which then play the first song instead.
    self.posIndex = #self.sources
    self.fadeDirection = 1 -- 1 for fade in, -1 for fade out
    self.fadeValue = 0 -- from 0 to CROSSFADE
    self.fading = false
    self.playing = false
end

---@param dt number
---@param volume number
function BGMGroup:update(dt, volume)
    if not self.playing then
        return
    end

    -- Update fade in/out
    if self.fading then
        self.fadeValue = helper.clamp(self.fadeValue + dt * self.fadeDirection, 0, CROSSFADE)
        volume = volume * self.fadeValue / CROSSFADE

        -- Pause on fade out
        if self.fadeValue <= 0 then
            local source = self.sources[self.posIndex]
            self.playing = false
            self.fading = false

            if self.retainPos then
                source:pause()
            else
                source:stop()
                self.posIndex = #self.sources
            end
        elseif self.fadeValue >= CROSSFADE then
            self.fading = false
        end
    end

    if self.playing then
        local source = self.sources[self.posIndex]
        source:setVolume(volume)

        if not source:isPlaying() then
            if source:tell() == 0 then
                -- Source has finished playing. Play next one.
                self.posIndex = self.posIndex % #self.sources + 1
                source = self.sources[self.posIndex]
                source:setVolume(volume)
                source:play()
            else
                source:play()
            end
        end
    end
end

function BGMGroup:fadeIn()
    self.playing = true
    self.fading = true
    self.fadeDirection = 1
end

function BGMGroup:fadeOut()
    -- We don't set self.playing = true here
    -- because the fade out song may already have been faded out
    self.fading = true
    self.fadeDirection = -1
end




---@type table<integer, _bgm.Group>
local bgmGroups = {}

---@type integer|nil
local bgmTargetPriority = nil
---@type integer|nil
local bgmPrevTargetPriority = nil

---@class _bgm
local bgm = {}

---@param priority integer
---@param sources string[]
---@param isAmbient boolean?
function bgm.register(priority, sources, isAmbient)
    assert(isLoadTime(), "can only define bgm at load time")

    if bgmGroups[priority] then
        error("bgm priority already defined: "..priority)
    end

    bgmGroups[priority] = BGMGroup(sources, not not isAmbient)
end

---Needs to be called on every update loop as long as the
---music needs to be played
---@param priority integer
function bgm.request(priority)
    if not bgmGroups[priority] then
        error("undefined bgm priority: "..priority)
    end

    if not bgmTargetPriority then
        bgmTargetPriority = priority
    else
        bgmTargetPriority = math.max(bgmTargetPriority, priority)
    end
end

---@param dt number
---@param volume number
function bgm.update(dt, volume)
    for _, group in pairs(bgmGroups) do
        group:update(dt, volume)
    end

    -- Compare previous priority with new priority
    if bgmTargetPriority ~= bgmPrevTargetPriority then
        if bgmPrevTargetPriority then
            bgmGroups[bgmPrevTargetPriority]:fadeOut()
        end

        if bgmTargetPriority then
            bgmGroups[bgmTargetPriority]:fadeIn()
        end
    end

    -- Swap pool and clear next pool
    bgmTargetPriority, bgmPrevTargetPriority = bgmPrevTargetPriority, bgmTargetPriority
    bgmTargetPriority = nil
end

return bgm
