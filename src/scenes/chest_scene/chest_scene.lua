local FreeCameraScene = require("src.scenes.FreeCameraScene")
local cosmetics = require("src.cosmetics.cosmetics")
local User = require("src.user")
local sceneManager = require("src.scenes.sceneManager")

---@class ChestScene: FreeCameraScene
---@field chestOpening ChestScene.ChestOpening?
local chestScene = FreeCameraScene()

local lg = love.graphics


---@class ChestScene.ChestOpening
---@field timeOpened number
-- put other data here. Like request-handle maybe? idk.

local COSMETIC_REFRESH_INTERVAL = 30


function chestScene:init()
    self.allowMousePan = false
    self.background = helper.newGradientMesh(
        "vertical",
        objects.Color("#".."FF090372"),
        objects.Color("#".."FF2B6CB6")
    )
    ---@type ChestScene.ChestOpening?
    self.chestOpening = nil
    self.showPopup = nil -- either "left" or "right"
    ---@type string[]
    self.inputCode = {} -- table of character to ease insertion and removal
    self.cosmeticsRefreshTime = 0
end

function chestScene:enter()
    cosmetics.tryRefresh()
end

function chestScene:leave()
    love.keyboard.setTextInput(false)
end





local CHEST_BUTTON_COL = {
    objects.Color("#".."FFB57705"),
    objects.Color("#".."FFC3A40C"),
}

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

---@param bot kirigami.Region
function chestScene:_drawChestUI(bot)
    local a, b, c = bot:splitHorizontal(4, 5, 4)

    -- Get Chest (Free)
    local leftButton = a:padUnit(4)
    if User.getFriendCode() then
        if drawChestButton("{o}Get Chest (Free){/o}", leftButton) then
            self.showPopup = "left"
        end
    end

    -- Input Code (Free Chest)
    if User.canSubmitFriendCode() then
        local rightButton = c:padUnit(4)
        if drawChestButton("{o}Put Code (Free Chest){/o}", rightButton) then
            self.showPopup = "right"
        end
    end

    g.drawImageContained("chest_big", b:shrinkToAspectRatio(1, 1):get())
    local _, d = b:splitVertical(5, 2)
    if cosmetics.getChestCount() > 0 then
        if ui.Button("{o}Open Chest{/o}", CHEST_BUTTON_COL[1], CHEST_BUTTON_COL[2], d:padUnit(4)) then
            print("TODO open chest")
        end
    end
end


local POPUP_COLOR = objects.Color("#".."FF735401")
local BUTTON_BASE_COL = objects.Color("#" .. "FF9F14F6")
local BUTTON_MAIN_COL = objects.Color("#" .. "FF3B12A4")
local BUTTON_GREEN_BASE_COL = objects.Color("#" .. "FF73ED75")
local BUTTON_GREEN_MAIN_COL = objects.Color("#" .. "FF2DAA1F")

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

---@param self ChestScene
local function showGetChestPopup(self)
    local r = drawCommonPopupBase()

    local titleR, descriptionR, codeTitleR, codeR, buttonR = r:splitVertical(48, r.h - 48 - 32 - 32 - 48, 32, 32, 48)
    helper.printTextOutline("Get Chest (Free)", g.getSmallFont(48), 2, titleR.x, titleR.y, titleR.w, "center")
    lg.printf("Everytime a friend uses your code, you also get a free chest! Give the code to your friends in Discord or your social media.", g.getSmallFont(32), descriptionR.x, descriptionR.y, descriptionR.w, "center")
    helper.printTextOutline("Your Code:", g.getSmallFont(32), 1, codeTitleR.x, codeTitleR.y, codeTitleR.w, "center")
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

    local titleR, descriptionR, inputCodeTextR, inputCodeR, enterCodeButtonR, closeButtonR = r:splitVertical(48, r.h - 2*48 - 2*32 - 64, 32, 32, 64, 48)
    helper.printTextOutline("Input Code", g.getSmallFont(48), 2, titleR.x, titleR.y, titleR.w, "center")
    lg.printf("Input your friend code in here to earn chest for both of you.", g.getSmallFont(32), descriptionR.x, descriptionR.y, descriptionR.w, "center")
    helper.printTextOutline("Input Code:", g.getSmallFont(32), 1, inputCodeTextR.x, inputCodeTextR.y, inputCodeTextR.w, "center")

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
        print("TODO enter code")
    end

    if ui.Button("{o}Close{/o}", BUTTON_BASE_COL, BUTTON_MAIN_COL, closeButtonR:padUnit(16, 8)) then
        love.keyboard.setTextInput(false)
        self.showPopup = nil
    else
        -- FIXME: This cannot be called all the time in iOS/Android.
        -- When porting to mobile, make sure to use different strategy.
        love.keyboard.setTextInput(true, ui.regionToScreenspace(textAreaR))
    end
end


local POPUPS = {
    left = showGetChestPopup,
    right = showInputCodePopup
}



---@param dt number
function chestScene:update(dt)
    self.cosmeticsRefreshTime = self.cosmeticsRefreshTime + dt
    if self.cosmeticsRefreshTime >= COSMETIC_REFRESH_INTERVAL then
        cosmetics.tryRefresh()
        self.cosmeticsRefreshTime = self.cosmeticsRefreshTime % COSMETIC_REFRESH_INTERVAL
    end
end





function chestScene:draw()
    -- Draw background
    lg.setColor(1,1,1)
    love.graphics.draw(self.background, 0, 0, 0, love.graphics.getDimensions())

    ui.startUI()
    local r = ui.getScreenRegion()
    local _,bot = r:splitVertical(3,2)
    self:_drawChestUI(bot)

    if POPUPS[self.showPopup] then
        POPUPS[self.showPopup](self)
    end
    ui.endUI()
end


function chestScene:mousepressed(mx,my,button)
end


function chestScene:keyreleased(k)
    if k == "escape" then
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




