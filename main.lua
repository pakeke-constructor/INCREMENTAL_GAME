
local love = require("love")


-- relative-require
do
local stack = {""}
local oldRequire = require
local function stackRequire(path)
    table.insert(stack, path)
    local result = oldRequire(path)
    table.remove(stack)
    return result
end


--[[
we *MUST* overwrite `require` here,
or else the stack will become malformed.
]]
function _G.require(path)
    if (path:sub(1,1) == ".") then
        -- its a relative-require!
        local lastPath = stack[#stack]
        if lastPath:find("%.") then -- then its a valid path1
            local subpath = lastPath:gsub('%.[^%.]+$', '')
            return stackRequire(subpath .. path)
        else
            -- we are in root-folder; remove the dot and require
            return stackRequire(path:sub(2))
        end
    else
        return stackRequire(path)
    end
end

end




love.graphics.setDefaultFilter("nearest", "nearest")

-- todo: set a better font here
love.graphics.setFont(love.graphics.newFont(64))

local font = love.graphics.getFont()
-- font:setFilter("nearest", "nearest")

--[[
=========
GLOBALS START
=========
]]
_G.utf8 = require("utf8")
_G.table.clear = require("table.clear")

---@param x number
---@param y number
---@return number
function _G.math.distance(x,y)
    return (x*x + y*y)^0.5
end

_G.json = require("lib.json")
_G.consts = require("src.consts")

local AutoAtlas = require("lib.AutoAtlas.AutoAtlas")
_G.atlas = AutoAtlas(consts.ATLAS_SIZE, consts.ATLAS_SIZE)

_G.inspect = require("lib.inspect.inspect")


_G.log = require("src.modules.log")

---@diagnostic disable-next-line
_G.typecheck = require("src.modules.typecheck.typecheck")

_G.objects = require("src.modules.objects.objects")

_G.helper = require("src.modules.helper.helper")

_G.richtext = require("src.modules.richtext.exports")

_G.localization = require("src.modules.localization")
_G.loc = _G.localization.localize
_G.interp = _G.localization.newInterpolator


_G.Kirigami = require("lib.kirigami")
_G.iml = require("lib.iml.iml")

_G.ui = require("src.ui.ui")

_G.g = require("src.g")

_G.worldutil = require("src.world.worldutil")
--[[
=========
GLOBALS END
=========
]]


setmetatable(_G, {
    __newindex = function (t,k)
        error("no new globals! " .. tostring(k))
    end,
    __index = function (t, k)
        error("dont access undefined vars! " .. tostring(k))
    end
})


local vignette = require("src.modules.vignette.vignette")
vignette.setStrength(0.35)

require("src.ev_q_definitions")


local simulation = require("src.world.simulation")






--[[
============================================================
TESTS
============================================================
]]

if consts.TEST then
    require("src.modules.objects._tests.BufferedSet_tests")

    require("src.modules.objects._tests.Partition_tests")
end

--[[
TESTS END
]]




local sceneManager = require("src.scenes.sceneManager")

function love.load(arg)
    assert(love.filesystem.createDirectory("saves"))
    love.graphics.setLineStyle("rough")
    g.requireFolder("src/upgrades")
    g.requireFolder("src/entities")

    local shouldLoad = not (consts.DEV_MODE and love.keyboard.isDown("lshift", "rshift"))
    if shouldLoad and love.filesystem.getInfo("saves/save1.json", "file") and arg[1] ~= "--simulate" then
        g.loadSession("saves/save1.json")
    else
        g.newSession()
    end

    if arg[1] == "--simulate" then
        local upg = assert(arg[2], "missing upgrade")
        local dur = assert(tonumber(arg[3]), "invalid simulation duration")
        simulation.setup(upg, dur)
    end

    if simulation.targetUpgrade then
        sceneManager.gotoScene("harvest_scene")
    else
        sceneManager.gotoScene("map_scene")
    end
end

function love.quit()
    local shouldSave = not (consts.DEV_MODE and love.keyboard.isDown("lshift", "rshift"))
    if shouldSave and g.getSn() and not simulation.targetUpgrade then
        local data = g.getSn():serialize()
        local contents = json.encode(data)
        assert(love.filesystem.write("saves/save1.json", contents))
    end
end


function love.update(dt)
    iml.setPointer(love.mouse.getPosition())
    g.getSn():_update(dt)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.update then
        sc:update(dt)
    end
end

function love.draw()
    local sc = sceneManager.getCurrentScene()
    if sc and sc.draw then
        iml.beginFrame()
        sc:draw()
        iml.endFrame()
    end
end


function love.mousepressed(mx, my, button, istouch, presses)
    iml.mousepressed(mx, my, button, istouch, presses)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousepressed then
        sc:mousepressed(mx, my, button, istouch, presses)
    end
end

function love.mousereleased(mx, my, button, istouch)
    iml.mousereleased(mx, my, button, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousereleased then
        sc:mousereleased(mx, my, button, istouch)
    end
end

function love.mousemoved(mx, my, dx, dy, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousemoved then
        sc:mousemoved(mx, my, dx, dy, istouch)
    end
end

function love.keypressed(key, scancode, isrep)
    iml.keyreleased(key, scancode, isrep)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keypressed then
        sc:keypressed(key, scancode, isrep)
    end
end

function love.keyreleased(key, scancode)
    iml.keyreleased(key, scancode)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keyreleased then
        sc:keyreleased(key, scancode)
    end
end

function love.textinput(text)
    iml.textinput(text)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.textinput then
        sc:textinput(text)
    end
end

function love.wheelmoved(dx, dy)
    iml.wheelmoved(dx,dy)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.wheelmoved then
        sc:wheelmoved(dx, dy)
    end
end

function love.resize(w, h)
    vignette.resize()
    local sc = sceneManager.getCurrentScene()
    if sc and sc.resize then
        sc:resize(w, h)
    end
end