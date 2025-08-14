


local function assertTablesEqual(expected, actual, message)
    message = message or "Assertion failed"
    assert(type(expected) == "table")
    assert(type(actual) == "table")

    for key, expectedValue in pairs(expected) do
        if actual[key] ~= expectedValue then
            error(message .. ": key '" .. key .. "' expected " .. tostring(expectedValue) .. ", got " .. tostring(actual[key]))
        end
    end

    for key, actualValue in pairs(actual) do
        if expected[key] == nil then
            error(message .. ": unexpected key '" .. key .. "' with value " .. tostring(actualValue))
        end
    end
end


local World = require(".World")
local Attachment = require(".Attachment")
local Object = require(".Object")



fg.defineEvent("testEvent")
fg.defineQuestion("testQuestion", function (a, b)
    return a+b
end, 0)





local TestAttachment = Attachment()
do
function TestAttachment:init(value, id)
    self.value = value
    self.id = id
end

function TestAttachment:testEvent()
    self.value = self.value + 1
end

function TestAttachment:testQuestion()
    return self.value
end
end



--[[

-- testing basic attachment functionality
do
w:defineEntity("attachment_test_ent", {})

local e = w:newEntity("attachment_test_ent", 0, 0)
local atc = TestAttachment(5)

e:attach(atc)
assert(atc.ent == e)

w:call("testEvent", e)
assert(atc.value == 6)

assert(w:ask("testQuestion", e) == 6)

e:detach(atc)
assert(atc.ent == nil)

end


-- testing attachment with ID
do
local e = w:newEntity("attachment_test_ent", 0, 0)
local atc1 = TestAttachment(10, "test")
local atc2 = TestAttachment(20, "test")

e:attach(atc1)
assert(e:getAttachmentById("test") == atc1)

-- Should replace first attachment
e:attach(atc2)
assert(e:getAttachmentById("test") == atc2)
assert(atc1.ent == nil)
end


-- testing multiple attachments
do
local e = w:newEntity("attachment_test_ent", 0, 0)
local atc1 = TestAttachment(5)
local atc2 = TestAttachment(10)

e:attach(atc1)
e:attach(atc2)

w:call("testEvent", e)
assert(atc1.value == 6 and atc2.value == 11)
assert(w:ask("testQuestion", e) == 17) -- 6 + 11
end


]]



print("===============")
print("ES TESTS PASSED")
print("===============")

