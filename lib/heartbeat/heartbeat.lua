local requirePath = (...):match("(.-)[^%.]+$")
local Stack = require(requirePath.."stack")
local LuaWriter = require(requirePath.."lua_writer")
local heartbeat = {}

heartbeat.stack = Stack.new()

-- scopes
function heartbeat:PushNamedScope(name)
    if (not self.captureActive) then
        return
    end

    local stats = love.graphics.getStats()
    local newScope = {}

    newScope.name = name
    newScope.parentName = (self.stack:peek() ~= nil) and self.stack:peek().name or nil
    newScope.startGCMemory = collectgarbage("count") / 1024 
    newScope.startTime = love.timer.getTime()
    newScope.startTextureMemory = stats.texturememory / (1024 * 1024)
    self.stack:push(newScope)
end

heartbeat.completedScopes = {}
function heartbeat:PopScope()
    if (not self.captureActive) then
        return
    end

    local stats = love.graphics.getStats()
    local scope = self.stack:pop()
    
    if (scope) then
        scope.endTime = love.timer.getTime()
        scope.endGCMemory = collectgarbage("count") / 1024
        scope.endTextureMemory = stats.texturememory / (1024 * 1024)
        table.insert(self.completedScopes, scope)
    end
end

heartbeat.captureActive = false
function heartbeat:StartCapture()
    self.captureActive = true
    LuaWriter:StartFile("capture")
end

function heartbeat:HeartbeatStart()
    if (not self.captureActive) then
        return
    end
    
    if (debug.getinfo(2, "n").name ~= "update") then
        print("HEARTBEAT - Error in heartbeat:Heartbeat: caller function is not love.update. Please only call this function at the start of love.update")
        return
    end

    self:PushNamedScope("Heartbeat")
end

-- frames
function heartbeat:HeartbeatEnd()
    if (not self.captureActive) then
        return
    end

    if (debug.getinfo(2, "n").name ~= "draw") then
        print("HEARTBEAT - Error in heartbeat:HeartbeatEnd: caller function is not love.draw. Please only call this function at the end of love.draw")
        return
    end

    self:PopScope()

    local stats = love.graphics.getStats()

    local frame = {}
    frame.FPS = love.timer.getFPS()
    frame.drawCalls = stats.drawcalls
    frame.drawCallsBatched = stats.drawCallsBatched
    frame.textureMemory = stats.texturememory / (1024 * 1024)
    frame.gcMemory = collectgarbage("count") / 1024
    
    local outData = {
        frame = frame,
        scopes = self.completedScopes
    }
    self.completedScopes = {}

    LuaWriter:AppendFile(outData)
end

return heartbeat