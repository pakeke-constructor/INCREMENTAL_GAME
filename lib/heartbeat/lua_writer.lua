local luaWriter = {}
local requirePath = (...):match("(.-)[^%.]+$")
local mp = require(requirePath.."messagepack")

function luaWriter:StartFile(path)
    self.path = path and path .. ".lua" or "capture.lua"
    love.filesystem.write(self.path, "")
end

function luaWriter:AppendFile(data)
  local payload = mp.pack(data)
  local header  = love.data.pack("string", ">I4", #payload) -- 4-byte big-endian length

  local f = assert(love.filesystem.openFile(self.path, "a"))
  assert(f:write(header))
  assert(f:write(payload))
  f:close()

  return payload
end

return luaWriter