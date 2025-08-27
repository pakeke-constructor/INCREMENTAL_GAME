


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

_G.json = require("lib.json")
_G.consts = require("src.consts")

local AutoAtlas = require("lib.AutoAtlas.AutoAtlas")
_G.atlas = AutoAtlas(consts.ATLAS_SIZE, consts.ATLAS_SIZE)

_G.inspect = require("lib.inspect.inspect")


_G.log = require("src.modules.log")

---@diagnostic disable-next-line
_G.typecheck = require("src.modules.typecheck.typecheck")

_G.objects = require("src.modules.objects.objects")

_G.richtext = require("src.modules.richtext.exports")

_G.localization = require("src.modules.localization")


_G.Kirigami = require("lib.kirigami")
_G.iml = require("lib.iml.iml")

_G.ui = require("src.modules.ui.ui")

_G.g = require("src.g")
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


if consts.TEST then
    require("src.modules.ecs._tests")
end

require("src.ev_q_definitions")





local sceneManager = require("src.scenes.sceneManager")

function love.load()
    sceneManager.gotoScene("map_scene")
end


function love.update(dt)
    iml.setPointer(love.mouse.getPosition())
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
    local sc = sceneManager.getCurrentScene()
    if sc and sc.resize then
        sc:resize(w, h)
    end
end