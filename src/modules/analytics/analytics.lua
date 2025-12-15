local asynchttp = require("src.modules.asynchttp.asynchttp")
local sceneManager = require("src.scenes.sceneManager")

---@class _Analytics
local analytics = {}

local MAX_ERROR_RETRIES = 10

local function makeRandomValue()
    local result = {}
    local seed = string.format("%p", {})

    for i = 1, 32 do
        local b = love.math.random(0, 255)
        local seedidx = (i - 1) % #seed + 1
        local x = seed:byte(seedidx, seedidx)
        result[#result+1] = string.char(bit.bxor(b, x))
    end

    return table.concat(result)
end

local steamId = nil
-- Random value has to be persistent only across game instances
local randomValue = love.data.encode("string", "base64", makeRandomValue()) --[[@as string]]
local tokenData = {
    token = "",
    expiry = 0,
}
local disableAnalytics = false
local hasRequestRunning = false
local errorRetries = 0

if not consts.ANALYTICS_URL then
    log.info("Analytics URL not set. Skipping Analytics init.")
    disableAnalytics = true
end


---@alias _Analytics.EventType "start"|"upgrade"|"update"|"end"

---@class _Analytics.SendData
---@field public event _Analytics.EventType
---@field public playtime integer
---@field public timestamp integer
---@field public game_version integer
---@field public scene string
---@field public save table

---@type _Analytics.SendData[]
local queuedSendData = {}

local function disableAnalyticsSystem()
    queuedSendData = {}
    disableAnalytics = true
end

---@param body string?
---@return boolean @Can retry?
local function errorHandler(body)
    errorRetries = errorRetries + 1
    log.error("Analytics error: "..tostring(body))

    if errorRetries >= MAX_ERROR_RETRIES then
        log.error("Analytics error after retrying "..MAX_ERROR_RETRIES.." times")
        disableAnalyticsSystem()
        return false
    else
        -- Retry
        return true
    end
end

local sendAll
local function auth()
    assert(steamId)
    assert(consts.ANALYTICS_URL)
    if disableAnalytics then
        return
    end

    hasRequestRunning = true

    asynchttp.request(function(code, body)
        local success = false
        local jsonbody = ""
        hasRequestRunning = false

        if (code == 200 or code == 201) and body then
            success, jsonbody = pcall(json.decode, body)

            if success then
                if jsonbody.token and jsonbody.expire then
                    tokenData.token = tostring(jsonbody.token)
                    -- response.expire is a countdown, so it only returns something like 3600
                    tokenData.expiry = jsonbody.expire + love.timer.getTime() - 60
                    errorRetries = 0

                    -- Start sendImpl main loop
                    if #queuedSendData > 0 then
                        sendAll()
                    end

                    return
                end

                success = false
                jsonbody = "got invalid response" -- error message
            end
        end

        if not success then
            log.error("Analytics error: "..tostring(jsonbody))
            disableAnalyticsSystem()
        elseif code and (code ~= 0 and math.floor(code / 100) ~= 2) then
            log.error("Analytics error with code "..code..": "..tostring(body))
            disableAnalyticsSystem()
        elseif code == 0 or code == nil then
            if errorHandler(body) then
                -- Retry
                return auth()
            end
        end
    end, consts.ANALYTICS_URL.."/auth", {
        headers = {
            ["Content-Type"] = "application/json"
        },
        data = json.encode({
            steam_id = steamId,
            random_value = randomValue,
            os = love.system.getOS(),
            os_version = "0.0",
        })
    })
end

function sendAll()
    if love.timer.getTime() >= tokenData.expiry then
        -- Token expired. Re-authenticate.
        return auth()
    end

    hasRequestRunning = true
    local tempQueuedSendData = queuedSendData
    -- Make sure to create new temporary queue for this in case data is added
    -- while analytics is being send.
    queuedSendData = {}

    asynchttp.request(function(code, body)
        hasRequestRunning = false

        if code == 200 then
            -- Good. Perform another re-send if any
            errorRetries = 0
            if #queuedSendData > 0 then
                return sendAll()
            end
        else
            -- Revert queuedSendData to tempQueuedSendData and append whatever
            -- data on queuedSendData to tempQueuedSendData
            table.move(queuedSendData, 1, #queuedSendData, #tempQueuedSendData, tempQueuedSendData)
            queuedSendData = tempQueuedSendData

            if code and math.floor(code / 100) == 4 then
                -- Token invalid. Need to re-auth.
                tokenData.expiry = 0
                errorRetries = 0
                return auth()
            -- Treat redirect as server error, as asynchttp is supposed to handle redirects.
            elseif code and (code ~= 0 and math.floor(code / 100) ~= 2) then
                -- Server error.
                log.error("Analytics error with code "..code..": "..tostring(body))
                disableAnalyticsSystem()
            elseif code == 0 or code == nil then
                if errorHandler(body) then
                    -- Retry
                    return sendAll()
                end
            end
        end
    end, consts.ANALYTICS_URL.."/send", {
        headers = {
            ["Content-Type"] = "application/json",
            ["X-Session-Token"] = tokenData.token,
        },
        data = json.encode(tempQueuedSendData)
    })
end




---@param steamid string?
function analytics.init(steamid)
    if not consts.ANALYTICS_URL then return end

    steamId = steamid
    if not steamid then
        log.info("Analytics has been explicitly disabled.")
        disableAnalytics = true
        return
    end
    auth()
end

---@param event _Analytics.EventType
function analytics.send(event)
    if disableAnalytics then return end
    if not g.hasSession() then return end
    assert(steamId, "forgot to call analytics.init()?")

    local sn = g.getSn()
    local _, scname = sceneManager.getCurrentScene()
    queuedSendData[#queuedSendData+1] = {
        event = event,
        playtime = math.floor(sn.playtime),
        timestamp = os.time(),
        game_version = consts.GAME_VERSION,
        scene = scname or "",
        save = sn:serialize()
    }

    if not hasRequestRunning then
        sendAll()
    end
end

return analytics
