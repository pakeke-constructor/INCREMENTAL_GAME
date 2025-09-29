

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")
local upgrades = require("src.upgrades.upgrades")

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

    upgrades.call(ev, arg1, ...)
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

    return reducer(val, upgrades.ask(q, arg1, ...))
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
                formatted = string.format("%.0f", scaled)
            elseif scaled >= 10 then
                formatted = string.format("%.1f", scaled)
            else
                formatted = string.format("%.2f", scaled)
            end
            formatted = formatted:gsub("%.?0+$", "")

            return (isNegative and "-" or "") .. formatted .. suffix[2]
        end
    end
    return (isNegative and "-" or "") .. tostring(num)
end


end



-- g.drawImage defined here!
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
    atlas:draw(quad, x, y, r, sx, sy, ox * w, oy * h, kx, ky)
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


---@class g.stats
g.stats = {}

g.stats.HitDuration = g.defineStat("HitDuration", 0.4)
g.stats.HitDamage = g.defineStat("HitDamage", 1)
g.stats.HarvestArea = g.defineStat("HarvestArea", 30)


g.stats.MoneyLimit = g.defineStat("MoneyLimit", 10000)

g.stats.LogLimit = g.defineStat("LogLimit", 1000)
g.stats.RockLimit = g.defineStat("RockLimit", 1000)
g.stats.BoneLimit = g.defineStat("BoneLimit", 1000)



---@alias g.Bundle {money?: number, bones?: number, rocks?: number, logs?: number}

---@alias g.Resources {money: number, bones: number, rocks: number, logs: number}

---@alias g.ResourceType "money"|"logs"|"rocks"|"bones"

---@alias g.PrestigeRange {lower: integer, upper: integer}




---@class g.UpgradeDefinition
---@field prestige number|g.PrestigeRange
---@field x number
---@field y number
---@field image string
---@field price g.Bundle
---@field isHidden (fun(uinfo: g.UpgradeInfo): boolean)?
local g_UpgradeDefinition = {}


---@class g.TokenDefinition
---@field maxHealth number
---@field image string
---@field resources g.Bundle
local g_TokenDefinition = {}


---@alias g.UpgradeInfo g.UpgradeDefinition|{type:string}


---@alias g.TokenInfo g.TokenDefinition|{type:string}




---@param prestige integer
---@param range g.PrestigeRange|integer
function g.inPrestigeRange(prestige, range)
    if type(range) == "number" then
        return prestige == range
    end
    return (prestige >= range.lower) and (prestige <= range.upper)
end


local VALID_RESOURCES = {
    money=true,
    logs=true,
    rocks=true,
    bones=true,
}

local RESOURCE_LIMIT_STAT_NAMES = {
    money = "MoneyLimit",
    logs = "LogLimit",
    rocks = "RockLimit",
    bones = "BoneLimit"
}


---@param r string
---@return boolean
function g.isValidResource(r)
    return VALID_RESOURCES[r]
end

---@param resId string
local function assertValidResource(resId)
    if not g.isValidResource(resId) then
        error("invalid resource type: " .. tostring(resId), 2)
    end
end


---@param a g.Bundle
---@param b g.Bundle
---@return g.Resources
function g.addBundles(a,b)
    return {
        money = (a.money or 0) + (b.money or 0),
        bones = (a.bones or 0) + (b.bones or 0),
        rocks = (a.rocks or 0) + (b.rocks or 0),
        logs = (a.logs or 0) + (b.logs or 0)
    }
end


---@param x number
function g.addMoney(x)
    currentSession.resources.money = math.min(currentSession.resources.money + x, g.stats.MoneyLimit)
end

---@param x number
---@return boolean
function g.trySubtractMoney(x)
    -- used for shopping:  
    -- if g.trySubtractMoney(COST) then  getUpgrade()  end
    local r = currentSession.resources
    if x <= r.money then
        r.money = r.money - x
        return true
    end
    return false
end

---@return number
function g.getMoney()
    return currentSession.resources.money
end

---@param x number
function g.addBones(x)
    currentSession.resources.bones = math.min(currentSession.resources.bones + x, g.stats.BoneLimit)
end

---@return number
function g.getBones()
    return currentSession.resources.bones
end

---@param x number
function g.addRocks(x)
    currentSession.resources.rocks = math.min(currentSession.resources.rocks + x, g.stats.RockLimit)
end

---@return number
function g.getRocks()
    return currentSession.resources.rocks
end

---@param x number
function g.addLogs(x)
    currentSession.resources.logs = math.min(currentSession.resources.logs + x, g.stats.LogLimit)
end

---@return number
function g.getLogs()
    return currentSession.resources.logs
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
function g.addResource(resId, amount)
    assertValidResource(resId)
    local r = currentSession.resources
    local statName = RESOURCE_LIMIT_STAT_NAMES[resId]
    local limit = assert(g.stats[statName])
    r[resId] = math.min(r[resId] + amount, limit)
end


---@param bundle g.Bundle
function g.addResources(bundle)
    if bundle.money then
        g.addMoney(bundle.money)
    end
    if bundle.bones then
        g.addBones(bundle.bones)
    end
    if bundle.rocks then
        g.addRocks(bundle.rocks)
    end
    if bundle.logs then
        g.addLogs(bundle.logs)
    end
end




---@param price g.Bundle
---@return boolean
function g.canAfford(price)
    local r = currentSession.resources
    if (price.money or 0) > (r.money or 0) then return false end
    if (price.bones or 0) > (r.bones or 0) then return false end
    if (price.rocks or 0) > (r.rocks or 0) then return false end
    if (price.logs or 0) > (r.logs or 0) then return false end
    return true
end


---@param price g.Bundle
---@return boolean
function g.trySubtractResources(price)
    local r = currentSession.resources
    if not g.canAfford(price) then
        return false
    end

    if price.money then r.money = r.money - price.money end
    if price.bones then r.bones = r.bones - price.bones end
    if price.rocks then r.rocks = r.rocks - price.rocks end
    if price.logs then r.logs = r.logs - price.logs end
    return true
end


function g.addResourceFrom(tok, resId, amount)
    local mult = g.ask("getTokenResourceMultiplier", tok, resId)
    -- TODO: MAKE g.call here!  "tokenEarnedResource"
    g.addResource(resId, amount * mult)
end




---@param upgradeId string
---@param tabl {}
function g.defineUpgrade(upgradeId, tabl)
    upgrades.defineUpgrade(upgradeId, tabl)
end













local tokenTypes = {--[[
    [tokenType] -> {
        health = X,
        
        onUpdate = func,
        onDestroyed = func
    }
]]}

local tokenMts = {--[[
    [tokenType] -> tokenMt
]]}



---@param tokType string
---@param tabl g.TokenDefinition
function g.defineToken(tokType, tabl)
    assert(not tabl.type, ".type is a reserved field!")
    assert(tabl.maxHealth, "Tokens need .maxHealth")
    assert(tabl.resources, "Tokens need .resources")
    tabl.type = tokType ---@diagnostic disable-line
    tokenTypes[tokType] = tabl
    tokenMts[tokType] = {__index = tabl}
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






---@class g.Token
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
---@field money number?
---@field logs number?
---@field rocks number?
---@field bones number?
---
---@field ___destroyed boolean?
local Token = {}




---@return number?
---@return number
function g.getRandomPositionForToken()
    local world = g.getMainWorld()
    return getRandomPos(world, 0,0, world.WIDTH,world.HEIGHT) ---@diagnostic disable-line
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
    local tabl = tokenTypes[tokType]
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

    tok.___destroyed = true
    w.tokens:removeBuffered(tok)
    return true
end



---@param tok g.Token
---@param dmg number
function g.damageToken(tok, dmg)
    local dmgMult = g.ask("getTokenDamageMultiplier", tok)
    dmg = dmg * dmgMult
    tok.health = tok.health - dmg
    g.call("tokenDamaged", tok, dmg)
    tok.timeSinceDamaged = 0
    if tok.health <= 0 then
        g.destroyToken(tok)
    end
end


---@param tok g.Token
function g.tryHitToken(tok)
    local time = tok.timeSinceHitStart
    if time > g.stats.HitDuration then
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

local MAX_SOURCE_POOL = 20
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
function g.playSound(soundname, pitch, volume)
    local s = getSourceFromPool(soundname)
    if not s then
        return false
    end

    pitch = pitch or 1
    volume = math.max(volume or 1, 0)
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
        local basename = pathrev:sub(1, pathrev:find("/", 1, true)):reverse()

        if #basename > 0 then
            local name = basename:sub(1, -#ext - 2)
            local mainSource = love.audio.newSource(path, "static")
            sourcePool[name] = {mainSource}
        end
    end
end

g.walkDirectory("assets/sounds", loadSound)


end



---@param particleName string
---@param x number
---@param y number
---@param amount integer?
function g.spawnParticle(particleName, x, y, amount)
    return currentSession.mainWorld.particles:spawnParticles(particleName, x, y, amount)
end


return g

