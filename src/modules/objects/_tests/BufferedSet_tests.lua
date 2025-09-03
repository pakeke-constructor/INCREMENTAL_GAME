

local BufferedSet = require("src.modules.objects.BufferedSet")



local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("TEST PASSED: BufferedSet " .. name)
    else
        error("FAILED " .. name .. ": " .. err)
    end
end

local function assert(condition, msg)
    if not condition then
        error(msg or "assertion failed")
    end
end

test("basic add and flush", function()
    local s = BufferedSet({"a", "b"})
    assert(s:size() == 2)
    s:addBuffered("c")
    assert(s:size() == 2)
    assert(not s:contains("c"))
    s:flush()
    assert(s:size() == 3)
    assert(s:contains("c"))
end)

test("basic remove and flush", function()
    local s = BufferedSet({"a", "b", "c"})
    s:removeBuffered("b")
    assert(s:size() == 3)
    assert(s:contains("b"))
    s:flush()
    assert(s:size() == 2)
    assert(not s:contains("b"))
end)

test("add then remove same item", function()
    local s = BufferedSet({"a"})
    s:addBuffered("b")
    s:removeBuffered("b")
    s:flush()
    assert(s:size() == 1)
    assert(not s:contains("b"))
end)

test("remove then add same item", function()
    local s = BufferedSet({"a", "b"})
    s:removeBuffered("b")
    s:addBuffered("b")
    s:flush()
    assert(s:size() == 2)
    assert(s:contains("b"))
end)

test("multiple operations", function()
    local s = BufferedSet({"a", "b"})
    s:addBuffered("c")
    s:addBuffered("d")
    s:removeBuffered("a")
    s:flush()
    assert(s:size() == 3)
    assert(not s:contains("a"))
    assert(s:contains("b"))
    assert(s:contains("c"))
    assert(s:contains("d"))
end)