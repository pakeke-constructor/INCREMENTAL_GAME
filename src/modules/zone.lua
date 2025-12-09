----------------------------------------------------------------------------
-- LuaJIT profiler zones.
--
-- Copyright (C) 2005-2025 Mike Pall. All rights reserved.
-- Copyright (C) 2025 Miku AuahDark.
-- Released under the MIT license. See Copyright Notice in luajit.h
----------------------------------------------------------------------------
--
-- This module implements a simple hierarchical zone model.
--
-- Example usage:
--
--   local zone = require("jit.zone")
--   zone("AI")
--   ...
--     zone("A*")
--     ...
--     print(zone:get()) --> "A*"
--     ...
--     zone()
--   ...
--   print(zone:get()) --> "AI"
--   ...
--   zone()
--
----------------------------------------------------------------------------

local remove = table.remove

---@param name string?
local function heartbeatZone(name)
end

if consts.PROFILING then
  local heartbeat = require("lib.heartbeat.heartbeat")
  ---@param name string?
  function heartbeatZone(name)
    if name then
      return heartbeat:PushNamedScope(name)
    else
      return heartbeat:PopScope()
    end
  end
end

local z = setmetatable({
  flush = function(t)
    for i=#t,1,-1 do t[i] = nil end
  end,
  get = function(t)
    return t[#t]
  end
}, {
  __call = function(t, zone)
    -- Yeah this tracking is essentially MSOT, but we want this zone function to work
    -- even without Heartbeat being loaded. Whereas if we SSOT, then we need Heartbeat
    -- loaded at all times.
    heartbeatZone(zone)
    if zone then
      t[#t+1] = zone
    else
      return (assert(remove(t), "empty zone stack"))
    end
  end
})

if false then
  ---@param name string?
  ---@diagnostic disable-next-line: cast-local-type
  function z(name) end
end

return z
