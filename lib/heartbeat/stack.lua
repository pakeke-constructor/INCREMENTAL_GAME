local stack = {}
stack.__index = stack

function stack.new()
    return setmetatable({
        n = 0
    }, stack)
end

function stack:push(val)
    self.n = self.n + 1
    self[self.n] = val
end

function stack:pop()
    if (self.n == 0) then return nil end
    local val = self[self.n]
    self[self.n] = nil
    self.n = self.n - 1
    return val
end

function stack:peek()
    return self[self.n]
end

function stack:isEmpty()
    return self.n == 0
end

return stack