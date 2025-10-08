

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")

local World = require("src.world.world")
local Session = require("src.Session")
local HUD = require("src.ui.hud.hud")

---@class g
local g = {}





---@type g.Session
local currentSession

function g.newSession()
    currentSession = Session()
end


---@return g.Session
function g.getSn()
    return assert(currentSession)
end

---@return g.World
function g.getMainWorld()
    return currentSession.mainWorld
end

function g.getPrestige()
    return currentSession.prestige
end




local loadingContext = {
    modname = "@" -- @ = built-in mod
}


---@return {modname:string}
function g.getLoadingContext()
    return loadingContext
end

function g.finishLoading()
    loadingContext = nil
end






local sceneManager

---@param scName string
function g.gotoScene(scName)
    sceneManager = sceneManager or require("src.scenes.sceneManager")
    sceneManager.gotoScene(scName)
end




local callUpgrades, askUpgrades
local definedEvents = objects.Set()

function g.defineEvent(ev)
    assert(g.getLoadingContext())
    definedEvents:add(ev)
end

function g.isEvent(ev)
    return definedEvents:has(ev)
end


function g.assertIsQuestionOrEvent(ev_or_question, level)
    level = level or 0
    local isQuestionOrEvent = (g.getQuestionInfo(ev_or_question) or g.isEvent(ev_or_question))
    if not isQuestionOrEvent then
        error("Invalid question/event: " .. tostring(ev_or_question), 2 + level)
    end
end


---@param ev string
---@param arg1 any
---@param ... unknown
function g.call(ev, arg1, ...)
    -- call systems
    if (type(arg1) == "table") and arg1[ev] then
        arg1[ev](arg1, ...)
    end

    callUpgrades(ev, arg1, ...)
end



local questions = {--[[
    [question] -> {reducer=func, defaultValue=0}
]]}

function g.getQuestionInfo(q)
    return questions[q]
end

---@param question string
---@param reducer fun(a:any, b:any): any
---@param defaultValue any
function g.defineQuestion(question, reducer, defaultValue)
    assert(g.getLoadingContext())
    questions[question] = {
        reducer = reducer,
        defaultValue = defaultValue
    }
end


---@param q string
---@param arg1 any
---@param ... unknown
function g.ask(q, arg1, ...)
    local t = questions[q]
    if not t then
        error("Invalid question")
    end
    local reducer, val = t.reducer, t.defaultValue

    if (type(arg1) == "table") and arg1[q] then
        val = reducer(arg1[q](arg1, ...), val)
    end

    return reducer(val, askUpgrades(q, arg1, ...))
end






---@param path string
---@param func fun(path: string)
function g.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            g.walkDirectory(path .. "/" .. pth, func)
        end
    end
end


---@param path string
function g.requireFolder(path)
    local results = {}
    g.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4,-1) == ".lua" then
            pth = pth:sub(1, -5)
            log.trace("loading file:", pth)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end




-- g.formatNumber defined here
do
local suffixes = {
    {1e12, "t"},
    {1e9,  "b"},
    {1e6,  "m"},
    {1e3,  "k"}
}

---@param num number
function g.formatNumber(num)
    local isNegative = num < 0
    num = math.abs(num)

    if num < 1000 then
        return (isNegative and "-" or "") .. tostring(math.floor(num))
    end

    for i, suffix in ipairs(suffixes) do
        if num >= suffix[1] then
            local scaled = num / suffix[1]
            local formatted
            if scaled >= 100 then
                formatted = string.format("%.0f", math.floor(scaled))
            elseif scaled >= 10 then
                formatted = string.format("%.14g", math.floor(scaled * 10) / 10)
            else
                formatted = string.format("%.14g", math.floor(scaled * 100) / 100)
            end

            return (isNegative and "-" or "") .. formatted .. suffix[2]
        end
    end
    return (isNegative and "-" or "") .. tostring(num)
end

end







-- fonts:   getBigFont, getSmallFont
do
local bigCache = {}
local smolCache = {}

---@param size number
---@return love.Font
function g.getBigFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if bigCache[size] then return bigCache[size] end
    bigCache[size] = love.graphics.newFont("assets/fonts/Smart 9h.ttf", size,"mono",1)
    return bigCache[size]
end

---@param size number
---@return love.Font
function g.getSmallFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if smolCache[size] then return smolCache[size] end
    smolCache[size] = love.graphics.newFont("assets/fonts/Match 7h.ttf", size,"mono",1)
    return smolCache[size]
end

end





-- Images,
-- atlas handling
-- g.drawImage, etc defined here!
do
local nameToQuad = {--[[
    [name] -> Quad
]]}
---@cast nameToQuad table<string, love.Quad>


---@return love.Texture
function g.getAtlas()
    return atlas:getTexture()
end

---@param imageName string
function g.getImageQuad(imageName)
    local quad = nameToQuad[imageName]
    if not quad then
        error("Invalid quad: "..tostring(imageName))
    end
    return quad
end


---@param imageName string
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param kx number?
---@param ky number?
function g.drawImage(imageName, x,y, r,sx,sy,kx,ky)
    return g.drawImageOffset(imageName, x, y, r, sx, sy, 0.5, 0.5, kx, ky)
end

---@param imageName string
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
---@param kx number?
---@param ky number?
function g.drawImageOffset(imageName, x,y, r, sx,sy, ox,oy, kx,ky)
    local quad = g.getImageQuad(imageName)
    local _,_,w,h = quad:getViewport()
    atlas:draw(quad, x, y, r, sx, sy, (ox or 0.5) * w, (oy or 0.5) * h, kx, ky)
end


---@param imageName any
---@return boolean
function g.isImage(imageName)
    return (nameToQuad[imageName] and true) or false
end


local validExtensions = {
    [".png"] = true,
    [".jpg"] = true
}

local function loadImage(path)
    local ext = path:sub(-4):lower()
    if validExtensions[ext] then
        local name = path:match("([^/]+)%.%w+$") -- path/to/foo.png --> "foo"
        local quad = atlas:add(love.image.newImageData(path))
        if nameToQuad[name] then
            error("Duplicate image: "..name)
        end
        nameToQuad[name] = quad
    end
end


g.walkDirectory("src/upgrades", loadImage)
g.walkDirectory("assets/images", loadImage)

end



-- metrics are "temporary" values that start at 0,
-- and keep track of arbitrary runtime stuff
-- (eg. number of logs destroyed, seconds-elapsed, mine-count, etc)
local validMetrics = {--[[
    [metricName] -> true
]]}

local metricTc = typecheck.assert("string")

---@param name string
function g.defineMetric(name)
    metricTc(name)

    validMetrics[name] = true
end


local setMetricTc = typecheck.assert("string","number")

---@param name string
---@param x number
function g.setMetric(name, x)
    setMetricTc(name, x)
    assert(validMetrics[name], name)
    g.getSn().metrics[name] = x
end


---@param name string
---@return number
function g.getMetric(name)
    metricTc(name)
    assert(validMetrics[name], name)
    return g.getSn().metrics[name] or 0
end




local strTc = typecheck.assert("string")

---@type table<string, {addQuestion: string, multQuestion:string, startingValue: number}>
g.VALID_STATS = {}

---@param name string
---@param startingValue number
---@return number
function g.defineStat(name, startingValue)
    strTc(name)
    assert(not g.VALID_STATS[name], "Redefined stat")
    assert(name:sub(1,1):upper() == name:sub(1,1), "Stats must have first letter capitalized")
    local addQ = "get" .. name .. "Modifier"
    g.defineQuestion(addQ, reducers.ADD, 0)
    local multQ = "get" .. name .. "Multiplier"
    g.defineQuestion(multQ, reducers.MULTIPLY, 1)
    g.VALID_STATS[name]={
        addQuestion = addQ, multQuestion = multQ,
        startingValue = startingValue
    }
    return 0
end




-- stats are recomputed every frame.
-- Think of them as like "global properties".
-- (EG. harvestingSpeed, harvestingDamage)
---@class g.stats
g.stats = {}


-- SSTATS 
-- (if you ever want to quickly search the name of stats, search "sstats")
g.stats.HitDuration = g.defineStat("HitDuration", 0.8)
g.stats.HitDamage = g.defineStat("HitDamage", 1)
g.stats.HarvestArea = g.defineStat("HarvestArea", 30)




---@alias g.ResourceType "money"|"logs"|"rocks"|"bones"

-- i wish we could define this as { [g.ResourceType]: number } but it doesnt work that way
---@alias g.Bundle {money?: number, bones?: number, rocks?: number, logs?: number}
---@alias g.Resources {money: number, bones: number, rocks: number, logs: number}


---@alias g.PrestigeRange {lower: integer, upper: integer}




local UPGRADE_KINDS = {TOKEN=true,HARVESTING=true,TOKEN_MODIFIER=true,MISC=true}

---@alias g.UpgradeKind
---token upgrade, always +1 <token> per level. 1-1 mapping with a token.
---| "TOKEN"
---upgrade relating to harvesting-speed, or dealing extra damage
---| "HARVESTING"
--- Token modifers. Eg. "all grass-tokens earn +$5". 
--- "When a log-token is destroyed, spawn a bomb"
---| "TOKEN_MODIFIER"
--- Misc upgrades; 
--- (eg. double the money-limit. Harvest stuff automatically.)
---| "MISC"

---@class g.UpgradeDefinition
---@field kind g.UpgradeKind
---@field tokenType string? (only for kind == "TOKEN")
---@field price g.Bundle
---@field maxLevel integer?
---@field startingUpgrade boolean? starting-upgrades will be visible at the start, no matter what.
---@field image string?
---@field priceScaling number?
---@field description string?
---@field isHidden (fun(uinfo: g.UpgradeInfo): boolean)?
---@field valueFormatter (string|(fun(x:number):string))[]
local g_UpgradeDefinition = {}
---@param self g.UpgradeInfo
---@param level integer
---@return integer ...
function g_UpgradeDefinition:getValues(level)
end


---@class g.TokenDefinition
---@field maxHealth number
---@field resources g.Bundle
---@field image string?
---@field description string?
---@field particles string?
local g_TokenDefinition = {}


---@class g.UpgradeInfo : g.UpgradeDefinition
---@field type string
---@field name string


---@alias g.TokenInfo g.TokenDefinition|{type:string,name:string}




---@param prestige integer
---@param range g.PrestigeRange|integer
function g.inPrestigeRange(prestige, range)
    if type(range) == "number" then
        return prestige == range
    end
    return (prestige >= range.lower) and (prestige <= range.upper)
end



---@class g._ResourceDefinition
---@field public limitStat string
---@field public image string
---@field public color [number, number, number, number?] Used by resource HUD
---@field public startingLimit number?

---@type g.ResourceType[]
g.RESOURCE_LIST = {}

---@type table<string, g._ResourceDefinition>
local RESOURCES = {}


---@param resId string
---@param tabl g._ResourceDefinition
function g.defineResource(resId, tabl)
    RESOURCES[resId] = tabl
    g.defineStat(tabl.limitStat, tabl.startingLimit or 100)
    table.insert(g.RESOURCE_LIST, resId)
    richtext.defineImage(tabl.image, g.getAtlas(), g.getImageQuad(tabl.image))
end


g.defineResource("money", {
    image="money_icon",
    limitStat="MoneyLimit",
    startingLimit=(consts.DEV_MODE and 10000000000000) or 1000,
    color = {0.71, 0.55, 0.02},
})
g.defineResource("logs", {
    image="logs_icon",
    limitStat="LogLimit",
    color={0.53, 0.5, 0.41}
})
g.defineResource("rocks", {
    image="rocks_icon",
    limitStat="RockLimit",
    color={0.35, 0.35, 0.35}
})
g.defineResource("bones", {
    image="bones_icon",
    limitStat="BoneLimit",
    color={0.75, 0.27, 0.1}
})



---@param r string
---@return boolean
function g.isValidResource(r)
    return not not RESOURCES[r]
end

---@param resId string
local function assertValidResource(resId)
    if not g.isValidResource(resId) then
        error("invalid resource type: " .. tostring(resId), 2)
    end
end

---@param resId string
function g.isResourceUnlocked(resId)
    assertValidResource(resId)
    if g.getPrestige() == 0 and (resId == "bones" or resId == "rocks") then
        return false
    end
    return true
end

---@param resId string
function g.getResourceInfo(resId)
    assertValidResource(resId)
    return RESOURCES[resId]
end



---@param a g.Bundle
---@param b g.Bundle
---@return g.Resources
function g.addBundles(a,b)
    local result = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        result[resId] = (a[resId] or 0) + (b[resId] or 0)
    end
    return result
end



---@return g.Resources
function g.getResources()
    return currentSession.resources
end

---@param resId g.ResourceType
---@return number
function g.getResource(resId)
    assertValidResource(resId)
    return currentSession.resources[resId]
end

---@param resId g.ResourceType
---@return number
function g.getResourceLimit(resId)
    assertValidResource(resId)
    local info = g.getResourceInfo(resId)
    local limit = assert(g.stats[info.limitStat])
    return limit
end


---@param resId g.ResourceType
function g.addResource(resId, amount)
    assertValidResource(resId)
    local r = currentSession.resources
    r[resId] = math.min(math.max(r[resId] + amount, 0), g.getResourceLimit(resId))
end


---@param bundle g.Bundle
function g.addResources(bundle)
    for resId, amount in pairs(bundle) do
        assertValidResource(resId)
        assert(type(amount) == "number", "?")
        g.addResource(resId, amount)
    end
end


---@param bundle g.Bundle
function g.subtractResources(bundle)
    for resId, amount in pairs(bundle) do
        assertValidResource(resId)
        assert(type(amount) == "number", "?")
        g.addResource(resId, -amount)
    end
end





---@param price g.Bundle
---@return boolean
function g.canAfford(price)
    local r = currentSession.resources
    for resId, amount in pairs(price) do
        assertValidResource(resId)
        if amount > (r[resId] or 0) then
            return false
        end
    end
    return true
end




---@param price g.Bundle
---@return boolean
function g.trySubtractResources(price)
    local r = currentSession.resources
    if not g.canAfford(price) then
        return false
    end

    for resId, amount in pairs(price) do
        r[resId] = r[resId] - amount
    end
    return true
end


function g.addResourceFrom(tok, resId, amount)
    local mult = g.ask("getTokenResourceMultiplier", tok, resId)
    -- TODO: MAKE g.call here!  "tokenEarnedResource"
    g.addResource(resId, amount * mult)
end



--------------------------------------------------
-- Upgrades.
--- 
-- g.getUpgradeInfo(upgradeId)
-- g.getUpgradeLevel(uinfo)
-- g.isUpgradeLocked(uinfo)
-- g.isUpgradeHidden(uinfo)
--------------------------------------------------
do

-- Dont ask me how this hash/unhash shit works, i vibecoded it.
-- (And YES, i tested it thoroughly)
-- just make sure args are in range.
local MAX_VAL = 500

---@param x integer (-499 to 499)
---@param y integer (-499 to 499)
---@param prestige integer (0 to 499)
---@return integer
local function hash(x, y, prestige)
    -- M_X = 499500 (999 * 500)
    -- M_Y = 500
    -- Offset = 499
    assert(prestige>=0,"prestige must be positive")
    return (x + 499) * 499500 + (y + 499) * 500 + prestige
end
g.hashPos = hash

---@param h integer
---@return integer x, integer y, integer prestige
local function unhash(h)
    -- M_X = 499500, S_Y = 999, M_Y = 500, Offset = 499
    local p = h % 500
    local r = math.floor(h/500)
    local y = r % 999 - 499
    local x = math.floor(r/999) - 499
    return x, y, p
end


local function assertSmallEnough(x)
    assert(math.abs(x) < MAX_VAL, "Needs to be less than " .. MAX_VAL .. " for hashing to work correctly!")
end

---@type string[]
g.UPGRADE_LIST = {}


---@type {[string]: g.UpgradeInfo?}
local upgradeInfos = {--[[
    [upgradeId] -> Table (contains all info)
]]}

local upgradePositionsHash = {--[[
    hash(x,y,prestige) -> upgrade type
]]}
---@cast upgradePositionsHash {[number]: string?}

---The mapping is `positions: [number,number][] = t[prestige][upgradename]`
---@type table<integer, table<string, [integer, integer][]>>
local upgradePositionByPrestige = {}

-- Load prestiges
do
    local i = 0
    while true do
        local p = "src/upgrades/prestige_"..i..".json"
        if love.filesystem.getInfo(p, "file") then
            log.trace("Loading upgrade prestige position:", p)
            ---@type _dev.UpgradePosition[]
            local ulist = json.decode((assert(love.filesystem.read(p))))
            local upgradePoses = {}

            for _, upos in ipairs(ulist) do
                local positions = upgradePoses[upos.type]
                if not positions then
                    positions = {}
                    upgradePoses[upos.type] = positions
                end
                positions[#positions+1] = {upos.x, upos.y}

                upgradePositionsHash[hash(upos.x, upos.y, i)] = upos.type
            end

            upgradePositionByPrestige[i] = upgradePoses
        else
            break
        end

        i = i + 1
    end
end



---@param id string
---@param name string
---@param def { token: g.TokenDefinition, upgrade: g.UpgradeDefinition|{type:nil,kind:nil} }
function g.defineTokenUpgrade(id, name, def)
    def.upgrade.populateTokenPool = function(self, level, tokens) ---@diagnostic disable-line
        tokens:add(id, level)
    end

    def.upgrade.kind = "TOKEN"
    g.defineUpgrade(id, name, def.upgrade)
    g.defineToken(id, name, def.token)
end







---@param uinfo g.UpgradeInfo
---@param prestige number
local function getNeighbor(uinfo, prestige, dx,dy)
    local upos = g.getUpgradePosition(uinfo, prestige)
    local ux, uy = upos[1]+dx, upos[2]+dy
    local h = hash(ux,uy,prestige)
    local utype = upgradePositionsHash[h]
    if utype then
        return g.getUpgradeInfo(utype)
    end
    return nil
end


local NEIGHBORS = {
    {1,0},{-1,0},{0,1},{0,-1}
}

local function hasAnyPurchasedNeighbors(uinfo)
    -- checks if any of `uinfo`s neighbors have been purchased (level>1)
    local prestige = g.getPrestige()
    for _,c in ipairs(NEIGHBORS) do
        local a = getNeighbor(uinfo, prestige, c[1],c[2])
        if a and g.getUpgradeLevel(a) > 0 then
            return true
        end
    end
    return false
end


local function niceAssert(bool, str, val)
    if not bool then
        str = str or "Assertion failed"
        if str and val then
            str = str .. " " .. tostring(val)
        end
        error(str, 2)
    end
end



local questionCache = {} -- [questionName] -> {upgradeId1, upgradeId2, ...}

local eventCache = {} -- [eventName] -> {upgradeId1, upgradeId2, ...}


-- some upgrades lie across multiple ranges.
-- EG `wood` is purchasable at prestige-0 AND prestige-1. {lower=0, upper=1}
-- And some upgrades are valid across ALL prestiges. {lower=0, upper=INFINITY}




-- a list of "special" functions that upgrades use,
-- that ARENT q-bus or ev-bus. (eg ignore them)
local SPECIAL_FUNCTIONS = {
    getValues = true
}


---@param id string
---@param def g.UpgradeDefinition
function g.defineUpgrade(id, name, def)
    if not (def.kind and UPGRADE_KINDS[def.kind]) then
        error("Invalid upgrade-kind: " .. tostring(def.kind),2)
    end
    def.name = loc(name) ---@diagnostic disable-line
    def.image = id
    def.valueFormatter = def.valueFormatter or {}
    table.insert(g.UPGRADE_LIST, id)

    niceAssert(type(id) == "string")
    niceAssert(g.isImage(def.image), "Invalid image: ", def.image)

    def.type = id

    assert(not upgradeInfos[id], "Redefined upgrade!")
    upgradeInfos[id] = def

    -- Cache questions and events this upgrade can handle
    for key, func in pairs(def) do
        if type(func) == "function"  then
            if g.getQuestionInfo(key) then
                if not questionCache[key] then questionCache[key] = {} end
                table.insert(questionCache[key], id)
            elseif g.isEvent(key) then
                if not eventCache[key] then eventCache[key] = {} end
                table.insert(eventCache[key], id)
            elseif (not SPECIAL_FUNCTIONS[key]) then
                error("Not a question, event, or special-function: "..tostring(key))
            end
        end
    end
end


---@param upgradeId string
---@return g.UpgradeInfo
function g.getUpgradeInfo(upgradeId)
    return assert(upgradeInfos[upgradeId])
end




---@param uinfo g.UpgradeInfo
---@return boolean
function g.isUpgradeLocked(uinfo)
    error([[
        todo: should we have this?

        the idea is that we have some upgrades that can be 
        purchased later on in the game,

        eg. late-game upgrades.
    ]])
end


---@param uinfo g.UpgradeInfo
---@param prestige integer
function g.isUpgradeDefinedInPrestige(uinfo, prestige)
    return not not upgradePositionByPrestige[prestige][uinfo.type]
end



---@param uinfo g.UpgradeInfo
---@param prestige integer
---@return [number, number][]
function g.getUpgradePositions(uinfo, prestige)
    if not g.isUpgradeDefinedInPrestige(uinfo, prestige) then
        error("upgrade '"..uinfo.type.."' not defined in prestige "..prestige)
    end

    return upgradePositionByPrestige[prestige][uinfo.type]
end

---@param uinfo g.UpgradeInfo
---@param prestige integer
---@return [number, number]
function g.getUpgradePosition(uinfo, prestige)
    return g.getUpgradePositions(uinfo, prestige)[1]
end




---@param prestige integer
---@return fun():({x:integer,y:integer},string)
function g.iterateUpgradeTree(prestige)
    return coroutine.wrap(function()
        for k, v in pairs(upgradePositionByPrestige[prestige]) do
            for _, pos in ipairs(v) do
                coroutine.yield({x = pos[1], y = pos[2]}, k)
            end
        end
    end)
end




---@param uinfo g.UpgradeInfo
---@return boolean
function g.isUpgradeHidden(uinfo)
    if not g.isUpgradeDefinedInPrestige(uinfo, g.getPrestige()) then
        -- not in prestige range... its obviously hidden
        return true
    end

    if g.getUpgradeLevel(uinfo) > 0 then
        return false -- cant be hidden if level>0
    end
    if uinfo.isHidden and uinfo:isHidden() then
        return true
    end

    if uinfo.startingUpgrade then
        return false
    end

    local isHidden = not hasAnyPurchasedNeighbors(uinfo)
    return isHidden
end


--- Floors a number, removing insignificant digits.
--- Useful for adjusting prices to look a bit "nicer"
---
--- g.floorSignificant(12345, 1) -> 10000
--- g.floorSignificant(12345, 2) -> 12000
--- g.floorSignificant(12345, 3) -> 12300
--- g.floorSignificant(12345, 4) -> 12340
--- g.floorSignificant(12345, 5) -> 12345
---@param value number
---@param nsig integer
---@return integer
local function floorSignificant(value, nsig)
	local zeros = math.floor(math.log10(math.max(math.abs(value), 1)))
	local mulby = 10 ^ (1+math.max(zeros-nsig, -1))
	return math.floor(math.floor(value / mulby) * mulby)
end

local function modifyUpgradePrice(uinfo, val, level)
    level = level or g.getUpgradeLevel(uinfo)
    local mult = (uinfo.priceScaling or consts.DEFAULT_UPGRADE_PRICE_SCALING) ^ level
    val = floorSignificant(val*mult, 2)
    return val
end


---WARNING: This incurs a table allocation.
---@param uinfo g.UpgradeInfo
---@param level number? Optional; defaults to the current upgrade's level.
---@return g.Bundle
function g.getUpgradePrice(uinfo, level)
    local truePrice = {}
    for _,res in ipairs(g.RESOURCE_LIST)do
        if uinfo.price[res] then
            truePrice[res] = modifyUpgradePrice(uinfo, uinfo.price[res], level)
        end
    end
    return truePrice
end


---@param uinfo g.UpgradeInfo
---@param level number? Optional; defaults to the current upgrade's level.
---@return boolean
function g.canAffordUpgrade(uinfo, level)
    level = level or g.getUpgradeLevel(uinfo)
    for res,p in pairs(uinfo.price) do
        local truePrice = modifyUpgradePrice(uinfo, p, level)
        if truePrice > g.getResource(res) then
            return false -- cant afford
        end
    end
    return true
end



---@param uinfo g.UpgradeInfo
---@return boolean wasPurchased
function g.tryBuyUpgrade(uinfo)
    local session = g.getSn()
    local typ = uinfo.type
    if g.getUpgradeLevel(uinfo) >= (uinfo.maxLevel or consts.DEFAULT_UPGRADE_MAX_LEVEL) then
        return false -- already max level
    end
    if g.canAffordUpgrade(uinfo) then
        local price = g.getUpgradePrice(uinfo)
        g.subtractResources(price)
        session.upgradeLevels[typ] = (session.upgradeLevels[typ] or 0) + 1
        return true
    end
    return false
end



---@param uinfo g.UpgradeInfo
---@return number
function g.getUpgradeLevel(uinfo)
    local session = g.getSn()
    assert(upgradeInfos[uinfo.type], "Invalid upgrade")
    return (session.upgradeLevels[uinfo.type] or 0)
end



function askUpgrades(question, ...)
    local questionInfo = g.getQuestionInfo(question)
    local reducer = questionInfo.reducer
    local defaultValue = questionInfo.defaultValue
    local upgradeIds = questionCache[question]

    local result = defaultValue

    if not upgradeIds then return result end

    for _, upgradeId in ipairs(upgradeIds) do
        local uinfo = g.getUpgradeInfo(upgradeId)
        local level = g.getUpgradeLevel(uinfo)
        if level > 0 then
            local answerFunc = uinfo[question]
            if answerFunc then
                local answer = answerFunc(uinfo, level, ...) or defaultValue
                result = reducer(answer, result)
            end
        end
    end

    return result
end


function callUpgrades(event, ...)
    local upgradeIds = eventCache[event]
    if not upgradeIds then return end

    for _, id in ipairs(upgradeIds) do
        local uinfo = g.getUpgradeInfo(id)
        local level = g.getUpgradeLevel(uinfo)
        if level and level > 0 then
            local eventFunc = uinfo[event]
            if eventFunc then
                eventFunc(uinfo, level, ...)
            end
        end
    end
end




end














local tokenDefinitions = {--[[
    [tokenType] -> {
        health = X,
        
        onUpdate = func,
        onDestroyed = func
    }
]]}
---@cast tokenDefinitions table<string,g.TokenInfo>

local tokenMts = {--[[
    [tokenType] -> tokenMt
]]}

g.TOKEN_LIST = {}


---@param tokType string
---@param tabl g.TokenDefinition
function g.defineToken(tokType, name, tabl)
    assert(not tabl.type, ".type is a reserved field!")
    assert(tabl.maxHealth, "Tokens need .maxHealth")
    assert(tabl.resources, "Tokens need .resources")
    tabl.type = tokType ---@diagnostic disable-line
    tabl.image = tabl.image or tokType ---@diagnostic disable-line
    tabl.name = loc(name) ---@diagnostic disable-line
    tokenDefinitions[tokType] = tabl
    tokenMts[tokType] = {__index = tabl}
    g.TOKEN_LIST[#g.TOKEN_LIST+1] = tokType
end

---@param tokType string
function g.getTokenInfo(tokType)
    if not tokenDefinitions[tokType] then
        error("token '"..tokType.."' does not exist")
    end
    return tokenDefinitions[tokType]
end


local DEFAULT_MIN_SPACING = 12

---@param world g.World
local function getRandomPos(world, x, y, w, h, minSpacing, maxAttempts)
    maxAttempts = maxAttempts or 20
    minSpacing = minSpacing or DEFAULT_MIN_SPACING
    for attempt = 1, maxAttempts do
        local px = x + math.random() * w
        local py = y + math.random() * h
        local tooClose = false

        world.tokenPartition:query(px, py, function(tok)
            local dx = px - tok.x
            local dy = py - tok.y
            local distSq = dx*dx + dy*dy
            if distSq < minSpacing * minSpacing then
                tooClose = true
                return true -- stop iteration early
            end
        end)

        if not tooClose then
            return px, py
        end
    end

    return nil, nil
end


--[[

IMPORTANT NOTE:

These functions all tag into the main-world.
In the future; if there are multiple-worlds; 
we will want to make this more generic.

]]



---@class g.Entity
---@field type string
---@field x number
---@field y number
---@field image string?
---@field update fun(ent: g.Entity, dt:number)
---@field draw fun(ent: g.Entity)
local Entity = {}




function g.addEntity(ent)
    local w = g.getMainWorld()
    assert(type(ent) == "table")
    assert(ent.type)
    assert(ent.update)
    assert(ent.draw)
    w.entities:addBuffered(ent)
end


function g.removeEntity(ent)
    local w = g.getMainWorld()
    w.entities:removeBuffered(ent)
end






---@class g.Token: g.TokenDefinition
---@field type string
---@field x number
---@field y number
---@field id number
---@field health number
---@field maxHealth number
---@field image string
---@field resources g.Bundle
---@field timeSinceHitStart number Time since last `tryHitToken` is initiated (it's not immediately hit).
---@field timeSinceHit number Time since `tryHitToken` actually hits the token.
---@field timeSinceDamaged number
---@field timeAlive number
---
---@field slimed boolean?
---@field ___destroyed boolean?
local g_Token = {}




---@return number?
---@return number
function g.getRandomPositionForToken()
    local world = g.getMainWorld()
    local pad=4
    return getRandomPos(world, pad,pad, world.WIDTH-pad*2,world.HEIGHT-pad*2) ---@diagnostic disable-line
end


---@param filter (fun(tok:g.Token):boolean)?
---@return g.Token?
function g.getRandomToken(filter)
    local maxTries = 30
    for _=1, maxTries do
        local tokens = currentSession.mainWorld.tokens
        local len = #tokens
        local i = math.min(math.max(1, math.floor(love.math.random() * len)), len)
        local tok = tokens[i]
        if tok then
            if (not filter) or filter(tok) then
                return tok
            end
        end
    end
    return nil
end



-- each token is given a unique id. (Used for animations and stuff)
local currentTokenId = 1

---@param tokType string
---@param x number
---@param y number
---@return g.Token
function g.spawnToken(tokType, x,y)
    local w = g.getMainWorld()
    assert(type(tokType) == "string")
    assert(x and y)
    local tabl = tokenDefinitions[tokType]
    if not (tabl) then
        error("Invalid token type: " .. tostring(tokType))
    end

    currentTokenId = currentTokenId + 1

    local tok = setmetatable({
        x = x,
        y = y,
        health = tabl.maxHealth,

        id = currentTokenId,

        timeAlive = 0,
        timeSinceHitStart = 0xffffffffff,
        timeSinceHit = 0xffffffffff,
        timeSinceDamaged = 0xfffffffff,
    }, tokenMts[tokType])

    w.tokens:addBuffered(tok)
    return tok
end


---@param tok g.Token
local function spawnTokenResource(tok)
    local hud = g.getHUD()
    if tok.resources.money then
        hud:spawnResourceParticle("money", tok.x, tok.y, tok.resources.money)
    end
    if tok.resources.logs then
        hud:spawnResourceParticle("logs", tok.x, tok.y, tok.resources.logs)
    end
    if tok.resources.rocks then
        hud:spawnResourceParticle("rocks", tok.x, tok.y, tok.resources.rocks)
    end
    if tok.resources.bones then
        hud:spawnResourceParticle("bones", tok.x, tok.y, tok.resources.bones)
    end
end

---@param tok g.Token
---@return boolean
function g.destroyToken(tok)
    if tok.___destroyed then
        -- already been destroyed.
        return false
    end

    local w = g.getMainWorld()
    g.call("tokenDestroyed", tok)
    g.addResources(tok.resources)
    spawnTokenResource(tok)
    if tok.particles then
        g.spawnParticle(tok.particles, tok.x,tok.y, love.math.random(3,5))
    end

    tok.___destroyed = true
    w.tokens:removeBuffered(tok)

    -- todo: rework/rethink this.
    -- Each token should have different "sound"
    g.playSound("pop", 1, 1, 0.15)
    return true
end



---@param tok g.Token
---@param dmg number
function g.damageToken(tok, dmg)
    local dmgMult = g.ask("getTokenDamageMultiplier", tok)
    dmg = dmg * dmgMult
    tok.health = tok.health - dmg
    g.call("tokenDamaged", tok, dmg)

    -- todo: rework all this.
    if love.math.random()<0.5 then
        g.playSound("hit_billiard", 1, 0.18, 0.3)
    else
        g.playSound("hit_soft", 1, 0.18, 0.3)
    end

    tok.timeSinceDamaged = 0
    if tok.health <= 0 then
        g.destroyToken(tok)
    end
end


--- checks if a token is being hit
---@param tok g.Token
---@return boolean
function g.isBeingHit(tok)
    local time = tok.timeSinceHitStart
    return time <= g.stats.HitDuration
end

---@param tok g.Token
function g.tryHitToken(tok)
    if not g.isBeingHit(tok) then
        tok.timeSinceHitStart = 0
        g.call("tokenHitStart", tok)
    end
end


local hud = HUD()

function g.getHUD()
    return hud
end



-- g.playSound defined here
do

local MAX_SOURCE_POOL = 15
---@type table<string, love.Source[]>
local sourcePool = {} -- first source always the one to clone

---@param name string
local function getSourceFromPool(name)
    local sources = sourcePool[name]
    if not sources then
        error("invalid sound '"..name.."'")
    end

    -- Linear search won't be expensive as long as source pool is low
    for _, s in ipairs(sources) do
        if not s:isPlaying() then
            s:stop()
            return s
        end
    end

    if #sources < MAX_SOURCE_POOL then
        -- first source always the one to clone
        local s = sources[1]:clone()
        sources[#sources+1] = s
        s:stop()
        return s
    end

    return nil
end

---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playSound(soundname, pitch, volume, pitchVar, volumeVar)
    local s = getSourceFromPool(soundname)
    if not s then
        return false
    end

    local dv = (volumeVar or 0) * (love.math.random()-0.5)*2
    local dp = (pitchVar or 0) * (love.math.random()-0.5)*2

    pitch = (pitch or 1) + dp
    volume = math.max((volume or 1) + dv, 0)
    if pitch <= 0 then
        error("invalid pitch "..pitch)
    end

    s:setPitch(pitch)
    s:setVolume(volume)
    s:play()
    return true
end

local validExtensions = {
    wav = true,
    mp3 = true,
    ogg = true,
    flac = true
}

---@param path string
local function loadSound(path)
    local pathrev = path:reverse()
    local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

    if validExtensions[ext] then
        local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

        if #basename > 0 then
            local name = basename:sub(1, -#ext - 2)
            local mainSource = love.audio.newSource(path, "static")
            print("n:",name)
            sourcePool[name] = {mainSource}
        end
    end
end

g.walkDirectory("assets/sfx", loadSound)


end



---@param particleName string
---@param x number
---@param y number
---@param amount integer?
function g.spawnParticle(particleName, x, y, amount)
    return currentSession.mainWorld.particles:spawnParticles(particleName, x, y, amount)
end



g.COLORS = {
    UPGRADE_KINDS = {
        HARVESTING = objects.Color("#" .. "FFCB8B14"),
        TOKEN = objects.Color("#" .. "FF1479CB"),
        TOKEN_MODIFIER = objects.Color("#" .. "FF15C39A"),
        MISC = objects.Color("#" .. "FFFFFFFF"),
    },

    CANT_AFFORD = objects.Color("#".."FFC81515"),
    MONEY = objects.Color(g.getResourceInfo("money").color),
    RECOMMENDED = objects.Color("#".."FF9DEC4E"),
}


richtext.defineImage("health_icon", g.getAtlas(), g.getImageQuad("health_icon"))

return g
