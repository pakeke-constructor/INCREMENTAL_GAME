-- Platform behavior emulation support, mostly for development only.
---@class emulation
local emulation = {}

function emulation.init()
    local insets = os.getenv("INCREMENTAL_GAME_SAFE_AREA")
    if insets then
        local status, data = pcall(json.decode, insets)
        if status then
            local left = assert(tonumber(data[1]))
            local top = assert(tonumber(data[2] or left))
            local right = assert(tonumber(data[3] or left))
            local bot = assert(tonumber(data[4] or top))

            ---@diagnostic disable-next-line: duplicate-set-field
            function love.window.getSafeArea()
                local x, y, w, h = Kirigami(0, 0, love.graphics.getDimensions()):padRatio(left, top, right, bot):get()
                return math.floor(x + 0.5), math.floor(y + 0.5), math.floor(w + 0.5), math.floor(h + 0.5)
            end
        end
    end

    if consts.EMULATE_TOUCH then
        -- For LuaLS only
        if false then love.handlers = {} end

        local emuX, emuY = 0, 0
        local wasPressed = false -- used to send mousemoved event

        local getPosition = love.touch.getPosition

        local function getMirroredPosition()
            local w, h = love.graphics.getDimensions()
            return w - emuX, h - emuY
        end

        function love.touch.getTouches()
            if not wasPressed then
                return {}
            end

            if not love.keyboard.isDown("rctrl") then
                return {1}
            end

            return {1, 2}
        end

        function love.touch.getPosition(id)
            if type(id) == "number" then
                if id == 1 then
                    return emuX, emuY
                elseif id == 2 then
                    return getMirroredPosition()
                else
                    error("\27]8;;https://youtu.be/dQw4w9WgXcQ\27\\what do you expect with touch emulation?\27]8;;\27\\")
                end
            end

            return getPosition(id)
        end

        -- Monkeypatch HACK
        ---@diagnostic disable-next-line: duplicate-set-field
        function love.mouse.getPosition()
            return emuX, emuY
        end

        function love.handlers.mousepressed(mx, my, button, _, presses)
            if button ~= 1 then return end
            if not wasPressed then
                love.mousemoved(mx, my, mx - emuX, my - emuY, true)
            end
            wasPressed = true
            emuX, emuY = mx, my
            return love.mousepressed(mx, my, button, true, presses)
        end

        function love.handlers.mousereleased(mx, my, button, _, presses)
            if button ~= 1 then return end
            emuX, emuY = mx, my
            wasPressed = false
            return love.mousereleased(mx, my, 1, true, presses)
        end

        function love.handlers.mousemoved(mx, my, dx, dy, _)
            if not love.mouse.isDown(1) then return end
            emuX, emuY = mx, my
            return love.mousemoved(mx, my, dx, dy, true)
        end
    end
end

---@param dt number
function emulation.update(dt)
end

function emulation.draw()
    if consts.EMULATE_TOUCH and love.mouse.isDown(1) then
        love.graphics.setColor(1, 1, 1)

        local m1x, m1y = love.touch.getPosition(1)
        love.graphics.circle("fill", m1x, m1y, 8)

        if love.keyboard.isDown("rctrl") then
            local m2x, m2y = love.touch.getPosition(2)
            love.graphics.circle("fill", m2x, m2y, 8)
            love.graphics.line(m1x, m1y, m2x, m2y)
        end
    end
end

return emulation
