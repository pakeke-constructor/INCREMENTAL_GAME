
local love = require("love")

local heartbeat = nil


---@type love.graphics
_G.lg=love.graphics


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





-- todo: set a better font here
love.graphics.setFont(love.graphics.newFont(64))


--[[
=========
GLOBALS START
=========
]]
_G.utf8 = require("utf8")

_G.table.clear = require("table.clear")
_G.table.new = require("table.new")


local _isloadtime = true
function _G.isLoadTime()
    return _isloadtime
end


_G.json = require("lib.json")
_G.consts = require("src.consts")

if consts.DEV_MODE then
    love.keyboard.setTextInput(true)
end


-- Profiler zones
local profilerStackCount = 0
if consts.PROFILING then
    heartbeat = require("lib.heartbeat.heartbeat")

    ---@param name string
    function _G.prof_push(name)
        profilerStackCount = profilerStackCount + 1
        return heartbeat:PushNamedScope(name)
    end

    function _G.prof_pop()
        assert(profilerStackCount > 0, "more pops than pushes")
        profilerStackCount = profilerStackCount - 1
        return heartbeat:PopScope()
    end
else
    ---@param name string
    function _G.prof_push(name)
        profilerStackCount = profilerStackCount + 1
    end

    function _G.prof_pop()
        assert(profilerStackCount > 0, "more pops than pushes")
        profilerStackCount = profilerStackCount - 1
    end
end

local AutoAtlas = require("lib.AutoAtlas.AutoAtlas")
_G.atlas = AutoAtlas(consts.ATLAS_SIZE, consts.ATLAS_SIZE)

_G.inspect = require("lib.inspect.inspect")


_G.log = require("src.modules.log")

---@diagnostic disable-next-line
_G.typecheck = require("src.modules.typecheck.typecheck")

_G.objects = require("src.modules.objects.objects")

_G.godrays = require("src.modules.godrays.godrays")

_G.helper = require("src.modules.helper.helper")

_G.settings = require("src.settings")

_G.richtext = require("src.modules.richtext.exports")

_G.localization = require("src.modules.localization")
_G.loc = _G.localization.localize
_G.interp = _G.localization.newInterpolator
local loadLoc = require("src.load_loc")
_G.getLanguageList = loadLoc.getLanguages


_G.Kirigami = require("lib.kirigami")
_G.iml = require("lib.iml.iml")

_G.ui = require("src.ui.ui")

_G.Steam = require("src.modules.steam.steam")

_G.g = require("src.g")

_G.worldutil = require("src.world.worldutil")

_G.analytics = require("src.modules.analytics.analytics")
_G.achievements = require("src.achievements.achievements")
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


local crt = require("src.modules.crt")
local vignette = require("src.modules.vignette.vignette")
vignette.setStrength(consts.VIGNETTE_STRENGTH)
local subpixel = require("src.modules.subpixel")

require("src.ev_q_definitions")


local simulation = require("src.world.simulation")
local asynchttp = require("src.modules.asynchttp.asynchttp")



local CONSIDERED_IDLE_TIME = 10 -- 10 seconds
local idleTime = 0 -- if this reaches at least `CONSIDERED_IDLE_TIME`, increase `idletime` in session.


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
local cosmetics = require("src.cosmetics.cosmetics")
local SteamTicket = require("src.steam.ticket")
local SteamInventory = require("src.steam.inventory")
local User = require("src.user")
local bgm = require("src.sound.bgm")
local sfx = require("src.sound.sfx")
local emulation = nil

if consts.DEV_MODE then
    emulation = require("src.emulation")
    emulation.init()
end

function love.load(arg)
    log.debug(love.graphics.getRendererInfo())
    assert(love.filesystem.createDirectory("saves"))
    love.graphics.setLineStyle("rough")
    g.requireFolder("src/upgrades")
    g.requireFolder("src/entities")
    g.requireFolder("src/effects")
    g.requireFolder("src/bosses")
    g.requireFolder("src/scythes")
    sceneManager.loadScenes()

    if arg[1] == "--simulate" then
        analytics.init(nil) -- Explicitly disable analytics
        local sn = g.newSession()
        sn.tree = g.loadPrestigeTree(0)

        -- Begin simulation
        local strategy = assert(arg[2], "missing strategy: [cheapest, random]"):lower()
        local duration = assert(tonumber(arg[3]), "invalid duration")
        simulation.start({duration = duration, buyStrategy = strategy})
    end

    if simulation.isSimulating() then
        sceneManager.gotoScene("harvest_scene")
    else
        local steamid = nil
        if Steam.init() then
            local luasteam = assert(Steam.getSteam())
            steamid = tostring(luasteam.user.getSteamID())
        end

        analytics.init(steamid)
        sceneManager.gotoScene("title_scene")
    end

    if consts.TEST then
        for _, uid in ipairs(g.UPGRADE_LIST) do
            local uinfo = assert(g.getUpgradeInfo(uid))
            local needs = uinfo.procGen and uinfo.procGen.needs
            if needs then assert(g.isValidUpgrade(needs), "procGen.needs dependency invalid: "..tostring(uid) .. " " .. tostring(needs)) end
        end
    end

    _isloadtime = false

    love.window.setFullscreen(settings.isFullscreen())
    SteamInventory.init()
    SteamTicket.init()
    User.init()
    cosmetics.init()

    if heartbeat then
        heartbeat:StartCapture()
    end
end

function love.quit()
    log.info("love.quit begin...")
    if consts.DEV_MODE then
        loadLoc.dump()
    end

    settings.save()
    g.saveAndInvalidateSession()
    asynchttp.finish()
    Steam.shutdown()
    log.info("love.quit done.")
end


function love.update(dt)
    collectgarbage()
    if emulation then
        emulation.update(dt)
    end

    if heartbeat then
        heartbeat:HeartbeatStart()
    end

    prof_push("love.update")

    asynchttp.update()
    local luasteam = Steam.getSteam()
    if luasteam then
        luasteam.runCallbacks()
    end
    achievements.update()
    sfx.update()
    bgm.update(dt, settings.getBGMVolume() / 100)
    iml.setPointer(love.mouse.getPosition())

    if simulation.isSimulating() then
        if simulation.update() then
            g.gotoScene("simulation_result_scene")
        end
    elseif g.hasSession() then
        local session = g.getSn()
        session:_update(dt)
        if idleTime >= CONSIDERED_IDLE_TIME then
            session.idletime = session.idletime + dt
        end
        idleTime = idleTime + dt
    end

    local sc, scname = sceneManager.getCurrentScene()
    if sc and sc.update then
        prof_push("scene "..scname..":update")

        sc:update(dt)

        prof_pop()
    end

    prof_pop() -- prof_push("love.update")
end

function love.draw()
    prof_push("love.draw")

    local crtActive = settings.isCRTActive()

    if crtActive then
        crt.start()
    end
    love.graphics.setShader(subpixel.shader)
    local sc, scname = sceneManager.getCurrentScene()
    if sc and sc.draw then
        prof_push("scene "..scname..":draw")

        iml.beginFrame()
        sc:draw()
        iml.endFrame()

        prof_pop()
    end
    if simulation.isSimulating() then
        local t = string.format("Simulating: %.3g", simulation.getProgress() * 100)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(t, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(t, 4, 4)
        log.info(t)
    end
    love.graphics.setShader()
    if crtActive then
        crt.finish()
    end

    -- Yes, we need this check instead of just calling `love.window.setFullscreen`
    -- without any conditions. Otherwise, mouse will get jittery on setting scene,
    -- at least in Windows.
    if settings.isFullscreen() ~= love.window.getFullscreen() then
        love.window.setFullscreen(settings.isFullscreen(), "desktop")
    end

    prof_pop() -- prof_push("love.draw")

    if heartbeat then
        heartbeat:HeartbeatEnd()
    end

    assert(profilerStackCount == 0, "more pushes than pops")

    if emulation then
        emulation.draw()
    end
end

local olderr = love.errorhandler or love.errhand

function love.errorhandler(msg)
    log.fatal(debug.traceback(msg))
    return olderr(msg)
end



function love.mousepressed(mx, my, button, istouch, presses)
    idleTime = 0
    iml.mousepressed(mx, my, button, istouch, presses)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousepressed then
        sc:mousepressed(mx, my, button, istouch, presses)
    end
end

function love.mousereleased(mx, my, button, istouch)
    idleTime = 0
    iml.mousereleased(mx, my, button, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousereleased then
        sc:mousereleased(mx, my, button, istouch)
    end
end

function love.mousemoved(mx, my, dx, dy, istouch)
    idleTime = 0
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousemoved then
        sc:mousemoved(mx, my, dx, dy, istouch)
    end
end



function love.keypressed(key, scancode, isrep)
    if scancode == "[" then
        -- toggle show-dev-stuff
        consts.SHOW_DEV_STUFF = consts.DEV_MODE and (not consts.SHOW_DEV_STUFF)
    elseif scancode == "return" and love.keyboard.isDown("lalt", "ralt") then
        settings.setFullscreen(not settings.isFullscreen())
    end

    idleTime = 0
    iml.keypressed(key, scancode, isrep)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keypressed then
        sc:keypressed(key, scancode, isrep)
    end
end

function love.keyreleased(key, scancode)
    idleTime = 0
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
    idleTime = 0
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

function love.focus(focus)
    if focus then
        idleTime = 0
    else
        if consts.IS_MOBILE and g.hasSession() then
            g.saveSession()
        end

        idleTime = CONSIDERED_IDLE_TIME
    end
end

function love.directorydropped(fullpath)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.directorydropped then
        sc:directorydropped(fullpath)
    end
end

function love.filedropped(file)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.filedropped then
        sc:filedropped(file)
    end
end

