local string_buffer = require("string.buffer")
local https = require("https")

-- IN_CHAN = This thread reads. OUT_CHAN = This thread writes.
local IN_CHAN, OUT_CHAN = ...
---@cast IN_CHAN love.Channel
---@cast OUT_CHAN love.Channel

while true do
    collectgarbage()
    collectgarbage()

    local request = IN_CHAN:demand() --[[@as string]]
    if request == "quit" then
        return
    end

    -- [1] = id, [2] = url, [3] = options
    local param = assert(string_buffer.decode(request))
    local code, body, headers = https.request(param[2], param[3] or {})

    local result = string_buffer.encode({param[1], code, body, headers})
    OUT_CHAN:push(result)
end
