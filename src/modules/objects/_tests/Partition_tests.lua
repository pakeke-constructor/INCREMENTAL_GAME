
local Partition = require("src.modules.objects.Partition")


local function test_basic()
    local p = Partition(10)
    local obj = {id = 1}
    p:add(obj, 5, 5)
    local found = {}
    p:query(5, 5, function(o) table.insert(found, o) end)
    assert(#found == 1)
    assert(found[1] == obj)
end

local function test_multiple_objects()
    local p = Partition(10)
    local obj1 = {id = 1}
    local obj2 = {id = 2}
    p:add(obj1, 5, 5)
    p:add(obj2, 7, 8)
    local found = {}
    p:query(5, 5, function(o) table.insert(found, o) end)
    assert(#found == 2)
end

local function test_neighboring_bins()
    local p = Partition(10)
    local obj = {id = 1}
    p:add(obj, 11, 11)
    local found = {}
    p:query(9, 9, function(o) table.insert(found, o) end)
    assert(#found == 1)
end

local function test_clear()
    local p = Partition(10)
    local obj = {id = 1}
    p:add(obj, 5, 5)
    p:clear()
    local found = {}
    p:query(5, 5, function(o) table.insert(found, o) end)
    assert(#found == 0)
end

local function test_negative_coords()
    local p = Partition(10)
    local obj = {id = 1}
    p:add(obj, -5, -5)
    local found = {}
    p:query(-5, -5, function(o) table.insert(found, o) end)
    assert(#found == 1)
    assert(found[1] == obj)
end

local function test_edge_case()
    local p = Partition(10)
    local obj1 = {id = 1}
    local obj2 = {id = 2}
    p:add(obj1, 9.9, 9.9)
    p:add(obj2, 10.1, 10.1)
    local found = {}
    p:query(10, 10, function(o) table.insert(found, o) end)
    assert(#found == 2)
end

test_basic()
test_multiple_objects()
test_neighboring_bins()
test_clear()
test_negative_coords()
test_edge_case()

print("TEST PASSED: Partition tests!")

