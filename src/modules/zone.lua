local push, pop
local i = 0

if consts.PROFILING then
    local heartbeat = require("lib.heartbeat.heartbeat")

    ---@param name string
    function push(name)
        i = i + 1
        return heartbeat:PushNamedScope(name)
    end

    function pop()
        assert(i > 0, "more pops than pushes")
        i = i - 1
        return heartbeat:PopScope()
    end
else
    ---@param name string
    function push(name)
        i = i + 1
    end

    function pop()
        assert(i > 0, "more pops than pushes")
        i = i - 1
    end
end

return {
    push = push,
    pop = pop,
    count = function() return i end
}
