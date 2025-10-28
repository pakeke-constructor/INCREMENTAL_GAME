

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")

local Session = require("src.Session")
local HUD = require("src.ui.hud.hud")

---@class g
local g = {}





---@type g.Session
local currentSession

function g.newSession()
    currentSession = Session()
end

---@param path string
function g.loadSession(path)
    local contents = assert(love.filesystem.read(path))
    local jsondata = json.decode(contents)
    currentSession = Session.deserialize(jsondata)
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
local callEffects, askEffects
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
    callEffects(ev, arg1, ...)
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

    val = reducer(val, askUpgrades(q, arg1, ...))
    return reducer(val, askEffects(q, arg1, ...))
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
g.walkDirectory("src/entities", loadImage)

end



-- metrics are "temporary" values that are set 0 when the game starts.
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
---@field getValues (fun(uinfo: g.UpgradeInfo, level: integer):number)?
---@field valueFormatter ((string|(fun(x:number):string))[])?
---@field getEntityCount (fun(uinfo: g.UpgradeInfo, level: integer):integer)?
---@field spawnEntity (fun(uinfo: g.UpgradeInfo):g.Entity)?
---@field perSecondUpdate (fun(uinfo: g.UpgradeInfo, level: integer))?
local g_UpgradeDefinition = {}


---@class g.TokenDefinition
---@field maxHealth number
---@field resources g.Bundle
---@field image string?
---@field description string?
---@field particles string?
---@field category g.Category?
local g_TokenDefinition = {}


---@class g.UpgradeInfo : g.UpgradeDefinition
---@field type string
---@field name string
---@field maxLevel integer
---@field description localization.Interpolator?
---@field valueFormatter (string|(fun(x:number):string))[]


---@alias g.TokenInfo g.TokenDefinition|{type:string,name:string}


---@class g.EffectDefinition
---@field public description string?
---@field public image string?
---@field public isDebuff boolean?

---@class g.EffectInfo: g.EffectDefinition
---@field public type string
---@field public name string
---@field public image string
---@field public isDebuff boolean



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


---@param a g.Bundle|number
---@param b g.Bundle|number
---@return g.Resources
function g.multBundles(a,b)
    --[[
    NOTE: this operation is NOT commutative.

    this is to compensate for how qbuses work.
    ]]
    local result = {}

    if type(a) == "number" then
        ---@type g.Bundle
        local temp = {}
        for _, resId in ipairs(g.RESOURCE_LIST) do
            temp[resId] = a
        end
        a = temp
    end

    if type(b) == "number" then
        for _, resId in ipairs(g.RESOURCE_LIST) do
            result[resId] = (a[resId] or 1) * b
        end
    else
        for _, resId in ipairs(g.RESOURCE_LIST) do
            result[resId] = (a[resId] or 1) * (b[resId] or 1)
        end
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
---@param resourcePool g.Bundle?
---@return boolean
function g.canAfford(price, resourcePool)
    local r = resourcePool or currentSession.resources
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



---@param tok g.Token
---@param bundle g.Bundle
local function spawnTokenResource(tok, bundle)
    local hud = g.getHUD()
    if bundle.money then
        hud:spawnResourceParticle("money", tok.x, tok.y, bundle.money)
    end
    if bundle.logs then
        hud:spawnResourceParticle("logs", tok.x, tok.y, bundle.logs)
    end
    if bundle.rocks then
        hud:spawnResourceParticle("rocks", tok.x, tok.y, bundle.rocks)
    end
    if bundle.bones then
        hud:spawnResourceParticle("bones", tok.x, tok.y, bundle.bones)
    end
end



---@param tok g.Token
---@param bundle g.Bundle
---@return g.Bundle
function g.addResourceFrom(tok, bundle)
    local mod = g.ask("getTokenResourceModifier", tok)
    local mult = g.ask("getTokenResourceMultiplier", tok)

    bundle = g.addBundles(bundle, mod)
    bundle = g.multBundles(bundle, mult)

    -- TODO: MAKE g.call here?  "tokenEarnedResource"
    g.addResources(bundle)
    spawnTokenResource(tok, bundle)
    return bundle
end



--------------------------------------------------
-- Categories
--------------------------------------------------

---@alias g.Category
---| "grass"
---| "wood"
---| "cat"
---| "mushroom"

---@type table<g.Category, true|nil>
g.CATEGORIES = {
    grass = true,
    wood = true,
    cat = true,
    mushroom = true
}



--------------------------------------------------
-- Temporary Effects
--------------------------------------------------

---@type string[]
g.EFFECT_LIST = {}
---@type table<string, g.EffectInfo>
local EFFECT_INFOS = {}
---@type table<string, string[]>
local EFFECT_QUESTION_CACHE = {}
---@type table<string, string[]>
local EFFECT_EVENT_CACHE = {}

---@param id string
---@param name string
---@param def g.EffectDefinition
function g.defineEffect(id, name, def)
    if EFFECT_INFOS[id] then
        error("effect '"..id.."' is already defined")
    end

    for k, v in pairs(def) do
        if type(v) == "function" then
            g.assertIsQuestionOrEvent(k)

            -- Add to cache
            if g.getQuestionInfo(k) then
                if EFFECT_QUESTION_CACHE[k] then
                    table.insert(EFFECT_QUESTION_CACHE[k], id)
                else
                    EFFECT_QUESTION_CACHE[k] = {id}
                end
            elseif g.isEvent(k) then
                if EFFECT_EVENT_CACHE[k] then
                    table.insert(EFFECT_EVENT_CACHE[k], id)
                else
                    EFFECT_EVENT_CACHE[k] = {id}
                end
            end
        end
    end

    local img = def.image or id
    if not g.isImage(img) then
        error("image '"..img.."' does not exist")
    end

    ---@cast def g.EffectInfo
    def.name = name
    def.type = id
    def.image = img
    def.isDebuff = not not def.isDebuff
    g.EFFECT_LIST[#g.EFFECT_LIST+1] = id
    EFFECT_INFOS[id] = def
end

---@param id string
---@param duration number
function g.grantEffect(id, duration)
    local effInfo = EFFECT_INFOS[id]
    if not effInfo then
        error("effect '"..id.."' is not defined")
    end
    return currentSession.mainWorld:_grantEffect(id, duration)
end

---@param id string
function g.getEffectInfo(id)
    local effInfo = EFFECT_INFOS[id]
    if not effInfo then
        error("effect '"..id.."' is not defined")
    end

    return effInfo
end


---@param ev string
---@param ... any
function callEffects(ev, ...)
    local effIds = EFFECT_EVENT_CACHE[ev]
    if effIds then
        for _, effId in ipairs(effIds) do
            local dur = currentSession.mainWorld.effectDurations[effId] or 0
            if dur > 0 then
                EFFECT_INFOS[effId][ev](dur, ...)
            end
        end
    end
end


function askEffects(q, ...)
    local questionInfo = g.getQuestionInfo(q)
    local reducer = questionInfo.reducer
    local defaultValue = questionInfo.defaultValue
    local effIds = EFFECT_QUESTION_CACHE[q]

    local result = defaultValue

    if effIds then
        for _, effId in ipairs(effIds) do
            local dur = currentSession.mainWorld.effectDurations[effId] or 0
            if dur > 0 then
                local answer = EFFECT_INFOS[effId][q](dur, ...) or defaultValue
                result = reducer(answer, result)
            end
        end
    end

    return result
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
---@cast upgradePositionsHash {[integer]: (string|_dev.Connector)?}

---The mapping is `positions: {x:integer,y:integer} = t[prestige][upgradename]`
---@type table<integer, table<string, _dev.UpgradePosition>>
local upgradePositionByPrestige = {}

---@param x integer
---@param y integer
---@param p integer
---@param t any
local function ensureEmpty(x, y, p, t)
    local h = hash(x, y, p)
    if upgradePositionsHash[h] then
        error(string.format(
            "prestige %d position %dx%d trying to put '%s' on '%s'",
            p,
            x,
            y,
            t,
            tostring(upgradePositionsHash[h])
        ))
    end
    return h
end

-- Load prestiges
do
    local i = 0
    while true do
        local p = "src/upgrades/prestige_"..i..".json"
        if love.filesystem.getInfo(p, "file") then
            log.trace("Loading upgrade prestige position:", p)
            ---@type _g.UpgradePrestigeData
            local r = json.decode((assert(love.filesystem.read(p))))

            for utype, upos in pairs(r.upgrades) do
                local h = ensureEmpty(upos.x, upos.y, i, utype)
                upgradePositionsHash[h] = utype
            end

            for _, cpos in ipairs(r.connectors) do
                for j = 0, cpos.length - 1 do
                    local dx = cpos.isVertical and 0 or j
                    local dy = cpos.isVertical and j or 0
                    local h = ensureEmpty(cpos.x + dx, cpos.y + dy, i, "connector")
                    upgradePositionsHash[h] = cpos
                end
            end

            upgradePositionByPrestige[i] = r.upgrades
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







---@param con _dev.Connector
---@param prestige integer
---@return [string, string]|nil
local function getTargetConnector(con, prestige)
    local h1, h2 = nil, nil
    if con.isVertical then
        -- Check utype on top and bottom
        h1 = hash(con.x, con.y - 1, prestige)
        h2 = hash(con.x, con.y + con.length, prestige)
    else
        -- Check utype on left and right
        h1 = hash(con.x - 1, con.y, prestige)
        h2 = hash(con.x + con.length, con.y, prestige)
    end

    local utype1 = upgradePositionsHash[h1]
    local utype2 = upgradePositionsHash[h2]

    if type(utype1) == "string" and type(utype2) == "string" then
        return {utype1, utype2}
    end

    return nil
end

---@param uinfo g.UpgradeInfo
---@param prestige integer
local function getNeighbor(uinfo, prestige, dx,dy)
    local upos = g.getUpgradePosition(uinfo, prestige)
    local ux, uy = upos.x+dx, upos.y+dy
    local h = hash(ux,uy,prestige)
    local utype = upgradePositionsHash[h]
    local vertical = nil -- if it's nil, inegligible for connector search
    if dx ~= 0 and dy == 0 then
        vertical = false
    elseif dx == 0 and dy ~= 0 then
        vertical = true
    end

    if utype then
        if type(utype) == "string" then
            return g.getUpgradeInfo(utype)
        elseif vertical ~= nil and utype.isVertical == vertical then
            local target = getTargetConnector(utype, prestige)
            -- The target connector returns 2 types across each endpoints.
            -- One of it is equal to `uinfo.type`. We want the one not equal to `uinfo.type`.
            if target then
                if target[1] == uinfo.type then
                    return g.getUpgradeInfo(target[2])
                elseif target[2] == uinfo.type then
                    return g.getUpgradeInfo(target[1])
                end
            end
        end
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
    getValues = true,
    getEntityCount = true,
    spawnEntity = true
}


---@param id string
---@param def g.UpgradeDefinition
function g.defineUpgrade(id, name, def)
    if not (def.kind and UPGRADE_KINDS[def.kind]) then
        error("Invalid upgrade-kind: " .. tostring(def.kind),2)
    end

    ---@cast def g.UpgradeInfo
    def.name = loc(name)
    if def.description then
        def.description = localization.newInterpolator(def.description) ---@diagnostic disable-line
    end

    def.image = def.image or id
    def.valueFormatter = def.valueFormatter or {}
    def.maxLevel = def.maxLevel or consts.DEFAULT_UPGRADE_MAX_LEVEL
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
    local uinfo = upgradeInfos[upgradeId]
    if not uinfo then
        error("unknown upgrade id '"..upgradeId.."'")
    end
    return uinfo
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
---@return {x:integer,y:integer}
function g.getUpgradePosition(uinfo, prestige)
    if not g.isUpgradeDefinedInPrestige(uinfo, prestige) then
        error("upgrade '"..uinfo.type.."' not defined in prestige "..prestige)
    end

    return upgradePositionByPrestige[prestige][uinfo.type]
end




---@param prestige integer
---@return fun():({x:integer,y:integer},string)
function g.iterateUpgradeTree(prestige)
    return coroutine.wrap(function()
        for k, v in pairs(upgradePositionByPrestige[prestige]) do
            coroutine.yield(v, k)
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



---Retireves list of upgrade connectors adjacent to the upgrade.
---
---TODO: Not sure if this should be in g. but upgrade_scene needs it.
---@param uinfo g.UpgradeInfo
---@param prestige integer
function g.getUpgradeConnectors(uinfo, prestige)
    local pos = g.getUpgradePosition(uinfo, prestige)
    ---@type _dev.Connector[]
    local result = {}
    for _, d in ipairs(NEIGHBORS) do
        local h = hash(pos.x + d[1], pos.y + d[2], prestige)
        local isVertical = d[1] == 0 and d[2] ~= 0
        local con = upgradePositionsHash[h]

        if con and type(con) ~= "string" and con.isVertical == isVertical then
            -- Also make sure none of the connector target is hidden
            local target = getTargetConnector(con, prestige)
            if target then
                local hidden1 = g.isUpgradeHidden(g.getUpgradeInfo(target[1]))
                local hidden2 = g.isUpgradeHidden(g.getUpgradeInfo(target[2]))
                if not (hidden1 or hidden2) then
                    result[#result+1] = con
                end
            end
        end
    end

    return result
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
    local mult2 = g.ask("getUpgradePriceMultiplier")
    val = floorSignificant(val*mult*mult2, 2)
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
    if g.getUpgradeLevel(uinfo) >= uinfo.maxLevel then
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
---@type table<g.TokenInfo, true|nil>
local reverseTokMt = {}

g.TOKEN_LIST = {}


---@param tokType string
---@param tabl g.TokenDefinition
function g.defineToken(tokType, name, tabl)
    assert(not tabl.type, ".type is a reserved field!")
    assert(tabl.maxHealth, "Tokens need .maxHealth")
    assert(tabl.resources, "Tokens need .resources")
    if tabl.category and not g.CATEGORIES[tabl.category] then
        error("invalid category '"..tabl.category.."'")
    end
    tabl.type = tokType ---@diagnostic disable-line
    tabl.image = tabl.image or tokType ---@diagnostic disable-line
    tabl.name = loc(name) ---@diagnostic disable-line
    tokenDefinitions[tokType] = tabl
    local mt = {__index = tabl}
    tokenMts[tokType] = mt
    reverseTokMt[mt] = true
    g.TOKEN_LIST[#g.TOKEN_LIST+1] = tokType
end

---@param obj any
function g.isToken(obj)
    local mt = getmetatable(obj)
    return not not reverseTokMt[mt]
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



-- ENTITY FUNCTIONS
do

---@class g.Entity
---@field type string
---@field x number
---@field y number
---@field id integer
---@field shadowRadius number?
---@field sx number?
---@field sy number?
---@field ox number?
---@field oy number?
---@field rot number?
---@field image string?
---@field lifetime number?
---@field blendmode love.BlendMode?
---@field blendalphamode love.BlendAlphaMode?
---@field init (fun(ent:g.Entity))?
---@field update (fun(ent: g.Entity, dt:number))?
---@field perSecondUpdate (fun(e:g.Entity))?
---@field drawBelow (fun(ent: g.Entity))?
---@field draw (fun(ent: g.Entity))?
local Entity = {}


---@type table<string, table>
local ENTITY_DEFS = {}
---@type table<table, true|nil>
local REVERSE_ENTITY_MT = {}

---@param type string
---@param etype g.Entity|{x:nil,y:nil,type:nil}
function g.defineEntity(type, etype)
    -- TODO, assertions maybe?
    assert(etype.x == nil, "x is reserved field")
    assert(etype.y == nil, "y is reserved field")
    assert(etype.type == nil, "type is reserved field")
    etype.type = type
    local mt = {__index=etype}
    ENTITY_DEFS[type] = mt
    REVERSE_ENTITY_MT[mt] = true
end


local currentId = 0

---@param ename string
---@param x number
---@param y number
---@return g.Entity
function g.spawnEntity(ename, x,y)
    local w = g.getMainWorld()
    local mt = ENTITY_DEFS[ename]
    if not mt then
        error("Invalid entity type: " .. tostring(ename))
    end

    ---@type g.Entity
    local ent = setmetatable({
        id = currentId,
        x=x,y=y, type=ename
    }, mt)

    if ent.init then
        ent:init()
    end

    currentId = currentId + 1
    assert(type(ent) == "table")
    assert(ent.type)
    w.entities:addBuffered(ent)
    return ent
end

function g.isEntity(obj)
    local mt = getmetatable(obj)
    return not not REVERSE_ENTITY_MT[mt]
end


function g.removeEntity(ent)
    local w = g.getMainWorld()
    w.entities:removeBuffered(ent)
end


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
    tok.maxHealth = tabl.maxHealth * g.ask("getTokenMaxHealthMultiplier", tok)
    tok.health = tok.maxHealth

    w.tokens:addBuffered(tok)
    g.call("tokenSpawned", tok)
    return tok
end


---@param tok g.Token
---@return boolean
function g.destroyToken(tok)
    if tok.___destroyed then
        -- already been destroyed.
        return false
    end
    tok.___destroyed = true

    local w = g.getMainWorld()
    g.call("tokenDestroyed", tok)

    g.addResourceFrom(tok, tok.resources)

    if tok.particles then
        g.spawnParticle(tok.particles, tok.x,tok.y, love.math.random(3,5))
    end

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
    local dmgMod = g.ask("getTokenDamageModifier", tok)
    dmg = (dmg + dmgMod) * dmgMult
    tok.health = tok.health - dmg
    g.call("tokenDamaged", tok, dmg)

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

---@param tok g.Token
function g.hitImmediately(tok)
    -- hits a token immediately; no checks, no buildup.
    local hitMult = g.ask("getTokenHitMultiplier", tok)
    tok.timeSinceHit = 0
    g.call("tokenHit", tok)
    g.damageToken(tok, hitMult * g.stats.HitDamage)

    g.spawnParticle("crosshair", tok.x, tok.y, 1)

    local i = love.math.random(1,3)
    local s = "hit_generic_"..i
    g.playSound(s, 1,0.1,0.2,0.2)

    -- todo: rework all this.
    if tok.category == "grass" then
        if love.math.random()<0.3 then
            g.playSound("hit_grass",1,0.15, 0.1)
        else
            g.playSound("hit_grass2",1,0.15, 0.1)
        end
    elseif love.math.random()<0.5 then
        g.playSound("hit_billiard", 1, 0.18, 0.3)
    else
        g.playSound("hit_soft", 1, 0.18, 0.3)
    end
end


---@param x number
---@param y number
---@param radius number
---@param func fun(tok:g.Token)
function g.iterateTokensInArea(x, y, radius, func)
    g.getMainWorld().tokenPartition:query(x, y, function(tok)
        if math.distance(x-tok.x, y-tok.y) <= radius then
            func(tok)
        end
    end, radius)
end



local MAX_QUEUED_TOKENS = 100

---@param tok string
---@param x number?
---@param y number?
function g.stackToken(tok, x, y)
    currentSession.tokenQueue[#currentSession.tokenQueue+1] = tok

    while #currentSession.tokenQueue > MAX_QUEUED_TOKENS do
        g.popStackedToken()
    end

    if x and y then
        g.getHUD().profileHUD:spawnParticle(tok, x, y)
    end
end

---@return string?
function g.peekStackedToken()
    return currentSession.tokenQueue[1]
end

---@return string
function g.popStackedToken()
    assert(#currentSession.tokenQueue > 0, "token queue is empty")
    return table.remove(currentSession.tokenQueue, 1)
end




local hud = HUD()

function g.getHUD()
    return hud
end



-- g.playSound defined here
do

local MAX_SOURCE_POOL = 4
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

    SHADOW = objects.Color(0,0,0,0.4),

    CANT_AFFORD = objects.Color("#".."FFC81515"),
    MONEY = objects.Color(g.getResourceInfo("money").color),
    RECOMMENDED = objects.Color("#".."FF9DEC4E"),
    UPGRADE_CONNECTOR = objects.Color("#".."FF123A85")
}


richtext.defineImage("health_icon", g.getAtlas(), g.getImageQuad("health_icon"))

return g
