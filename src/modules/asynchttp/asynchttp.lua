local string_buffer = require("string.buffer")

---@class _AsyncHTTP
local asynchttp = {}

local thread = love.thread.newThread("src/modules/asynchttp/thread.lua")
local inChan = love.thread.newChannel()
local outChan = love.thread.newChannel()
local callbacks = {}

---@param callback fun(code:integer|nil, body:string|nil, headers: table<string, string>|nil)
---@param url string
---@param options {data:string?,method:("GET"|"HEAD"|"POST"|"PUT"|"DELETE"|"PATCH")?,headers:table<string,string>?}?
function asynchttp.request(callback, url, options)
    if not thread:isRunning() then
        thread:start(inChan, outChan)
    end

    local dummy = {}
    local id = string.format("%p", dummy)
    callbacks[dummy] = true -- Ensure strong reference
    callbacks[id] = function(code, body, headers)
        callbacks[dummy] = nil -- Remove ref
        callbacks[id] = nil
        return callback(code, body, headers)
    end

    local param = string_buffer.encode({id, url, options})
    inChan:push(param)
end

function asynchttp.finish()
    if thread:isRunning() then
        inChan:push("quit")
        thread:wait()
        asynchttp.update()
    end
end

function asynchttp.update()
    prof_push("asynchttp.update")

    while true do
        local response = outChan:pop() --[[@as string|nil]]
        if not response then
            break
        end

        local restab = assert(string_buffer.decode(response))
        callbacks[restab[1]](restab[2], restab[3], restab[4])
    end

    prof_pop()
end

return asynchttp
