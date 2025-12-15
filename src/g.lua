

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")

local Session = require("src.Session")
local HUD = require("src.ui.hud.hud")



local sfx = require("src.sound.sfx")

local simulation = require("src.world.simulation")

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

function g.hasSession()
    return not not currentSession
end


---@return g.Session
function g.getSn()
    return assert(currentSession, "session not loaded")
end

function g.getWorldTime()
    return currentSession.worldTime
end

---@return g.Tree
function g.getUpgTree()
    return currentSession.tree
end

---@return g.World
function g.getMainWorld()
    return currentSession.mainWorld
end

function g.getPrestige()
    return currentSession.prestige or 0
end

g.isBeingSimulated = simulation.isSimulating

function g.saveAndInvalidateSession()
    if not g.hasSession() or g.isBeingSimulated() then return end
    analytics.send("end")

    local shouldSave = not (consts.DEV_MODE and love.keyboard.isDown("lshift", "rshift"))
    if shouldSave then
        log.trace("Saving session.")
        local data = g.getSn():serialize()
        local contents = json.encode(data)
        assert(love.filesystem.write("saves/save1.json", contents))
        ---@diagnostic disable-next-line: cast-local-type
        currentSession = nil
    end
end






local sceneManager = require("src.scenes.sceneManager")

---@param scName string
function g.gotoScene(scName)
    sceneManager.gotoScene(scName)
end

---@param scName string
function g.gotoSceneViaMap(scName)
    local _,curName = sceneManager.getCurrentScene()
    assert(curName ~= "map_scene", "Already in map! (this will break stuff.)")
    g.gotoScene("map_scene")
    if scName ~= "map_scene" then
        local mapScene, sceneName = sceneManager.getCurrentScene()
        assert(sceneName == "map_scene")
        mapScene:queueDestinationScene(scName)
    end
end




local callEffects, askEffects
local definedEvents = objects.Set()

function g.defineEvent(ev)
    assert(isLoadTime())
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

    local tree = g.getUpgTree()
    tree:callUpgrades(ev, arg1, ...)

    local world = currentSession.mainWorld
    if world:_isPlayerCurrentlyHarvesting() then
        -- only apply effects if player is currently harvesting
        callEffects(ev, arg1, ...)
    end

    local sc = sceneManager.getCurrentScene()
    if sc and sc[ev] then
        sc[ev](sc, arg1, ...)
    end
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
    assert(isLoadTime())
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

    local sc = sceneManager.getCurrentScene()
    if sc and sc[q] then
        val = reducer(val, sc[q](sc, arg1, ...))
    end

    if (type(arg1) == "table") and arg1[q] then
        val = reducer(val, arg1[q](arg1, ...))
    end

    local tree = g.getUpgTree()

    local mainWorld = currentSession.mainWorld
    if mainWorld:_isPlayerCurrentlyHarvesting() then
        -- effects should only be active when player is harvesting
        val = reducer(val, askEffects(q, arg1, ...))
    end

    return reducer(val, tree:askUpgrades(q, arg1, ...))
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
    local prefix = (isNegative and "-" or "")

    if num < 1000 then
        if num == math.floor(num) then
            -- is integer!
            return prefix .. ("%d"):format(num)
        elseif num < 1 then
            return prefix .. ("%.2f"):format(num)
        elseif num < 3 then
            return prefix .. ("%.1f"):format(num)
        end
        return prefix .. tostring(math.floor(num))
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

            return prefix .. formatted .. suffix[2]
        end
    end
    return prefix .. tostring(num)
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


---@param imageName string|love.Quad
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


---@param tinfo g.TokenInfo
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param kx number?
---@param ky number?
function g.drawTokenImage(tinfo, x,y, r,sx,sy,kx,ky)
    local stalkInfo = tinfo.growths and g.getStalkInfo(tinfo.growths.stalk)
    if tinfo.image then
        g.drawImage(tinfo.image, x,y, r, sx, sy, kx,ky)
    end

    if stalkInfo then
        for _, pos in ipairs(stalkInfo.growthpos) do
            g.drawImage(tinfo.growths.growth, x + pos.x, y + pos.y, r, sx, sy, kx, ky)
        end
    end
end


---@param imageName string|love.Quad
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
    local quad
    if type(imageName) == "string" then
        quad = g.getImageQuad(imageName)
    else
        if not (imageName.typeOf and imageName:typeOf("Quad")) then
            error("Expected quad, got: " .. type(imageName) .. " " .. tostring(imageName))
        end
        quad = imageName
    end
    local _,_,w,h = quad:getViewport()
    atlas:draw(quad, x, y, r, sx, sy, (ox or 0.5) * w, (oy or 0.5) * h, kx, ky)
end

---@param imageName string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rot number?
function g.drawImageContained(imageName, x,y, w,h, rot)
    local quad = g.getImageQuad(imageName)
    local _,_,qw,qh = quad:getViewport()
    local scaleX = w / qw
    local scaleY = h / qh
    local scale = math.min(scaleX, scaleY)
    local scaledW = qw * scale
    local scaledH = qh * scale
    local centerX = x + (w - scaledW) / 2
    local centerY = y + (h - scaledH) / 2
    atlas:draw(quad, centerX, centerY, rot or 0, scale, scale, 0, 0)
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
        richtext.defineImage(name, atlas:getTexture(), quad)
    end
end

-- Define 1x1 white image
do
    -- Add padding around to prevent bleeding
    local id = love.image.newImageData(3, 3, "rgba8")
    id:mapPixel(function() return 1, 1, 1, 0 end) -- fill transparent white
    id:setPixel(1, 1, 1, 1, 1, 1) -- set middle pixel
    local q = assert(atlas:add(id))
    local x, y = q:getViewport()
    -- Now define it to be 1x1 instead of 3x3
    q:setViewport(x + 1, y + 1, 1, 1, g.getAtlas():getDimensions())
    nameToQuad["1x1"] = q
end

-- Load other images
g.walkDirectory("src/upgrades", loadImage)
g.walkDirectory("assets/images", loadImage)
g.walkDirectory("src/entities", loadImage)
g.walkDirectory("src/scythes", loadImage)
g.walkDirectory("src/rewards", loadImage)
g.walkDirectory("src/potions", loadImage)

-- Set this to true to dump the atlas
if false then
    local atlasImageData = love.graphics.readbackTexture(atlas:getTexture())
    atlasImageData:encode("png", "texture_atlas_dump.png")
end

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

---@param name string
---@param by number?
function g.incrementMetric(name, by)
    return g.setMetric(name, g.getMetric(name) + (by or 1))
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
g.stats.HitSpeed = g.defineStat("HitSpeed", 5)
g.stats.HitDamage = g.defineStat("HitDamage", 1)
g.stats.HarvestArea = g.defineStat("HarvestArea", 15)
g.stats.ResourceMultiplier = g.defineStat("ResourceMultiplier", 1)
g.stats.OrbitSpeed = g.defineStat("OrbitSpeed", 2) -- rad/s
g.stats.XpMultiplier = g.defineStat("XpMultiplier", 1)
g.stats.AutoCatMoveSpeed = g.defineStat("AutoCatMoveSpeed", 40)
g.stats.LightningDamageMultiplier = g.defineStat("LightningDamageMultiplier", 1)
g.stats.TokenRespawnTime = g.defineStat("TokenRespawnTime", 3)

-- World stat
g.stats.WorldTileWidth = g.defineStat("WorldTileWidth", 20)
g.stats.WorldTileHeight = g.defineStat("WorldTileHeight", 13)

function g.getWorldDimensions()
    local w = math.floor(g.stats.WorldTileWidth * consts.WORLD_TILE_SIZE)
    local h = math.floor(g.stats.WorldTileHeight * consts.WORLD_TILE_SIZE)
    return w, h
end



---@alias g.ResourceType "money"|"fabric"|"bread"|"juice"|"fish"

-- i wish we could define this as { [g.ResourceType]: number } but it doesnt work that way
---@alias g.Bundle {money?: number, fabric?: number, bread?: number, juice?: number, fish?: number}
---@alias g.Resources {money: number, fabric: number, bread: number, juice: number, fish: number}


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
---@field maxLevel integer?
---@field image string?
---@field priceScaling number?
---@field description string?
---@field getPriceOverride (fun(uinfo:g.UpgradeInfo, level:integer): g.Bundle)?
---@field isHidden (fun(uinfo: g.UpgradeInfo): boolean)?
---@field getValues (fun(uinfo: g.UpgradeInfo, level: integer):number)?
---@field valueFormatter ((string|(fun(x:number):string))[])?
---@field getEntityCount (fun(uinfo: g.UpgradeInfo, level: integer):integer)?
---@field spawnEntity (fun(uinfo: g.UpgradeInfo):g.Entity)?
---@field perSecondUpdate (fun(uinfo: g.UpgradeInfo, level: integer, seconds:integer))?
---@field drawUI (fun(uinfo: g.UpgradeInfo, level:integer, x:number,y:number,w:number,h:number))?
local g_UpgradeDefinition = {}


---@class g.TokenDefinition
---@field maxHealth number
---@field resources g.Bundle
---@field image string?
---@field maxLevel integer?
---@field growths {stalk:string,growth:string}?
---@field description string?
---@field particles string?
---@field category g.Category?
---@field shadow ("shadow_medium"|"shadow_small"|"shadow_big")?
---@field init (fun(tok:g.Token))?
---@field update (fun(tok: g.Token, dt:number))?
---@field drawBelow (fun(tok: g.Token))?
--- below this line are events (via g.call)
---@field drawToken (fun(tok: g.Token, x:number,y:number, rot:number?,sx:number?,sy:number?,kx:number?,ky:number?))?
---@field tokenHit (fun(tok: g.Token))?
---@field tokenDestroyed (fun(tok: g.Token))?
---@field tokenDamaged (fun(tok: g.Token, dmg:number))?
---@field upgradeDefinition table<string, function>? Extra definitions for the corresponding upgrade
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
    image="money",
    limitStat="MoneyLimit",
    startingLimit=(consts.DEV_MODE and 10000000000000) or 1000,
    color = {0.71, 0.55, 0.02},
})
g.defineResource("juice", {
    image="juice",
    limitStat="JuiceLimit",
    color=objects.Color("#".."FF8A2E59")
})
g.defineResource("fabric", {
    image="fabric",
    limitStat="FabricLimit",
    color=objects.Color("#".."FFF353FB")
})
g.defineResource("bread", {
    image="bread",
    limitStat="BreadLimit",
    color=objects.Color("#".."FFB78652")
})
g.defineResource("fish", {
    image="fish",
    limitStat="FishLimit",
    color=objects.Color("#".."FF305FCD")
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
    local sn = currentSession
    return sn.resourceUnlocks[resId]
end

---@param resId string
function g.getResourceInfo(resId)
    assertValidResource(resId)
    return RESOURCES[resId]
end


---@param resId string
---@return number resourcesPerSecond
function g.getResourcesPerSecond(resId)
    assertValidResource(resId)
    local world = g.getSn().mainWorld
    return world.resourcesPerSecond[resId] or 0
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
            result[resId] = (a[resId] or 0) * b
        end
    else
        for _, resId in ipairs(g.RESOURCE_LIST) do
            result[resId] = (a[resId] or 0) * (b[resId] or 1)
        end
    end
    return result
end


---@param bundle g.Bundle
---@return g.Bundle
function g.cloneBundle(bundle)
    local result = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        result[resId] = bundle[resId] or 0
    end
    return result
end


---@param a g.Bundle
---@param b g.Bundle
---@return g.Resources
function g.minBundle(a, b)
    local result = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        local aVal = a[resId] or 0
        local bVal = b[resId] or 0
        result[resId] = math.min(aVal, bVal)
    end
    return result
end

---@param a g.Bundle
---@param b g.Bundle
---@return g.Resources
function g.maxBundle(a, b)
    local result = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        local aVal = a[resId] or 0
        local bVal = b[resId] or 0
        result[resId] = math.max(aVal, bVal)
    end
    return result
end

---@param cost g.Bundle The cost of the upgrade
---@param current? g.Bundle The current resources available
---@return number ratio A value between 0 and 1 representing affordability (1 = can fully afford)
function g.getBundleCostRatio(cost, current)
    current = current or g.getResources()

    local totalRatio = 0
    local resourceCount = 0

    for _, resId in ipairs(g.RESOURCE_LIST) do
        local costVal = cost[resId] or 0
        if costVal > 0 then
            resourceCount = resourceCount + 1
            local currentVal = current[resId] or 0
            local ratio = currentVal / costVal
            -- Clamp ratio to [0, 1] so having more than needed doesn't exceed 1
            totalRatio = totalRatio + math.min(ratio, 1)
        end
    end

    -- If no resources required, return 1 (fully affordable)
    if resourceCount == 0 then
        return 1
    end
    return totalRatio / resourceCount
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
---@return g.Bundle
function g.addResourceFrom(tok, bundle)
    local mod = g.ask("getTokenResourceModifier", tok)
    local mult = g.ask("getTokenResourceMultiplier", tok)

    bundle = g.addBundles(bundle, mod)
    bundle = g.multBundles(bundle, mult)

    g.addResources(bundle)

    g.call("tokenEarnedResources", tok, bundle)
    return bundle
end



--------------------------------------------------
-- Categories
--------------------------------------------------

---@alias g.Category
---| "grass"
---| "berry"
---| "mushroom"
---| "chest"
---| "slime"

---@type table<g.Category, true|nil>
g.CATEGORIES = {
    grass = true,
    berry = true,
    mushroom = true,
    chest = true,
    slime = true,
}

-- g.getTokensDestroyedInCategory
do
---@param tokCategory string
---@return number
function g.getTokensDestroyedInCategory(tokCategory)
    assert(g.CATEGORIES[tokCategory], "?")
    local name = "totalCategoryHarvested_"..tokCategory
    return g.getMetric(name) or 0
end

for tokCategory,_ in pairs(g.CATEGORIES)do
    local name = "totalCategoryHarvested_"..tokCategory
    g.defineMetric(name)
end
end

g.defineMetric("totalTokensHarvested")




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
---@return g.EffectInfo
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


---@type string[]
g.UPGRADE_LIST = {}

---@type {[string]: g.UpgradeInfo?}
local upgradeInfos = {--[[
    [upgradeId] -> Table (contains all info)
]]}



-- Load prestiges
do
    local i = 0
    while true do
        local p = "src/upgrades/prestige_"..i..".json"
        if love.filesystem.getInfo(p, "file") then
            log.trace("Loading upgrade prestige position:", p)
            ---@type _g.UpgradePrestigeData
            local r = json.decode((assert(love.filesystem.read(p))))

        else
            break
        end

        i = i + 1
    end
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




-- a list of "special" functions that upgrades use,
-- that ARENT q-bus or ev-bus. (eg ignore them)
local SPECIAL_FUNCTIONS = {
    getValues = true,
    getEntityCount = true,
    spawnEntity = true,
    getPriceOverride = true,
    drawUI = true
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

    if rawget(def,"price") then
        error("Deprecated.", 2)
    end

    -- Cache questions and events this upgrade can handle
    for key, func in pairs(def) do
        if type(func) == "function"  then
            local ok = g.getQuestionInfo(key) or g.isEvent(key)
            local ok2 = SPECIAL_FUNCTIONS[key]
            if not (ok or ok2) then
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


---@param upgradeId string
---@return boolean
function g.isValidUpgrade(upgradeId)
    local uinfo = upgradeInfos[upgradeId]
    return not not uinfo
end



local STAT_UP_COLOR = objects.Color("#".."FFEF8EFC")

---@param uinfo g.UpgradeInfo
---@param level integer
---@param nextLevel boolean? (Display next level values?)
function g.getUpgradeDescription(uinfo, level, nextLevel)
    if not uinfo.description then
        return ""
    end
    local displayValue = {}
    if uinfo.getValues then
        local currentValues = {uinfo:getValues(level)}
        local nextValues = nil
        if nextLevel then
            nextValues = {uinfo:getValues(level + 1)}
            assert(#currentValues == #nextValues)
        end
        for i = 1, #currentValues do
            local formatter = uinfo.valueFormatter[i] or "%.14g"
            local value
            if type(formatter) == "string" then
                value = string.format(formatter, currentValues[i])
                if nextValues then
                    value = value..string.format(helper.wrapRichtextColor(STAT_UP_COLOR, " -> "..formatter), nextValues[i])
                end
            else
                value = formatter(currentValues[i])
                if nextValues then
                    value = value..helper.wrapRichtextColor(STAT_UP_COLOR, " -> "..formatter(nextValues[i]))
                end
            end
            displayValue[tostring(i)] = value
        end
    end
    return uinfo.description(displayValue)
end



end









---@type table<string, g.StalkDefinition>
local STALKS = {}

---@class g.StalkDefinition
---@field public image string?
---@field public dontFlip boolean?
---@field public growthpos {x: number, y: number}[] Position coordinate is in pixels, relative to stalk center

---@param id string
---@param def g.StalkDefinition
function g.defineStalk(id, def)
    helper.assert(not STALKS[id], "stalk", id, "already defined")
    assert(def.growthpos and type(def.growthpos) == "table", "missing or invalid growth position table")
    assert(#def.growthpos > 0, "missing growth position (must at least 1)")
    def.image = def.image or id
    helper.assert(g.isImage(def.image), "invalid image", def.image)

    STALKS[id] = def
end

---@param stalk string
function g.getStalkInfo(stalk)
    return (helper.assert(STALKS[stalk], "invalid stalk", stalk))
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
    assert(not tokenDefinitions[tokType], "Duplicate token definition!")
    if tabl.shadow then
        assert(g.getImageQuad(tabl.shadow))
    end

    if tabl.category and not g.CATEGORIES[tabl.category] then
        error("invalid category '"..tabl.category.."'")
    end

    if tabl.growths then
        assert(tabl.growths.growth, "growth field is missing")
        assert(tabl.growths.stalk, "stalk field is missing")
        -- LuaLS why you not remove nil on assert of table field?
        ---@type g.StalkDefinition
        local stalkInfo = helper.assert(STALKS[tabl.growths.stalk], "invalid stalk", tabl.growths.stalk)

        assert(not tabl.image, "cannot define image when defining stalk")
        tabl.image = assert(stalkInfo.image)
    end

    if tabl.resources then
        for resId,v in pairs(tabl.resources) do
            assertValidResource(resId)
            assert(v >= 0)
        end
    end

    tabl.image = tabl.image or tokType

    local oldDescription = tabl.description
    if tabl.description then
        tabl.description = loc(tabl.description)
    end

    tokenDefinitions[tokType] = tabl
    ---@cast tabl g.Token
    tabl.type = tokType
    tabl.name = loc(name) ---@diagnostic disable-line
    local mt = {__index = tabl}
    tokenMts[tokType] = mt
    reverseTokMt[mt] = true
    g.TOKEN_LIST[#g.TOKEN_LIST+1] = tokType

    ---@type g.UpgradeDefinition
    local upgradeDef
    upgradeDef = {
        image = tabl.image,
        populateTokenPool = function(self, level, tokens) ---@diagnostic disable-line
            tokens:add(tokType, level)
        end,
        maxLevel = tabl.maxLevel or nil,
        description = oldDescription,
        kind = "TOKEN",
        tokenType = tokType
    }
    for k,v in pairs(tabl.upgradeDefinition or {}) do
        upgradeDef[k]=v
    end
    g.defineUpgrade(tokType, name, upgradeDef)
end



---@param obj any
function g.isToken(obj)
    local mt = getmetatable(obj)
    return not not reverseTokMt[mt]
end

---@param tokType string
function g.getTokenInfo(tokType)
    if not tokenDefinitions[tokType] then
        error("token '"..tostring(tokType).."' does not exist")
    end
    return tokenDefinitions[tokType]
end


function g.drawTokenIcon(tokType, x,y, rot,sx,sy, kx,ky)
    local tinfo = g.getTokenInfo(tokType)
    if tinfo.image then
        g.drawImage(tinfo.image, x, y, rot, sx, sy, kx,ky)
    end

    if tinfo.growths then
        local stalkInfo = g.getStalkInfo(tinfo.growths.stalk)
        for _, pos in ipairs(stalkInfo.growthpos) do
            g.drawImage(tinfo.growths.growth, x + pos.x, y + pos.y, rot, sx, sy, kx, ky)
        end
    end
end


local DEFAULT_MIN_SPACING = 12

---@param world g.World
---@param x number
---@param y number
---@param w number
---@param h number
---@param minSpacing number?
---@param maxAttempts integer?
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
---@field shadow ("shadow_medium"|"shadow_small"|"shadow_big")?
---@field sx number?
---@field sy number?
---@field ox number?
---@field oy number?
---@field rot number?
---@field alpha number?
---@field orbitRing integer?
---@field bulgeAnimation {time: number, magnitude: number, duration:number}?
---@field image string?
---@field drawIndex number?
---@field lifetime number?
---@field blendmode love.BlendMode?
---@field blendalphamode love.BlendAlphaMode?
---@field init (fun(ent:g.Entity,...:any))?
---@field update (fun(ent: g.Entity, dt:number))?
---@field perSecondUpdate (fun(e:g.Entity, seconds:integer))?
---@field drawBelow (fun(ent: g.Entity))?
---@field draw (fun(ent: g.Entity))?
---@field hitToken {radius:number,collision:fun(self:g.Entity,tok:g.Token),cooldown:number?}?
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
    if etype.hitToken then
        assert(etype.hitToken.radius, "missing radius")
        assert(etype.hitToken.collision, "missing collision function")
    end
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
function g.spawnEntity(ename, x,y, ...)
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

    if ent.hitToken then
        ent.hitToken = helper.shallowCopy(ent.hitToken)
    end

    if ent.init then
        ent:init(...)
    end

    currentId = currentId + 1
    assert(type(ent) == "table")
    assert(ent.type)
    w.entities:addBuffered(ent)
    return ent
end


---@param ent g.Entity
---@param duration number
---@param magnitude number
function g.bulgeEntity(ent, duration, magnitude)
    ent.bulgeAnimation = {
        duration = duration,
        time = duration,
        magnitude = magnitude
    }
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
---@field laggedHealth number for lag-health-visual
---@field health number
---@field maxHealth number
---@field image string
---@field resources g.Bundle
---@field timeSinceHitStart number Time since last `tryHitToken` is initiated (it's not immediately hit).
---@field timeSinceHit number Time since `tryHitToken` actually hits the token.
---@field timeSinceDamaged number
---@field timeAlive number
---@field drawToken (fun(tok: g.Token, x:number,y:number, rot:number?,sx:number?,sy:number?,kx:number?,ky:number?))?
---@field slimed boolean?
---@field starred boolean?
---@field wasSpawnedViaTokenPool boolean?
---@field ___destroyed boolean?
local g_Token = {}




---@param guarantee boolean? If true, get any random position even if it's too close to token.
---@overload fun():(number?,number?)
---@overload fun(guarantee:true):(number,number)
---@return number?,number?
function g.getRandomPositionForToken(guarantee)
    local worldW, worldH = g.getWorldDimensions()
    local pad=4
    local x, y = getRandomPos(g.getMainWorld(), pad,pad, worldW-pad*2,worldH-pad*2)

    if not (x and y) and guarantee then
        x = helper.lerp(pad, worldW - pad, love.math.random())
        y = helper.lerp(pad, worldH - pad, love.math.random())
    end

    return x, y
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
    ---@cast tok g.Token
    tok.maxHealth = tabl.maxHealth * g.ask("getTokenMaxHealthMultiplier", tok)
    tok.health = tok.maxHealth
    tok.laggedHealth = tok.health

    if tok.init then
        tok:init()
    end

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

    if tok.category then
        local name = "totalCategoryHarvested_"..tok.category
        g.incrementMetric(name)
    end
    g.incrementMetric("totalTokensHarvested")

    local w = g.getMainWorld()
    g.call("tokenDestroyed", tok)

    g.addResourceFrom(tok, tok.resources)

    if tok.slimed then
        g.spawnParticle("slime", tok.x,tok.y, love.math.random(3,5))
    end
    if tok.particles then
        g.spawnParticle(tok.particles, tok.x,tok.y, love.math.random(3,5))
    end
    if tok.growths then
        local stalkInfo = g.getStalkInfo(tok.growths.stalk)
        for _, pos in ipairs(stalkInfo.growthpos) do
            g.spawnEntity("growth_falling", tok.x + pos.x, tok.y + pos.y, tok.growths.growth, tok.y + 8)
        end
    end

    if not w.tokenDestroyTime[tok.type] then
        w.tokenDestroyTime[tok.type] = {}
    end
    table.insert(w.tokenDestroyTime[tok.type], g.getWorldTime())

    w.tokens:removeBuffered(tok)

    -- todo: rework/rethink this.
    -- Each token should have different "sound"
    g.playWorldSound("pop", 1, 1, 0.15)
    return true
end



---@param tok g.Token
function g.slimeToken(tok)
    if not tok.slimed then
        g.call("tokenSlimed",tok)
    end
    tok.slimed=true
    worldutil.spawnSTSAnimation("slimed_visual2", tok.x,tok.y, 0.4, 5)
end

---@param tok g.Token
function g.starToken(tok)
    if not tok.starred then
        g.call("tokenStarred", tok)
    end
    tok.starred = true
    worldutil.spawnSTSAnimation("star_visual", tok.x,tok.y, 0.5, 9)
end



---@param tok g.Token
---@param dmg number
function g.damageToken(tok, dmg)
    if tok.health <= 0 then
        return
    end

    local dmgMult = g.ask("getTokenDamageMultiplier", tok)
    local dmgMod = g.ask("getTokenDamageModifier", tok)
    dmg = (dmg + dmgMod) * dmgMult
    local displayDmg = math.min(dmg, math.max(tok.health, 0))

    -- Ensure lagged health number is updated first before tok.health
    local t = helper.clamp(tok.timeSinceDamaged / consts.LAGGED_HEALTHBAR_DURATION, 0, 1)
    t = helper.clamp(helper.EASINGS.easeInCubic(t), 0, 1)
    tok.laggedHealth = helper.lerp(tok.laggedHealth, tok.health, t)

    -- Now update tok.health
    tok.health = math.max(tok.health - dmg, 0)
    g.call("tokenDamaged", tok, dmg)

    currentSession.mainWorld:_spawnDamageNumber(
        displayDmg,
        tok.x,
        tok.y - 5,
        g.COLORS.DAMAGE_NUMBERS_BY_CATEGORY[tok.category] or objects.Color.WHITE
    )

    tok.timeSinceDamaged = 0
end


function g.getHitDuration()
    return consts.MAX_HIT_DURATION + (3 / g.stats.HitSpeed) ^ 0.9
end


--- checks if a token is being hit
---@param tok g.Token
---@return boolean
function g.isBeingHit(tok)
    local time = tok.timeSinceHitStart
    return time <= g.getHitDuration()
end

---@param tok g.Token
function g.tryHitToken(tok)
    if tok.health > 0 and not g.isBeingHit(tok) then
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

    local r = love.math.random()
    if r < 0.333 then
        g.spawnParticle("xp1", tok.x, tok.y, 2)
    elseif r < 0.666 then
        g.spawnParticle("xp2", tok.x, tok.y, 1)
    else
        g.spawnParticle("xp3", tok.x, tok.y, 2)
    end

    local i = love.math.random(1,3)
    local s = "hit_generic_"..i
    g.playWorldSound(s, 1,0.1,0.2,0.2)

    -- todo: rework all this.
    if tok.category == "grass" then
        if love.math.random()<0.3 then
            g.playWorldSound("hit_grass",1,0.15, 0.1)
        else
            g.playWorldSound("hit_grass2",1,0.15, 0.1)
        end
    elseif love.math.random()<0.5 then
        g.playWorldSound("hit_billiard", 1, 0.18, 0.3)
    else
        g.playWorldSound("hit_soft", 1, 0.18, 0.3)
    end
end


---@param x number
---@param y number
---@param radius number
---@param func fun(tok:g.Token)
function g.iterateTokensInArea(x, y, radius, func)
    g.getMainWorld().tokenPartition:query(x, y, function(tok)
        if helper.magnitude(x-tok.x, y-tok.y) <= radius then
            func(tok)
        end
    end, radius)
end



local MAX_QUEUED_TOKENS = 100

---@param tokenId string
---@param screenX number?
---@param screenY number?
---@param onSpawn fun(tok:g.Token)?
function g.stackToken(tokenId, screenX,screenY, onSpawn)
    assert(g.getTokenInfo(tokenId))
    currentSession.tokenQueue[#currentSession.tokenQueue+1] = {
        tokenId = tokenId,
        onSpawn = onSpawn
    }

    while #currentSession.tokenQueue > MAX_QUEUED_TOKENS do
        g.popStackedToken()
    end

    if screenX and screenY then
        g.getHUD().profileHUD:spawnTokenVisual(tokenId, screenX, screenY)
    end
end


---@param duration number
---@param effectInfo g.EffectInfo
---@param screenX number?
---@param screenY number?
function g.stackPotionToken(duration, effectInfo, screenX, screenY)
    g.stackToken("abstract_potion_token", screenX, screenY, function (tok)
        -- HACKY HACKY: Injecting shit here.
        tok.image = effectInfo.image

        ---@diagnostic disable-next-line
        tok._effect = effectInfo.type
        ---@diagnostic disable-next-line
        tok._effectDuration = duration
    end)
end


---@return string?
---@return fun(tok:g.Token)? onSpawn
function g.peekStackedToken()
    local tabl = currentSession.tokenQueue[1]
    if tabl then
        return tabl.tokenId, tabl.onSpawn
    end
end

---@return string
function g.popStackedToken()
    assert(#currentSession.tokenQueue > 0, "token queue is empty")
    local popped = table.remove(currentSession.tokenQueue, 1)
    return popped.tokenId
end




local hud = HUD()

function g.getHUD()
    return hud
end



-- g.playWorldSound
-- g.playUISound
do


---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playWorldSound(soundname, pitch, volume, pitchVar, volumeVar)
    if love.audio.getActiveSourceCount() > consts.MAX_PLAYING_SOURCES then
        return false
    end
    if select(2, sceneManager.getCurrentScene()) == "harvest_scene" then
        return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
    end
    return false
end


---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playUISound(soundname, pitch, volume, pitchVar, volumeVar)
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end



local cosmetics = require("src.cosmetics.cosmetics")

g.getCosmeticInfo = cosmetics.getInfo
g.getUnlockedCosmetics = cosmetics.getUnlocked

g.drawAvatar = cosmetics.drawAvatar
g.drawPlayerAvatar = cosmetics.drawPlayerAvatar






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
            if name:sub(1,1) ~= "_" then
                sfx.defineSound(name, path)
            end
        end
    end
end

g.walkDirectory("assets/sfx", loadSound)


end



-------------
-- Scythes --
-------------
do

---@class _ScytheDefinition
---@field public image string?
---@field public harvestArea number harvest area modifier

---@class g.Scythe: _ScytheDefinition
---@field public type string
---@field public image string
---@field public name string



---@type table<string, g.Scythe>
local SCYTHES = {}

---@type string[]
local SCYTHE_ORDER = {}


---Define new scythe
---@param id string
---@param name string
---@param def _ScytheDefinition
function g.defineScythe(id, name, def)
    def.image = def.image or id
    helper.assert(g.isImage(def.image), "invalid image", def.image)

    ---@cast def g.Scythe
    def.type = id
    def.name = loc(name, {}, {
        context = "As in, a scythe used for harvesting. Like 'Ruby Scythe' or 'Emerald Scythe' or 'Basic Scythe'"
    })
    SCYTHES[id] = def
    table.insert(SCYTHE_ORDER,id)
end

---@param id string
function g.getScytheInfo(id)
    return (helper.assert(SCYTHES[id], "invalid scythe", id))
end

---@return string
function g.getCurrentScythe()
    return currentSession.scythe or consts.DEFAULT_SCYTHE
end

---@return string?
---@return g.Scythe?
function g.getNextScythe()
    local curr = g.getCurrentScythe()
    for i,sc in ipairs(SCYTHE_ORDER)do
        if sc == curr then
            local id = SCYTHE_ORDER[i+1]
            if id then
                return id, g.getScytheInfo(id)
            end
        end
    end
    return nil
end



end



---@param particleName string
---@param x number
---@param y number
---@param amount integer?
function g.spawnParticle(particleName, x, y, amount)
    if g.isBeingSimulated() then return end
    return currentSession.mainWorld.particles:spawnParticles(particleName, x, y, amount)
end



g.COLORS = {

    BUTTON_FADE_1 = objects.Color("#" .. "FF9F14F6"),
    BUTTON_FADE_2 = objects.Color("#" .. "FF3B12A4"),

    UPGRADE_KINDS = {
        HARVESTING = objects.Color("#" .. "FFCB8B14"),
        TOKEN = objects.Color("#" .. "FF1479CB"),
        TOKEN_MODIFIER = objects.Color("#" .. "FF15C39A"),
        MISC = objects.Color("#" .. "FFFFFFFF"),
    },

    ---@type table<g.Category, objects.Color>
    DAMAGE_NUMBERS_BY_CATEGORY = {
        grass = objects.Color("#".."FF84CDFA"),
        wood = objects.Color("#".."FFF5D48E"),
        mushroom = objects.Color("#".."FFFAFCC0"),
        rock = objects.Color("#".."FFF7A8A6"),
    },

    SHADOW = objects.Color(0,0,0,0.4),

    CANT_AFFORD = objects.Color("#".."FFD72D2D"),
    CAN_AFFORD = objects.Color("#".."FF73FF73"),

    MONEY = objects.Color("#".."FFF7D127"),
    RECOMMENDED = objects.Color("#".."FF9DEC4E"),
    UPGRADE_CONNECTOR = objects.Color("#".."FF000000")
}

do
for k,v in pairs(g.COLORS) do
    if getmetatable(v) == objects.Color then
        richtext.defineEffect(k, function (context, char)
            char:setColor(v)
        end)
    end
end
end


return g
