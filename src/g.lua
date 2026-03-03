

-- global exports.
-- Gotta go fast, i dont care about "best practice"

local reducers = require("src.modules.reducers")

local Session = require("src.Session")
local Tree = require("src.upgrades.Tree")
local HUD = require("src.ui.hud.hud")



local bgm = require("src.sound.bgm")
local sfx = require("src.sound.sfx")

local simulation = require("src.world.simulation")

---@class g
local g = {}





---@type g.Session
local currentSession

---@return g.Session
function g.newSession()
    currentSession = Session()
    return currentSession
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


---@param prestige integer
---@return g.Tree
function g.loadPrestigeTree(prestige)
    local fname = "assets/prestiges/prestige_" .. prestige .. ".json"
    local data,er = love.filesystem.read(fname)
    assert(data,er)
    local tabl = assert(json.decode(data))
    return Tree.deserialize(tabl)
end

do
local finalPrestige = 0
for p=0,500 do
    local fname = "assets/prestiges/prestige_" .. tostring(p) .. ".json"
    if not love.filesystem.getInfo(fname) then
        -- welp, we ran out of prestige files!
        break
    end
    finalPrestige = p
end

function g.getFinalPrestige()
    return finalPrestige
end

end


function g.incrementPrestige()
    -- WARNING: this function has FAR REACHING CONSEQUENCES.
    -- will reset upgrades, and do a tonne of other resets.
    local curr = currentSession
    local new = Session()

    local prestige = math.min(g.getFinalPrestige(), curr.prestige + 1)
    new.tree = (g.loadPrestigeTree(prestige))
    new.level = 0

    -- copy over the important stuff:
    new.prestige = prestige
    new.avatar = curr.avatar
    new.showTutorials = {harvest=false, upgrades=false}
    new.unlockedPOI = objects.Set(curr.unlockedPOI)
    new.fisherCatCount = curr.fisherCatCount

    currentSession = new
end

function g.forceUnlockPOI(poiId)
    g.getSn().unlockedPOI:add(poiId)
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

---@param delfile boolean? Delete the save file?
function g.delSession(delfile)
    ---@diagnostic disable-next-line: cast-local-type
    currentSession = nil

    if delfile then
        love.filesystem.remove("saves/save1.json")
    end
end

local pendingEndSession = nil

--- Deferred delSession + scene change (safe to call mid-frame)
---@param delfile boolean?
---@param gotoScene string?
function g.endSession(delfile, gotoScene)
    pendingEndSession = {delfile = delfile, gotoScene = gotoScene or "title_scene"}
end

function g.shouldEndSession()
    local p = pendingEndSession
    pendingEndSession = nil
    return p
end

function g.saveSession()
    local shouldSave = not (consts.DEV_MODE and love.keyboard.isDown("lshift", "rshift"))
    if shouldSave then
        log.trace("Saving session.")
        local data = g.getSn():serialize()
        local contents = json.encode(data)
        assert(love.filesystem.write("saves/save1.json", contents))
    end
end

function g.saveAndInvalidateSession()
    if not g.hasSession() or g.isBeingSimulated() then return end
    analytics.send("end")

    g.saveSession()
    return g.delSession()
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
---@type table<integer, love.Font>
local bigCache = {}
---@type table<integer, love.Font>
local smolCache = {}
---@type table<integer, love.Font>
local fbCache = {}

---@param size integer
local function getFallbackFonts(size)
    if not fbCache[size] then
        local f = love.graphics.newFont("assets/fonts/unifont-17.0.03.otf", size, "mono", size / 16)
        fbCache[size] = f
    end

    return fbCache[size]
end

---@param size number
function g.getBigFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not bigCache[size] then
        local f = love.graphics.newFont("assets/fonts/Smart 9h.ttf", size,"mono",1)
        f:setFallbacks(getFallbackFonts(size))
        bigCache[size] = f
    end
    return bigCache[size]
end

---@param size number
function g.getSmallFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not smolCache[size] then
        local f = love.graphics.newFont("assets/fonts/Match 7h.ttf", size,"mono",1)
        f:setFallbacks(getFallbackFonts(size))
        smolCache[size] = f
    end
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
        local gox, goy = stalkInfo.growthOx or 0, stalkInfo.growthOy or 0
        for _, pos in ipairs(stalkInfo.growthpos) do
            g.drawImage(tinfo.growths.growth, x + pos.x + gox, y + pos.y + goy, r, sx, sy, kx, ky)
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
    atlas:draw(quad, centerX + scaledW/2, centerY + scaledH/2, rot or 0, scale, scale, qw/2, qh/2)
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
g.walkDirectory("src/bosses", loadImage)
g.walkDirectory("src/scythes", loadImage)
g.walkDirectory("src/rewards", loadImage)
g.walkDirectory("src/effects", loadImage)
g.walkDirectory("src/cosmetics", loadImage)

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



local defineStatTc = typecheck.assert("string", "number", "string")

---@type table<string, {addQuestion: string, multQuestion:string, startingValue: number, name: string}>
g.VALID_STATS = {}

---@param id string
---@param startingValue number
---@param name string
---@return number
function g.defineStat(id, startingValue, name)
    defineStatTc(id, startingValue, name)
    assert(not g.VALID_STATS[id], "Redefined stat")
    assert(id:sub(1,1):upper() == id:sub(1,1), "Stats must have first letter capitalized")
    local addQ = "get" .. id .. "Modifier"
    g.defineQuestion(addQ, reducers.ADD, 0)
    local multQ = "get" .. id .. "Multiplier"
    g.defineQuestion(multQ, reducers.MULTIPLY, 1)
    g.VALID_STATS[id]={
        addQuestion = addQ, multQuestion = multQ,
        startingValue = startingValue,
        name = name and loc(name, nil, {context = "This is a statistic, e.g. 'Damage' or 'Health'. Represents a value that can be improved/upgraded."}) or id,
    }
    return 0
end


---@param id string
---@return number
function g.getStatBaseValue(id)
    return g.VALID_STATS[id].startingValue
end



-- stats are recomputed every frame.
-- Think of them as like "global properties".
-- (EG. harvestingSpeed, harvestingDamage)
---@class g.stats
g.stats = {}


-- SSTATS 
-- (if you ever want to quickly search the name of stats, search "sstats")
g.stats.HitSpeed = g.defineStat("HitSpeed", 9, "Hit Speed")
g.stats.HitDamage = g.defineStat("HitDamage", 25, "Hit Damage")
g.stats.HarvestArea = g.defineStat("HarvestArea", 10, "Harvest Area")
g.stats.ResourceMultiplier = g.defineStat("ResourceMultiplier", 1, "Resource Gain Multiplier")
g.stats.OrbitSpeed = g.defineStat("OrbitSpeed", 2, "Entity Orbit Speed") -- rad/s
g.stats.XpMultiplier = g.defineStat("XpMultiplier", 1, "XP Gain Multiplier")
g.stats.AutoCatMoveSpeed = g.defineStat("AutoCatMoveSpeed", 20, "Cats Move Speed")
g.stats.AutoCatRadiusMultiplier = g.defineStat("AutoCatRadiusMultiplier", 1, "Farmer Cats Harvest Area")
g.stats.TokenRespawnTime = g.defineStat("TokenRespawnTime", 3, "Crop Respawn Time")
g.stats.CritChance = g.defineStat("CritChance", 0, "Critical Hit Chance") -- should start at 0
g.stats.CritDamageMultiplier = g.defineStat("CritDamageMultiplier", 10, "Crirical Damage Multiplier")
g.stats.KnifeDamage = g.defineStat("KnifeDamage", 10, "Knife Damage")
g.stats.LightningDamage = g.defineStat("LightningDamage", 20, "Lightning Damage")
g.stats.ExplosionDamage = g.defineStat("ExplosionDamage", 15, "Explosion Damage")

-- World stat
g.stats.WorldTileSize = g.defineStat("WorldTileSize", 20, "World Size")

-- OLD CODE:
-- g.stats.WorldTileWidth = g.defineStat("WorldTileWidth", 20)
-- g.stats.WorldTileHeight = g.defineStat("WorldTileHeight", 13)

---@return integer
---@return integer
function g.getWorldTileDimensions()
    -- the size of dimensions in TILES.
    local sze = g.stats.WorldTileSize
    local wtw = math.floor((sze * 20/20) + 0.5)
    local wth = math.floor((sze * 13/20) + 0.5)
    return wtw, wth
end


---@return number
---@return number
function g.getWorldDimensions()
    local wtw,wth = g.getWorldTileDimensions()
    local w = math.floor(wtw * consts.WORLD_TILE_SIZE)
    local h = math.floor(wth * consts.WORLD_TILE_SIZE)
    return w, h
end

---@return number
function g.getWorldEdgeLeeway()
    -- Roughly, the distance from world-island-edge to screen-edges
    -- (NOT ENTIRELY ACCURATE; ESTIMATE.)
    return 150
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



---@class g.UpgradeDefinition.ProcGen
---@field weight number The rarity-weight of upgrade
---@field distance [integer,integer] [min,max] distance from root node when generating. A root node has level > 0. E.g. if distance = {1,3}, that means it MUST be between 1 and 3 jumps to a root node.
---@field resource g.ResourceType? The resource (if any) that this upgrade relates to.
---@field needs string? a dependency to another upgrade. Eg: "better_slime" upgrade requires "slime" upgrade as a pre-requisite.
--- this class tells the system: "Hey, this upgrade will be procedurally generated!"
local g_UpgradeDefinition_ProcGen


---@class g.UpgradeDefinition
---@field kind g.UpgradeKind
---@field nameContext string?
---@field tokenType string? (only for kind == "TOKEN")
---@field maxLevel integer?
---@field image string?
---@field priceScaling number?
---@field description string?
---@field descriptionContext string?
---@field rawDescription string?
---@field procGen g.UpgradeDefinition.ProcGen?
---@field getPriceOverride (fun(uinfo:g.UpgradeInfo, level:integer): g.Bundle)?
---@field isHidden (fun(uinfo: g.UpgradeInfo): boolean)?
---@field getValues (fun(uinfo: g.UpgradeInfo, level: integer):number,number?,number?,number?)?
---@field valueFormatter ((string|(fun(x:number):string))[])?
---@field getEntityCount (fun(uinfo: g.UpgradeInfo, level: integer):integer)?
---@field spawnEntity (fun(uinfo: g.UpgradeInfo):g.Entity)?
---@field perSecondUpdate (fun(uinfo: g.UpgradeInfo, level: integer, seconds:integer))?
---@field drawUI (fun(uinfo: g.UpgradeInfo, level:integer, x:number,y:number,w:number,h:number))?
local g_UpgradeDefinition = {}


---@class g.TokenDefinition
---@field maxHealth number
---@field resources g.Bundle
---@field nameContext string?
---@field image string?
---@field bossfight {healthToken:string?}?
---@field maxLevel integer?
---@field growths {stalk:string,growth:string}?
---@field flight {vx:number,vy:number}?
---@field flightCustomWings {image: string, distance: number}?
---@field description string?
---@field descriptionContext string?
---@field rawDescription string?
---@field upgradeNameContext string?
---@field upgradeDescriptionContext string?
---@field drawOrder number?
---@field particles string?
---@field category g.Category?
---@field shadow ("shadow_medium"|"shadow_small"|"shadow_big")?
---@field procGen {weight:number,distance:[integer,integer],needs:string?}?
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
---@field public nameContext string?
---@field public description string?
---@field public descriptionContext string?
---@field public rawDescription string?
---@field public update fun(duration:number, dt:number)?
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
---@field public limitStatName string

---@type g.ResourceType[]
g.RESOURCE_LIST = {}

---@type table<string, g._ResourceDefinition>
local RESOURCES = {}


---@param resId string
---@param tabl g._ResourceDefinition
function g.defineResource(resId, tabl)
    RESOURCES[resId] = tabl
    g.defineStat(tabl.limitStat, tabl.startingLimit or 100, tabl.limitStatName)
    table.insert(g.RESOURCE_LIST, resId)
    pcall(richtext.defineImage, tabl.image, g.getAtlas(), g.getImageQuad(tabl.image))
end


g.defineResource("money", {
    image="money",
    limitStat="MoneyLimit",
    limitStatName="Money Limit",
    startingLimit=1000,
    color = objects.Color("#".."FFF7D127"),
})
g.defineResource("juice", {
    image="juice",
    limitStat="JuiceLimit",
    limitStatName="Juice Limit",
    startingLimit=1000,
    color=objects.Color("#".."FF8A2E59")
})
g.defineResource("fabric", {
    image="fabric",
    limitStat="FabricLimit",
    limitStatName="Fabric Limit",
    startingLimit=1000,
    color=objects.Color("#".."FFF353FB")
})
g.defineResource("bread", {
    image="bread",
    limitStat="BreadLimit",
    limitStatName="Bread Limit",
    startingLimit=1000,
    color=objects.Color("#".."FFB78652")
})
g.defineResource("fish", {
    image="fish",
    limitStat="FishLimit",
    limitStatName="Fish Limit",
    startingLimit=1000,
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


---@param amount number
function g.addXP(amount)
    local sn = currentSession
    sn.xp = sn.xp + amount
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
---| "fish"

---@type table<g.Category, true|nil>
g.CATEGORIES = {
    grass = true,
    berry = true,
    mushroom = true,
    chest = true,
    slime = true,
    fish = true,
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
    def.name = loc(name, nil, {context = def.nameContext})
    assert(not (def.rawDescription and def.description), "raw description and description is mutually exclusive")
    if def.rawDescription then
        def.description = def.rawDescription
    else
        def.description = loc(def.description, nil, {context = def.descriptionContext})
    end
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


function g.clearEffects()
    return currentSession.mainWorld:_clearEffects()
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
    isHidden = true,
    getEntityCount = true,
    spawnEntity = true,
    getPriceOverride = true,
    drawUI = true
}


---@param id string
---@param name string
---@param def g.UpgradeDefinition
function g.defineUpgrade(id, name, def)
    if not (def.kind and UPGRADE_KINDS[def.kind]) then
        error("Invalid upgrade-kind: " .. tostring(def.kind),2)
    end

    ---@cast def g.UpgradeInfo
    def.name = loc(name, nil, {context = def.nameContext})
    assert(not (def.rawDescription and def.description), "raw description and description is mutually exclusive")
    if def.rawDescription then
        def.description = function()
            return def.rawDescription
        end
    elseif def.description then
        local d = def.description --[[@as string]]
        def.description = localization.newInterpolator(d, {context = def.descriptionContext})
    end

    if def.procGen then
        assert(def.procGen.weight > 0, "weight must be positive")
        assert(#def.procGen.distance == 2, "distance must be integer length of 2")
        assert(def.procGen.distance[1] <= def.procGen.distance[2], "invalid distance")
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
---@field public growthOx number? Extra x offset applied to all growth sprites
---@field public growthOy number? Extra y offset applied to all growth sprites

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


---@param name string
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
    assert(not (tabl.rawDescription and tabl.description), "raw description and description is mutually exclusive")
    if tabl.rawDescription then
        tabl.description = tabl.rawDescription
    elseif tabl.description then
        tabl.description = loc(tabl.description, nil, {context = tabl.descriptionContext})
    end

    tokenDefinitions[tokType] = tabl
    ---@cast tabl g.Token
    tabl.type = tokType
    ---@diagnostic disable-next-line: inject-field
    tabl.name = loc(name, nil, {context = tabl.nameContext})
    local mt = {__index = tabl}
    tokenMts[tokType] = mt
    reverseTokMt[mt] = true
    g.TOKEN_LIST[#g.TOKEN_LIST+1] = tokType

    ---@type g.UpgradeDefinition
    local upgradeDef = {
        nameContext = tabl.upgradeNameContext or tabl.nameContext,
        image = tabl.image,
        populateTokenPool = function(self, level, tokens) ---@diagnostic disable-line
            tokens:add(tokType, level)
        end,
        maxLevel = tabl.maxLevel or nil,
        description = oldDescription,
        descriptionContext = tabl.upgradeDescriptionContext or tabl.descriptionContext,
        kind = "TOKEN",
        tokenType = tokType,
        procGen = tabl.procGen,
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
        local gox, goy = stalkInfo.growthOx or 0, stalkInfo.growthOy or 0
        for _, pos in ipairs(stalkInfo.growthpos) do
            g.drawImage(tinfo.growths.growth, x + pos.x + gox, y + pos.y + goy, rot, sx, sy, kx, ky)
        end
    end
end


local DEFAULT_MIN_SPACING = 12


function g.canSpawnTokenHere(x,y, minSpacing)
    -- checks whether we are "too close" to another token,
    --  and whether we could spawn a new token at this pos
    minSpacing = minSpacing or DEFAULT_MIN_SPACING
    local world = g.getSn().mainWorld

    local tooClose = false
    world.tokenPartition:query(x,y, function(tok)
        local dx = x - tok.x
        local dy = y - tok.y
        local distSq = dx*dx + dy*dy
        if distSq < minSpacing * minSpacing then
            tooClose = true
            return true -- stop iteration early
        end
    end)
    return not tooClose
end


---@param x number
---@param y number
---@param leeway number?
---@return number
---@return number
function g.clampInsideWorld(x,y, leeway)
    leeway = leeway or 8
    local w,h = g.getWorldDimensions()
    x = helper.clamp(x, leeway, w - leeway*2)
    y = helper.clamp(y, leeway, h - leeway*2)
    return x,y
end


---@param x number
---@param y number
---@param w number
---@param h number
---@param minSpacing number?
---@param maxAttempts integer?
local function getRandomPos(x, y, w, h, minSpacing, maxAttempts)
    maxAttempts = maxAttempts or 20
    minSpacing = minSpacing or DEFAULT_MIN_SPACING
    for attempt = 1, maxAttempts do
        local px = x + math.random() * w
        local py = y + math.random() * h

        if g.canSpawnTokenHere(px,py, minSpacing) then
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
---@field shadow (false|"shadow_medium"|"shadow_small"|"shadow_big")?
---@field sx number?
---@field sy number?
---@field ox number?
---@field oy number?
---@field rot number?
---@field alpha number?
---@field orbitRing integer?
---@field bulgeAnimation {time: number, magnitude: number, duration:number}?
---@field image string?
---@field drawOrder number?
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
    local x, y = getRandomPos(pad,pad, worldW-pad*2,worldH-pad*2)

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



-- difference between delete/destroy:
--[[
Destroy = delete + earn resources, particles, etc.
Delete = delete instantly. Nothing else.
]]

---@param tok g.Token
---@return boolean
function g.deleteToken(tok)
    local w = g.getMainWorld()
    if tok.___destroyed then
        return false -- already been destroyed.
    end
    tok.___destroyed = true

    if tok.wasSpawnedViaTokenPool then
        -- if it was spawned via token-pool, then we should record its destroyTime!
        --  (this way, world.lua will spawn it back in future)
        if not w.tokenDestroyTime[tok.type] then
            w.tokenDestroyTime[tok.type] = {}
        end
        table.insert(w.tokenDestroyTime[tok.type], g.getWorldTime())
    end

    w.tokens:removeBuffered(tok)
    return true
end


---@param tok g.Token
---@return boolean
function g.destroyToken(tok)
    if tok.___destroyed then
        -- already been destroyed.
        return false
    end

    if tok.category then
        local name = "totalCategoryHarvested_"..tok.category
        g.incrementMetric(name)
    end
    g.incrementMetric("totalTokensHarvested")

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
        local gox, goy = stalkInfo.growthOx or 0, stalkInfo.growthOy or 0
        for _, pos in ipairs(stalkInfo.growthpos) do
            g.spawnEntity("growth_falling", tok.x + pos.x + gox, tok.y + pos.y + goy, tok.growths.growth, tok.y + 8)
        end
    end

    g.deleteToken(tok)

    local cate = tok.category
    -- g.playWorldSound("plop_on_destroy_1", 1.2,2.7, 0.3, 0.4)
    -- g.playWorldSound("plop_on_destroy_2", 1.3,0.4, 0.2, 0.3)

    -- g.playWorldSound("pop_on_destroy_1", 1.5,0.2, 0.2, 0.05)
    g.playWorldSound("pop_on_destroy_2", 1.2,0.2, 0.2, 0.05)
    do return true end
    if (cate == "grass") or (cate == "berry") then
        -- todo: this is hacky and not robust, concating the name
        -- what if the sound doesnt exist? (fails at runtime)
        local name = "hit_grass2"
        g.playWorldSound(name, 1,0.4, 0.1)
    else
        local name = "chest_on_destroy_" .. love.math.random(1,3)
        g.playWorldSound(name, 1,0.3, 0.1)
    end
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
    if tok.slimed then
        dmg = dmg * 1.2
    end
    local displayDmg = math.min(dmg, math.max(tok.health, 0))

    -- Ensure lagged health number is updated first before tok.health
    local t = helper.clamp(tok.timeSinceDamaged / consts.LAGGED_HEALTHBAR_DURATION, 0, 1)
    t = helper.clamp(helper.EASINGS.easeInCubic(t), 0, 1)
    tok.laggedHealth = helper.lerp(tok.laggedHealth, tok.health, t)

    -- Now update tok.health
    tok.health = math.max(tok.health - dmg, 0)
    tok.timeSinceDamaged = 0
    g.call("tokenDamaged", tok, dmg)

    if tok.health <= 0 then
        currentSession.mainWorld:_incrementCombo()
    end

    currentSession.mainWorld:_spawnDamageNumber(
        displayDmg,
        tok.x,
        tok.y - 5,
        g.COLORS.DAMAGE_NUMBERS_BY_CATEGORY[tok.category] or objects.Color.WHITE
    )

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
    local dmg = hitMult * g.stats.HitDamage
    g.damageToken(tok, dmg)

    if love.math.random() < g.stats.CritChance then
        g.critToken(tok, dmg)
    end

    local r = love.math.random()
    if r < 0.333 then
        g.spawnParticle("xp1", tok.x, tok.y, 2)
    elseif r < 0.666 then
        g.spawnParticle("xp2", tok.x, tok.y, 1)
    else
        g.spawnParticle("xp3", tok.x, tok.y, 2)
    end

    if love.math.random() < 0.5 then
        -- hit_generic_1 is the softest and best. Ive tried all of em!
        g.playWorldSound("hit_generic_1", 1,0.15,0.35,0.05)
    else
        g.playWorldSound("hit_generic_2", 1.3,0.07,0.25,0.02)
    end

    if tok.category == "grass" then
        if love.math.random()<0.5 then
            g.playWorldSound("hit_grass",1,0.2, 0.1)
        else
            g.playWorldSound("hit_grass2",1,0.3, 0.1)
        end
    else
        g.playWorldSound("hit_soft", 1, 0.18, 0.3)
        -- g.playWorldSound("hit_billiard", 1, 0.18, 0.3)
    end
end


local CRIT = "{c r=1 g=0.3 b=0.2}{o}"..loc("CRIT!", {}, {
    context = "As in, an abbreviation for a critical hit"
}).."{/o}{/c}"

function g.critToken(tok, dmg)
    dmg = dmg * g.stats.CritDamageMultiplier
    tok.health = tok.health - dmg
    g.call("tokenCrit", tok, dmg)
    worldutil.spawnText(CRIT, tok.x, tok.y-8, 0.45, 10)
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




-- functions for bosses:
do
---@type table<string, true>
local VALID_BOSSES = {}

---@type table<integer, g.TokenInfo>
local PRESTIGE_TO_BOSS = {}
---@type integer[]
local MAX_PRESTIGE_INDICES = {}


---@param tok g.Token
local function killBoss(tok)
    local bossId = g.getBossIdForPrestige(g.getPrestige())
    if not bossId then
        log.error("another wat??")
        return
    end

    local bossPrestige = g.getTokenInfo(bossId)
    if bossPrestige and bossPrestige.type == tok.type then
        g.getSn().bossesKilled[tok.type] = true
        achievements.unlockAchievement("SLAYER")
        g.call("bossSlain")
    else
        log.error("wat??") -- wtf? what happened here?
    end
end

---@param id string
---@param prestige integer
---@param healthToken string|nil
---@param def g.TokenDefinition
function g.defineBoss(id, prestige, healthToken, def)
    def.bossfight = {healthToken=healthToken}
    def.tokenDestroyed = killBoss
    g.defineToken(id, "\0boss " .. prestige, def)
    PRESTIGE_TO_BOSS[prestige] = g.getTokenInfo(id)
    VALID_BOSSES[id] = true
    MAX_PRESTIGE_INDICES[#MAX_PRESTIGE_INDICES+1] = prestige
    table.sort(MAX_PRESTIGE_INDICES, function(a, b) return a > b end)
end

function g.summonBoss(bossId)
    assert(VALID_BOSSES[bossId])
    return g.spawnToken(bossId, 0,0)
end

---@param prestige integer
---@return string?
function g.getBossIdForPrestige(prestige)
    for _, mul in ipairs(MAX_PRESTIGE_INDICES) do
        if (prestige + 1) % (mul + 1) == 0 then
            local tInfo = assert(PRESTIGE_TO_BOSS[mul])
            return tInfo.type
        end
    end

    return nil
end

--- returns the boss token, if there's a bossfight happening
---@return g.Token?
function g.getBossToken()
    local w = g.getMainWorld()
    return w.bossToken
end

end


local hud = HUD()

function g.getHUD()
    return hud
end



-- g.playWorldSound
-- g.playUISound
do

----------
-- SFXs --
----------

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
---@param typeFilter? "BACKGROUND"|"HAT"|"AVATAR"
function g.getUnlockedCosmetics(typeFilter)
    local t = cosmetics.getUnlocked(typeFilter)
    table.sort(t)
    return t
end

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


----------
-- BGMs --
----------

-- Higher number means higher priority.
g.BGMID = {
    TITLE = 999, -- Title and settings
    MAP = 1, -- Map scene
    AMBIENT = 2, -- Harvest scene / Upgrade scene
    CUSTOMIZATION = 3, -- Customization scene
    BOSS = 100, -- Boss theme
}


---@param path string
---@param prio integer
---@param isAmbient boolean?
local function registerBGMFromDirectories(path, prio, isAmbient)
    ---@type string[]
    local files = {}

    g.walkDirectory(path, function(filename)
        local pathrev = filename:reverse()
        local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

        if validExtensions[ext] then
            local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

            if #basename > 0 then
                local name = basename:sub(1, -#ext - 2)
                if name:sub(1,1) ~= "_" then
                    files[#files+1] = filename
                end
            end
        end
    end)

    if #files == 0 then
        error("no bgm files in "..path)
    end

    return bgm.register(prio, files, isAmbient)
end

-- We cannot use g.walkDirectory because we need all the files first then register
-- the BGM in one go using `bgm.register`.
registerBGMFromDirectories("assets/bgm/boss", g.BGMID.BOSS, false)
registerBGMFromDirectories("assets/bgm/customization", g.BGMID.CUSTOMIZATION, true)
registerBGMFromDirectories("assets/bgm/ambient", g.BGMID.AMBIENT, true)
registerBGMFromDirectories("assets/bgm/map", g.BGMID.MAP, true)
registerBGMFromDirectories("assets/bgm/ambient", g.BGMID.TITLE, true)


---Request playing specific BGM ID
---@param id integer BGM ID. Use `g.BGMID` for the fixed constants.
function g.requestBGM(id)
    return bgm.request(id)
end


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

    CRIT = objects.Color("#" .. "FFA43929"),

    CANT_AFFORD = objects.Color("#".."FFD72D2D"),
    CAN_AFFORD = objects.Color("#".."FF73FF73"),

    MONEY = objects.Color("#".."FFF7D127"),
    RECOMMENDED = objects.Color("#".."FF9DEC4E"),
    UPGRADE_CONNECTOR = objects.Color("#".."FF000000"),

    RARITIES = {
        [0] = objects.Color("#".."FF8A8A8A"), -- Common (grey)
        [1] = objects.Color("#".."FF4A9EFF"), -- Rare (blue)
        [2] = objects.Color("#".."FFFFD700"), -- Legendary (gold)
    },
}

do
for k,v in pairs(g.COLORS) do
    if getmetatable(v) == objects.Color then
        richtext.defineEffect(k, function (args, x,y, context, next)
            local r,gg,b,a = lg.getColor()
            lg.setColor(v)
            next(context.textOrDrawable, x,y)
            lg.setColor(r,gg,b,a)
        end)
    end
end
end


return g
