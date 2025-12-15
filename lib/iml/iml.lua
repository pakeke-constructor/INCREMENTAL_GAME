



local iml = {}



---@alias iml._Panel {x:number, y:number, w:number,h:number, key:any, transform?: love.Transform}
---@alias iml._FrameState { hoveredPanel: iml._Panel?, transformStack: love.Transform[], transform: love.Transform}


---@class iml._Click
---@field original_x number
---@field original_y number
---@field total_dx number (drag distance).
---@field total_dy number (drag distance).
---@field last_frame_dx number
---@field last_frame_dy number
---@field panel_key any? The key or identifier of the panel that was clicked
---@field is_drag boolean?
local iml_Click



---@type iml._Panel?
local lastHoveredPanel = nil
---@type boolean
local hoverChangedLastFrame = false

---@type iml._Panel?
local selectedPanel = nil

---@type string?
local text = nil


local frameCount = 0

---@type iml._FrameState
local frameState = nil



iml.CLICK_MOVE_THRESHOLD = 10
-- Click and move less than X pixels = click
-- MORE than X pixels, drag


-- tracks the "current" clicks.
-- (eg if user is holding down the mouse)
local currentClicks = {--[[
    [button] -> iml._Click
]]}



-- tracks the click-releases from the previous frame
local clickReleases = {--[[
    [button] = iml._Click
]]}


-- tracks the click-presses from the previous frame
local clickPresses = {--[[
    [button] = iml._Click
]]}



local pointer_x = 0
local pointer_y = 0

local last_pointer_x = 0
local last_pointer_y = 0


---@param cl iml._Click
---@return boolean
local function isClick(cl)
    if cl.is_drag then
        -- once its a drag; its *always* a drag
        return false
    end
    -- Otherwise, if it moves less than X distance, its a click
    return math.sqrt(cl.total_dx*cl.total_dx + cl.total_dy*cl.total_dy) < iml.CLICK_MOVE_THRESHOLD
end



local function assertIsFrame()
    if not frameState then
        error("No framestate was set! (Did you forget to call .beginFrame()..?)", 3)
    end
end


function iml.beginFrame()
    local px, py = pointer_x, pointer_y
    local pdx, pdy = pointer_x-last_pointer_x, pointer_y-last_pointer_y

    last_pointer_x = pointer_x
    last_pointer_y = pointer_y

    for _, cl in pairs(currentClicks) do
        cl.total_dx = px - cl.original_x
        cl.total_dy = py - cl.original_y

        cl.last_frame_dx = pdx
        cl.last_frame_dy = pdy
    end

    frameState = {
        transformStack = {},
        transform = love.math.newTransform(),

        hoveredPanel = nil
    }
end


local DOUBLE_MAX_PRECISION = 53 -- 2^53 is biggest double int precision
local ZEROS = math.floor(DOUBLE_MAX_PRECISION/4)

local function hash(x,y,w,h)
    return x
        + y*(2^ZEROS)
        + w*(2^(ZEROS*2))
        + h*(2^ZEROS*3)
end


iml.hash = hash


local function getKey(x,y,w,h, key)
    return key or hash(x,y,w,h)
end



---@param x number
---@param y number
---@param w number
---@param h number
---@param px number
---@param py number
---@return boolean
local function isInside(x, y, w, h, px, py)
  return
    px >= x and
    py >= y and
    px <= x + w and
    py <= y + h
end


---@return number,number
local function getTransformedPointer()
    assert(frameState and pointer_x, "?")
    return frameState.transform:inverseTransformPoint(pointer_x, pointer_y)
end
iml.getTransformedPointer = getTransformedPointer



--- Creates a "Panel".
--- Mouse click / mouse hover won't propagate through this region.
---@param x number
---@param y number
---@param w number
---@param h number
---@param key any?
function iml.panel(x,y,w,h, key)
    assertIsFrame()
    -- If no key is specified,
    -- uses hash(x,y,w,h) as a key.
    if pointer_x then
        local px, py = getTransformedPointer()
        if isInside(x,y,w,h, px,py) then
            frameState.hoveredPanel = {
                x=x,y=y, w=w,h=h,
                key = getKey(x,y,w,h,key),
            }
        end
    end
end




local IDENTITY = love.math.newTransform()

---@param t love.Transform
function iml.pushTransform(t)
    assertIsFrame()
    local stack = frameState.transformStack
    table.insert(stack, t)
    local tr = IDENTITY
    for i=1, #stack do
        local v = stack[i]
        tr = tr:clone():apply(v)
    end
    frameState.transform = tr
end


function iml.popTransform()
    assertIsFrame()
    local stack = frameState.transformStack
    table.remove(stack)
    local tr = IDENTITY
    for i=1, #stack do
        local v = stack[i]
        tr = tr:clone():apply(v)
    end
    frameState.transform = tr
end


function iml.resetTransforms()
    assertIsFrame()
    frameState.transformStack = {}
    frameState.transform = love.math.newTransform()
end





--- Pushes a "mask" onto the stack; elements outside of this area cannot be clicked.
---  Useful for stencil-like operations.
---@param x number
---@param y number
---@param w number
---@param h number
function iml.pushMask(x,y,w,h)
    
end


--- Pops a mask from the stack. 
---  (Undos pushMask)
function iml.popMask()

end


local function wasTop(key)
    -- returns whether this `key` was the top panel the previous frame
    if lastHoveredPanel and lastHoveredPanel.key == key then
        return true
    end
    return false
end

--- Returns true if the region is currently being clicked.
--- (Called continously every frame whilst the mouse is down)
---@param x number
---@param y number
---@param w number
---@param h number
---@param button any
---@param keyy any
---@return boolean
function iml.isClicked(x,y,w,h, button, keyy)
    assertIsFrame()
    iml.panel(x,y,w,h, keyy)
    button = button or 1
    local cl = currentClicks[button]
    if cl and isClick(cl) then
        keyy = getKey(x,y,w,h,keyy)
        return wasTop(keyy)
    end
    return false
end


---@param x number
---@param y number
---@param w number
---@param h number
---@param key any
---@return boolean
function iml.isHovered(x,y,w,h, key)
    assertIsFrame()
    iml.panel(x,y,w,h, key)
    key = getKey(x,y,w,h,key)
    return wasTop(key)
end



--- returns true IFF the element's hover was started the last frame exactly.
---@param x number
---@param y number
---@param w number
---@param h number
---@param key any
---@return boolean
function iml.wasJustHovered(x,y,w,h, key)
    return hoverChangedLastFrame and iml.isHovered(x,y,w,h,key)
end




---@param x number
---@param y number
---@param w number
---@param h number
---@param key any
---@return boolean
function iml.isSelected(x,y,w,h, key)
    assertIsFrame()
    iml.panel(x,y,w,h, key)
    key = getKey(x,y,w,h,key)
    return (selectedPanel and selectedPanel.key == key) or false
end




--- Returns true ONCE if the region was just clicked.
--- (ie ONLY the frame after `mousereleased`.)
function iml.wasJustClicked(x,y,w,h, button, key)
    assertIsFrame()
    iml.panel(x,y,w,h, key)
    button = button or 1
    local cl = clickReleases[button]
    if cl and isClick(cl) then
        key = getKey(x,y,w,h,key)
        if wasTop(key) then
            return true
        end
    end
    return false
end


---@param x number
---@param y number
---@return number
---@return number
local function inverseTransform(x,y)
    assert(frameState and x and y, "?")
    return frameState.transform:inverseTransformPoint(x,y)
end



---@class iml.Drag
---@field startX number
---@field startY number
---@field endX number
---@field endY number
---@field dx number
---@field dy number

---@param key any
---@param button integer
---@return iml.Drag?
function iml.consumeDrag(key, x,y,w,h, button)
    assertIsFrame()
    iml.panel(x,y,w,h, key)
    assert(key ~= nil and type(key) ~= "number", "Must provide a valid key")
    ---@type iml._Click
    local cl = currentClicks[button]
    if cl and (cl.panel_key == key) and (not isClick(cl)) then
        -- its dragging this element!
        cl.last_frame_dx = 0
        cl.last_frame_dy = 0
        local startX,startY = inverseTransform(cl.original_x, cl.original_y)
        local endX,endY = getTransformedPointer()
        local dx,dy = endX-startX, endY-startY
        return {
            startX = startX,
            startY = startY,
            endX = endX,
            endY = endY,
            dx = dx, dy=dy
        }
    end
end



--- Returns true ONCE if the region was just pressed by a mouse-button.
--- (ie ONLY the frame after `mousepressed`.)
function iml.wasJustPressed(x,y,w,h, button, key)
    assertIsFrame()
    iml.panel(x,y,w,h, key)
    button = button or 1
    if clickPresses[button] then
        key = getKey(x,y,w,h,key)
        if wasTop(key) then
            return true
        end
    end
    return false
end


--- Returns true ONCE if the region was just released by a mouse-button.
--- (ie ONLY the frame after `mousepressed`.)
function iml.wasJustReleased(x,y,w,h, button, key)
    assertIsFrame()
    iml.panel(x,y,w,h, key)
    button = button or 1
    if clickReleases[button] then
        key = getKey(x,y,w,h,key)
        if wasTop(key) then
            return true
        end
    end
    return false
end



--- Returns and "consumes" text input
---@return string?
function iml.consumeText()
    local t = text
    text = nil
    return t
end



function iml.endFrame()
    hoverChangedLastFrame = false
    if frameState.hoveredPanel then
        if lastHoveredPanel then
            if lastHoveredPanel.key ~= frameState.hoveredPanel.key then
                hoverChangedLastFrame = true
            end
        else
            hoverChangedLastFrame = true
        end
    end

    for _button,cl in pairs(currentClicks) do
        if not isClick(cl) then
            cl.is_drag = true
        end
    end

    lastHoveredPanel = frameState.hoveredPanel or nil
    frameCount = frameCount + 1
    clickReleases = {}
    clickPresses = {}
    text = nil
end



function iml.mousepressed(x, y, button, istouch, presses)
    -- "when mouse is pressed, store the widget that was pressed."
    local cl = {
        original_x=x,
        original_y=y,
        total_dx = 0,
        total_dy = 0,

        last_frame_dx = 0,
        last_frame_dy = 0,

        -- the panel that was just clicked!
        panel_key = (lastHoveredPanel and lastHoveredPanel.key) or nil
    }

    if button == 1 then
        selectedPanel = lastHoveredPanel
    end

    currentClicks[button] = cl
    clickPresses[button] = cl
end



function iml.mousereleased(x, y, button, istouch, presses)
    local cl = currentClicks[button]
    if cl and isClick(cl) then
        clickReleases[button] = cl
    end
    currentClicks[button] = nil
end


function iml.keypressed(key, scancode, isrepeat)
    if not frameState then return end
end

function iml.keyreleased(key, scancode, isrepeat)
    if not frameState then return end

end



function iml.setPointer(x,y)
    pointer_x = x
    pointer_y = y
end



function iml.textinput(txt)
    text = (text or "") .. txt
end


function iml.wheelmoved(dx,dy)
    -- TODO: implement me
end




return iml

