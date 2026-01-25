

--[[

Create simple particles-manager.


=== FEATURES: =======
----------------------
SoA fields for efficiency
Custom fields
Typechecking on fields
Custom rendering, Custom updating (via overrides)

]]

---@class g.modules.particles
local particles = {}

---@class particles.ParticlesWorld
---@field fields table<particles._Fields, any[]>
---@field extraFields table<string, (fun(x: any):boolean)|true>
---@field proxy table<particles._Fields|string, any>
---@field gravity number
---@field drawParticle fun(p: particles.Proxy)
---@field getParticleDuration fun(p: particles.Proxy): number
---@field updateParticle fun(p: particles.Proxy,dt:number)?
local ParticlesWorld = {}
local ParticlesWorld_mt = {__index=ParticlesWorld}

---@enum particles._Fields
local F = {
    id="id",
    x="x",
    y="y",
    vx="vx",
    vy="vy",
    lifetime="lifetime",
}

local DEFAULT_FIELD_TYPES = {
    id = "number",
    x = "number",
    y = "number",
    vx = "number",
    vy = "number",
    lifetime = "number",
}



local MAX_PARTICLES = 1000


---@param self particles.ParticlesWorld
---@param k particles._Fields
local function defField(self, k)
    self.fields[k] = table.new(MAX_PARTICLES, 0)
end


local function check(checkr,k,x)
    local bad=false
    if type(checkr)=="function" then
        bad = not checkr(x)
    elseif type(checkr)=="string" then
        bad = type(x)~=checkr
    end
    if bad then
        error(("Bad type for field: %s, %s"):format(k, type(x)), 3)
    end
end


---@class particles.Proxy
---@field id integer
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field lifetime number
local Proxy = {}


local Proxy_mt = {
    __newindex = function(t,k,v)
        local self = t._self
        ---@cast self particles.ParticlesWorld
        if DEFAULT_FIELD_TYPES[k] then
            check(DEFAULT_FIELD_TYPES[k],k,v)
        elseif self.extraFields[k] then
            check(self.extraFields[k],k,v)
        else
            error("Invalid field: " .. k, 2)
        end
        local arr = assert(self.fields[k])
        local i = self.i
        arr[i] = v
    end,
    __index = function(t,k)
        local self = t._self
        ---@cast self particles.ParticlesWorld
        local i = self.i
        local arr = self.fields[k]
        if not arr then
            error("Invalid field: "..k)
        end
        return arr[i]
    end
}



---@class particles._Args
---@field drawParticle fun(p: particles.Proxy)
---@field getParticleDuration fun(p: particles.Proxy): number
---@field extraFields table<string, (fun(x: any):boolean)|true>?
---@field gravity number?
---@field updateParticle fun(p: particles.Proxy,dt:number)?
local Args = {}

---@param args particles._Args
---@return particles.ParticlesWorld
function particles.newParticlesWorld(args)
    local self = setmetatable({}, ParticlesWorld_mt)

    self.currentId = 0
    self.fields = {}
    self.extraFields = args.extraFields or {}
    self.gravity = args.gravity or 0
    self.i = 1 -- the current "particle" we are viewing

    self.drawParticle = assert(args.drawParticle)
    self.getParticleDuration = assert(args.getParticleDuration)
    self.updateParticle = args.updateParticle

    self.proxy = setmetatable({
        _self=self
    }, Proxy_mt)

    -- struct of arrays:
    for k,_ in pairs(DEFAULT_FIELD_TYPES) do
        defField(self, k)
    end
    for k,v in pairs(self.extraFields) do
        defField(self, k)
    end
    return self
end




local function remove(self, i)
    local lastIdx = self:getParticleCount()

    if i == lastIdx then
        for _fieldName, arr in pairs(self.fields) do
            arr[i] = nil
        end
        return
    end

    for _fieldName, arr in pairs(self.fields) do
        arr[i] = arr[lastIdx]
        arr[lastIdx] = nil
    end
end




---@param x number
---@param y number
---@param vx number
---@param vy number
function ParticlesWorld:spawnParticle(x,y, vx,vy)
    self.i = #self.fields["x"] + 1
    local p = self.proxy
    local id = self.currentId + 1
    self.currentId = id
    p.x = x
    p.y = y
    p.vx = vx
    p.vy = vy
    p.id = id
    p.lifetime = 0
end


function ParticlesWorld:getParticleCount()
    return #self.fields["x"]
end


function ParticlesWorld:update(dt)
    local count = self:getParticleCount()
    for i=count,1,-1 do
        self.i = i
        local p = self.proxy
        if self.updateParticle then
            self.updateParticle(p,dt)
        end
        p.lifetime = p.lifetime + dt
        p.x = p.x + p.vx*dt
        p.y = p.y + p.vy*dt
        p.vy = p.vy + self.gravity*dt
        if p.lifetime > self.getParticleDuration(p) then
            -- destroy particle
            remove(self, i)
        end
    end
end



function ParticlesWorld:draw()
    local count = self:getParticleCount()
    for i=1,count do
        self.i = i
        local p = self.proxy
        self.drawParticle(p)
    end
end



function ParticlesWorld:clear()
    local count = self:getParticleCount()
    for i=count,1,-1 do
        remove(self, i)
    end
end



return particles

