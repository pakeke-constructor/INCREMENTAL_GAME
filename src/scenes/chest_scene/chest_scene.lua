local FreeCameraScene = require("src.scenes.FreeCameraScene")
local asynchttp = require("src.modules.asynchttp.asynchttp")
local cosmetics = require("src.cosmetics.cosmetics")
local ChestOpen = require("src.scenes.chest_scene.ChestOpen")
local User = require("src.user")
local sceneManager = require("src.scenes.sceneManager")
local steamTicket = require("src.steam.ticket")

---@class ChestScene: FreeCameraScene
---@field chestOpening ChestScene.ChestOpen?
local chestScene = FreeCameraScene()

local lg = love.graphics

local COSMETIC_REFRESH_INTERVAL = 30


local DO_MOCK = true
local MOCKING = consts.DEV_MODE and DO_MOCK
-- MOCK: fake chest opening for testing. Remove when done!
local MOCK_DELAY = 2 -- seconds
local mockTimers = {}
if MOCKING then
    cosmetics.getChestCount = function() return 99 end
    cosmetics.openChest = function(callback)
        mockTimers[#mockTimers+1] = {time = love.timer.getTime(), cb = callback}
    end
    User.getFriendCode = function() return "MEOW1234" end
    User.canSubmitFriendCode = function() return true end
end

local ERROR_CODES = {
    ERROR_ALREADY_ENTERED = loc("You've entered a code.", nil, {
        context = "Error message when user already entered a friend code. Each user can only enter one code for their account."
    }),
    ERROR_CODE_NOT_FOUND = loc("Invalid code.", nil, {
        context = "Error message when user typed wrong friend code."
    }),
    ERROR_SELF_REFERRAL = loc("Cannot enter your own code.", nil, {
        context = "Error message when user typed their own code as an attempt to cheat the system."
    })
}


function chestScene:init()
    self.allowMousePan = false
    self.background = helper.newGradientMesh(
        "vertical",
        objects.Color("#".."FF090372"),
        objects.Color("#".."FF2B6CB6")
    )
    ---@type ChestScene.ChestOpen?
    self.chestOpening = nil
    self.showPopup = nil -- either "left", "right", "center"
    self.inputCodeState = nil
    ---@type string[]
    self.inputCode = {} -- table of character to ease insertion and removal
    self.inputCodeSubmitting = false -- true if it's submitting invite codes.
    self.showInputCodeSuccess = false
    ---@type string?
    self.inputCodeError = nil
    self.cosmeticsRefreshTime = 0
end

function chestScene:enter()
    cosmetics.tryRefresh()
end

function chestScene:leave()
    love.keyboard.setTextInput(false)
end



local BUTTON_BASE_COL = objects.Color("#" .. "FF9F14F6")
local BUTTON_MAIN_COL = objects.Color("#" .. "FF3B12A4")
local BUTTON_GREEN_BASE_COL = objects.Color("#" .. "FF73ED75")
local BUTTON_GREEN_MAIN_COL = objects.Color("#" .. "FF2DAA1F")

---@param r kirigami.Region
---@return number
function chestScene:_drawButtons(r)
    local baseButtonR = Kirigami(0, 0, 96, 32)
        :attachToRightOf(r)
        :attachToTopOf(r)
        :moveRatio(-1, 1)
        :moveUnit(-8, 64)

    local refreshR = baseButtonR:moveRatio(0, 1):moveUnit(0, 8)
    if ui.Button("{o}Refresh{/o}", BUTTON_GREEN_BASE_COL, BUTTON_GREEN_MAIN_COL, refreshR) then
        cosmetics.tryRefresh()
    end

    local inventoryR = refreshR:moveRatio(0, 1):moveUnit(0, 8)
    if ui.Button("{o}Inventory{/o}", BUTTON_BASE_COL, BUTTON_MAIN_COL, inventoryR) then
        local luasteam = Steam.getSteam()
        if luasteam then
            local steamid = tostring(luasteam.user.getSteamID())
            local appid = luasteam.utils.getAppID()
            love.system.openURL("steam://openurl/https://steamcommunity.com/profiles/"..steamid.."/inventory/#"..appid)
        end
    end

    return math.max(inventoryR.w, refreshR.w)
end



local CHEST_BUTTON_COL = {
    objects.Color("#".."FFB57705"),
    objects.Color("#".."FFC3A40C"),
}
local CHEST_COUNT_TEXT = interp("You have %{chestCount} chest(s)", {context = "Used to show how many cosmetic chest user has"})

---@param text string
---@param region kirigami.Region
---@return boolean
local function drawChestButton(text, region)
    return ui.CustomButton(function(x, y, w, h)
        local f = g.getSmallFont(32)
        local wrap, lines = richtext.getWrap(text, f, w)
        -- I'm lazy computing the centering myself, so abuse Kirigami
        local newR = Kirigami(0, 0, wrap, lines * f:getHeight())
            :center(Kirigami(x, y, w, h))
        richtext.printRich(text, f, newR.x, newR.y, newR.w, "center")
    end, CHEST_BUTTON_COL[1], CHEST_BUTTON_COL[2], region)
end

---@param top kirigami.Region
function chestScene:_drawCosmeticsGrid(top)
    local allIds = cosmetics.getAll()
    if #allIds == 0 then return end
    table.sort(allIds, function(a, b)
        return cosmetics.getInfo(a).rarity > cosmetics.getInfo(b).rarity
    end)

    local r = top:padUnit(4)
    local cols, rows = helper.getBestFitDimensions(#allIds, r.w, r.h)
    local cellW, cellH = r.w / cols, r.h / rows

    for i, id in ipairs(allIds) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = r.x + col * cellW
        local cy = r.y + row * cellH
        local cellR = Kirigami(cx, cy, cellW, cellH):padUnit(2)

        local info = cosmetics.getInfo(id)
        local rarCol = g.COLORS.RARITIES[info.rarity or 0]
        lg.setColor(rarCol.r, rarCol.g, rarCol.b, 1)
        lg.rectangle("fill", cellR:padUnit(4):get())
        ui.drawPanel(cellR:get())
        lg.setColor(1, 1, 1)
        local inner = cellR:padUnit(4)
        g.drawImageContained(info.image, inner:get())
    end
end

---@param bot kirigami.Region
function chestScene:_drawChestUI(bot)
    local a, b, c = bot:splitHorizontal(4, 5, 4)

    -- Get Chest (Free)
    local leftButton = a:padRatio(0.2)
    if User.getFriendCode() then
        if drawChestButton("{o}Get Chest (Free){/o}", leftButton) then
            self.showPopup = "left"
        end
    end

    -- Input Code (Free Chest)
    if User.canSubmitFriendCode() then
        local rightButton = c:padRatio(0.2)
        if drawChestButton("{o}Put Code (Free Chest){/o}", rightButton) then
            self.showPopup = "right"
        end
    end

    local chestContainerR = b:shrinkToAspectRatio(1, 1)
    do
    local dy = math.sin(love.timer.getTime() * 1.75) * chestContainerR.h / 40 - 10
    local drot = math.sin(love.timer.getTime() * 1.9) * 0.05
    local x,y,w,h = chestContainerR:padRatio(0.6):get()
    g.drawImageContained("chest_big", x,y+dy,w,h, drot)
    end

    local chestCount = cosmetics.getChestCount()
    local chestCounterText = CHEST_COUNT_TEXT({chestCount = chestCount})
    local sfont32 = g.getSmallFont(32)
    local chestCounterTextR = Kirigami(0, 0, sfont32:getWidth(chestCounterText), sfont32:getHeight())
        :centerX(chestContainerR)
        :attachToTopOf(chestContainerR)
        :moveRatio(0,1)
    helper.printTextOutline(chestCounterText, sfont32, 2, chestCounterTextR.x, chestCounterTextR.y, chestCounterTextR.w, "left")

    local _, d = b:splitVertical(5, 2)
    if cosmetics.getChestCount() > 0 then
        if ui.Button("{o}Open Chest{/o}", CHEST_BUTTON_COL[1], CHEST_BUTTON_COL[2], d:padUnit(4)) then
            self.showPopup = "center"
        end
    end
end


local POPUP_COLOR = objects.Color("#".."FF735401")

local function drawCommonPopupBase()
    -- Prevent propagation
    local fullR = ui.getFullScreenRegion()
    iml.panel(fullR:get())
    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", fullR:get())

    local r = ui.getScreenRegion():padRatio(0.2)

    lg.setColor(POPUP_COLOR)
    ui.drawSingleColorPanel(r:padUnit(2):get())
    lg.setColor(1, 1, 1)
    ui.drawPanel(r:get())

    return r:padUnit(8)
end



local EXPLAIN_CODE = loc("Everytime your code is used, get a free chest! No limits; if your code is used 50 times, you will get 50 chests!\nShare it to friends via telegram, discord, reddit, etc.", {
    context = "Explaining the mechanics of an affiliate scheme, simple and clear. Whenever anyone uses their code, they get a free chest; without limits."
})
local GET_CHEST_TITLE = loc("Get Chest (Free)", {context = "Title of popup showing the user's referral code"})
local YOUR_CODE = loc("Your Code:", {context = "Label above the user's referral code"})

local INPUT_CODE_TITLE = loc("Input Code", {context = "Title of popup for entering a friend's referral code"})
local INPUT_CODE_DESC = loc("Enter a friend's code: you'll both get a free chest!", {context = "Description explaining the friend code input affiliate mechanism"})
local INPUT_CODE_LABEL = loc("Input Code:", {context = "Label above the code input field"})


---@param self ChestScene
local function showGetChestPopup(self)
    local r = drawCommonPopupBase()

    local titleR, descriptionR, codeTitleR, codeR, buttonR = r:splitVertical(48, r.h - 48 - 32 - 32 - 48, 32, 32, 48)
    helper.printTextOutline(GET_CHEST_TITLE, g.getSmallFont(48), 2, titleR.x, titleR.y, titleR.w, "center")
    lg.printf(EXPLAIN_CODE, g.getSmallFont(32), descriptionR.x, descriptionR.y, descriptionR.w, "center")
    helper.printTextOutline(YOUR_CODE, g.getSmallFont(32), 1, codeTitleR.x, codeTitleR.y, codeTitleR.w, "center")
    local codeArea = codeR:set(nil, nil, 16 * 8):padUnit(-2):center(codeR)
    lg.setColor(1, 1, 1, 0.3)
    helper.quickRoundedRectangle("fill", 4, codeArea)
    lg.setColor(1, 1, 1)
    local friendCode = assert(User.getFriendCode())
    helper.printTextOutline(friendCode, g.getSmallFont(32), 1, codeR.x, codeR.y, codeR.w, "center")

    local copyButtonR, okButtonR = buttonR:splitHorizontal(1, 1)
    if ui.Button("{o}Copy{/o}", BUTTON_BASE_COL, BUTTON_MAIN_COL, copyButtonR:padUnit(16, 8)) then
        love.system.setClipboardText(friendCode)
    end

    if ui.Button("{o}Ok{/o}", BUTTON_GREEN_BASE_COL, BUTTON_GREEN_MAIN_COL, okButtonR:padUnit(16, 8)) then
        self.showPopup = nil
    end
end


---@param self ChestScene
local function pasteToInput(self)
    local clipboardText = love.system.getClipboardText()
    if clipboardText and #clipboardText > 0 then
        -- We don't want utf8.codes error propagate
        pcall(function()
            for _, c in utf8.codes(clipboardText) do
                if #self.inputCode >= 8 then
                    break
                end

                self.inputCode[#self.inputCode+1] = utf8.char(c)
            end
        end)
    end
end

---@param self ChestScene
local function showInputCodePopup(self)
    local r = drawCommonPopupBase()

    local titleR, descriptionR, inputCodeTextR, inputCodeR, enterCodeButtonR, errorMessageR, closeButtonR = r:splitVertical(48, r.h - 2*48 - 2*32 - 64 - 16, 32, 32, 64, 16, 48)
    helper.printTextOutline(INPUT_CODE_TITLE, g.getSmallFont(48), 2, titleR.x, titleR.y, titleR.w, "center")
    lg.printf(INPUT_CODE_DESC, g.getSmallFont(32), descriptionR.x, descriptionR.y, descriptionR.w, "center")
    helper.printTextOutline(INPUT_CODE_LABEL, g.getSmallFont(32), 1, inputCodeTextR.x, inputCodeTextR.y, inputCodeTextR.w, "center")

    local textAreaR, pasteButtonR = inputCodeR:padUnit(16, 0):splitHorizontal(3, 2)

    -- Draw text input
    local inputR = textAreaR:padUnit(0, 0, 8, 0)
    local text = ""
    local textInput = iml.consumeText()
    if #self.inputCode < 8 and textInput then
        self.inputCode[#self.inputCode+1] = textInput:upper()
    end
    if #self.inputCode > 0 then
        text = table.concat(self.inputCode, "", 1, math.min(#self.inputCode, 8))
    end
    lg.setColor(1, 1, 1, 0.3)
    helper.quickRoundedRectangle("fill", 4, inputR)
    if #text > 0 then
        lg.setColor(1, 1, 1)
        helper.printTextOutline(text, g.getSmallFont(32), 1, inputR.x, inputR.y, inputR.w, "center")
    else
        lg.setColor(1, 1, 1, 0.5)
        lg.printf("Input Code", g.getSmallFont(32), inputR.x, inputR.y, inputR.w, "center", 1, 1, 0, 0, 0.5)
    end
    lg.setColor(1, 1, 1)
    -- Blinker
    if love.timer.getTime() % 1 >= 0.5 then
        local width = g.getSmallFont(32):getWidth(text)
        local x = inputR.x + (inputR.w + width) / 2
        love.graphics.line(x, inputR.y, x, inputR.y + inputR.h)
    end

    -- Draw paste button
    if ui.Button("{o}Paste{/o}", BUTTON_BASE_COL, BUTTON_MAIN_COL, pasteButtonR:padUnit(8, 0, 0, 0)) then
        pasteToInput(self)
    end

    -- Draw enter code
    if ui.Button("{o}Enter{/o}", BUTTON_GREEN_BASE_COL, BUTTON_GREEN_MAIN_COL, enterCodeButtonR:padUnit(16, 8)) then
        if #text > 0 then
            User.submitFriendCode(text, function(success, reason)
                cosmetics.tryRefresh()

                if success then
                    self.showInputCodeSuccess = true
                    self.showPopup = nil
                else
                    self.inputCodeError = ERROR_CODES[reason] or reason or "Unknown error"
                end

                self.inputCodeSubmitting = false
            end)
            self.inputCodeSubmitting = true
        else
            self.inputCodeError = "Please enter a code."
        end
    end

    if self.inputCodeError then
        lg.setColor(1, 0.3, 0.3)
        helper.printTextOutline(self.inputCodeError, g.getSmallFont(16), 1, errorMessageR.x, errorMessageR.y, errorMessageR.w, "center")
    end

    if ui.Button("{o}Close{/o}", BUTTON_BASE_COL, BUTTON_MAIN_COL, closeButtonR:padUnit(16, 8)) then
        love.keyboard.setTextInput(false)
        self.showPopup = nil
        self.inputCodeError = nil
        return
    end

    if self.inputCodeSubmitting then
        local fullR = ui.getFullScreenRegion()
        iml.panel(fullR:get())
        lg.setColor(0, 0, 0, 0.3)
        lg.rectangle("fill", fullR:get())
        lg.setColor(1, 1, 1)

        local cx, cy = fullR:getCenter()
        local f = g.getSmallFont(32)
        richtext.printRich("{w}{o}Submitting...{/o}{/w}", f, cx, cy, fullR.w, "center", 0, 1, 1, cx, f:getHeight() / 2)
        love.keyboard.setTextInput(false)
    else
        -- FIXME: This cannot be called all the time in iOS/Android.
        -- When porting to mobile, make sure to use different strategy.
        love.keyboard.setTextInput(true, ui.regionToScreenspace(textAreaR))
    end
end

---@param self ChestScene
local function showOpenChestPopup(self)
    if not self.chestOpening then
        self.chestOpening = ChestOpen()
        cosmetics.openChest(function(success, cosmetic)
            if success and self.chestOpening and cosmetic then
                self.chestOpening:setResult(cosmetic)
            elseif self.chestOpening then
                self.chestOpening:setError()
            end
        end)
    end

    if not self.chestOpening then return end
    self.chestOpening:draw()

    if self.chestOpening:isDone() then
        if self.chestOpening:isError() then
            self.inputCodeError = "Error opening chest"
        end
        self.chestOpening = nil
        self.showPopup = nil
    end
end

---@param self ChestScene
local function showChestOnGodrays(self)
    local r = ui.getFullScreenRegion()
    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", r:get())
    lg.setColor(1, 1, 1)

    local rx, ry = r:getCenter()
    -- Draw cosmetic in godray
    local t2 = love.timer.getTime()/2
    godrays.drawRays(rx,ry, t2/2.5, {
        rayCount = 3,
        divisions=100,
        color = RAY_COLOR,
        startWidth=8,
        length=600,
        fadeTo=0,
        growRate=0.6,
    })
    godrays.drawRays(rx,ry, -t2/1.5, {
        rayCount = 5,
        divisions=100,
        color = RAY_COLOR,
        startWidth=9,
        length=150,
        fadeTo=0,
        growRate=1.6,
    })
    godrays.drawRays(rx,ry, t2, {
        rayCount = 6,
        divisions=100,
        color = RAY_COLOR,
        startWidth=10,
        length=200,
        fadeTo=0,
        growRate=2.6,
    })
    godrays.drawRays(rx,ry, t2*-1, {
        rayCount = 5,
        divisions=100,
        color = RAY_COLOR,
        startWidth=10,
        length=300,
        fadeTo=0,
        growRate=2.6,
    })

    lg.setColor(1, 1, 1)

    local dy = math.sin(love.timer.getTime() * 1.75) * 3
    local drot = math.sin(love.timer.getTime() * 1.9) * 0.2
    g.drawImage("chest_big", rx, ry+dy, drot, 7, 7, 0,0)

    helper.printTextOutline("You got 1 free chest!", g.getSmallFont(32), 2, rx, ry + 90, r.w, "center", 0, 1, 1, r.w / 2)
    helper.printTextOutline("Click anywhere to close", g.getSmallFont(32), 2, rx, ry + 120, r.w, "center", 0, 1, 1, r.w / 2)

    if iml.wasJustPressed(r:get()) then
        self.showInputCodeSuccess = nil
    end
end

local POPUPS = {
    left = showGetChestPopup,
    right = showInputCodePopup,
    center = showOpenChestPopup
}



---@param dt number
function chestScene:update(dt)
    self.cosmeticsRefreshTime = self.cosmeticsRefreshTime + dt
    if self.cosmeticsRefreshTime >= COSMETIC_REFRESH_INTERVAL then
        cosmetics.tryRefresh()
        self.cosmeticsRefreshTime = self.cosmeticsRefreshTime % COSMETIC_REFRESH_INTERVAL
    end

    if self.chestOpening then
        self.chestOpening:update(dt)
    end

    -- MOCK: tick delayed callbacks
    local t = love.timer.getTime()
    for i = #mockTimers, 1, -1 do
        if t - mockTimers[i].time >= MOCK_DELAY then
            mockTimers[i].cb(true, "gold")
            table.remove(mockTimers, i)
        end
    end
end





function chestScene:draw()
    -- Draw background
    lg.setColor(1,1,1)
    love.graphics.draw(self.background, 0, 0, 0, love.graphics.getDimensions())

    ui.startUI()
    local r = ui.getScreenRegion()
    local top, bot = r:splitVertical(3, 2)

    self:renderMapButton()

    local w = self:_drawButtons(r)
    local grid = top:padUnit(0,0,w + 10, 0)
    self:_drawCosmeticsGrid(grid)
    self:_drawChestUI(bot)

    if POPUPS[self.showPopup] then
        POPUPS[self.showPopup](self)
    end

    if self.showInputCodeSuccess then
        showChestOnGodrays(self)
    end
    ui.endUI()
end


function chestScene:mousepressed(mx,my,button)
end


function chestScene:keyreleased(k)
    if k == "escape" and self.showPopup == nil and not self.showInputCodeSuccess then
        sceneManager.gotoLastScene()
    end
end

function chestScene:keypressed(k)
    if self.showPopup == "right" then
        if k == "backspace" and #self.inputCode > 0 then
            -- Erase
            table.remove(self.inputCode)
        elseif k == "v" and love.keyboard.isDown("lctrl", "rctrl") then
            pasteToInput(self)
        end
    end
end

return chestScene




