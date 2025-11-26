---@class _Simulation
local simulation = {}

local SIMULATION_FPS = 60
local SIMULATION_TIME_BUDGET = 0.01 -- 10ms time budget.

---@class _Simulation.State
---@field public duration number
---@field public time number
---@field public lastMouseHitTime number
---@field public mouse [number, number]
---@field public startResource g.Resources
---@field public xp number
---@field public lastExp number

---@private
---@type _Simulation.State|nil
simulation.state = nil

---@class _Simulation.Result
---@field public resource g.Resources Resource earned
---@field public rps g.Resources Average RPS across whole duration
---@field public duration number Simulation duration
---@field public xp number XP earned
---@field public xpps number Average XP earned across whole duration

---@private
---@type _Simulation.Result|nil
simulation.result = nil


function simulation.isSimulating()
    return not not simulation.state
end



local function getBestMousePositionInWorld()
    local worldW, worldH = g.getWorldDimensions()

    local RESOLUTION_X = 30
    local RESOLUTION_Y = 20

    local bestX, bestY = 0,0
    local bestRank = 0

    for x=0, worldW, (worldW/RESOLUTION_X) do
        for y=0, worldH, (worldH/RESOLUTION_Y) do
            local rank = 0
            g.iterateTokensInArea(x,y, g.stats.HarvestArea, function (tok)
                local hp = (tok.health / tok.maxHealth)
                rank = rank + (1.5 - hp)
            end)

            love.graphics.setColor(1,0,0)
            love.graphics.circle("line", x,y,g.stats.HarvestArea)

            if rank > bestRank then
                bestX, bestY, bestRank = x,y,rank
            end
        end
    end

    return bestX, bestY
end



---@param duration number
function simulation.start(duration)
    assert(not simulation.state, "simulation is in progress")

    local res = g.getResources()
    simulation.state = {
        duration = duration,
        time = 0,
        lastMouseHitTime = 0,
        mouse = {0, 0},
        startResource = {
            -- Need to copy because `g.getResources()` doesn't return a copy
            money = res.money,
            fabric = res.fabric,
            juice = res.juice,
            bread = res.bread,
            fish = res.fish
        },
        xp = 0,
        lastExp = g.getSn().xp
    }
end



---@return boolean @Is simulation completed?
function simulation.update()
    if not simulation.state then
        return true
    end

    local world = g.getMainWorld()
    local tstart = love.timer.getTime()

    while true do
        local dt = 1/SIMULATION_FPS
        local tsessupdate = love.timer.getTime()
        local sn = g.getSn()
        sn:_update(dt)

        -- Harvest area may reset the XP on level up, so have this to reduce
        -- the inaccuracies of the result
        local dxp = sn.xp < simulation.state.lastExp and sn.xp or (sn.xp - simulation.state.lastExp)
        simulation.state.xp = simulation.state.xp + dxp
        simulation.state.lastExp = sn.xp
        simulation.state.time = simulation.state.time + dt

        if simulation.state.time >= simulation.state.duration then
            local currentResource = g.getResources()
            local earnedResource = {
                money = currentResource.money - simulation.state.startResource.money,
                fabric = currentResource.fabric - simulation.state.startResource.fabric,
                bread = currentResource.bread - simulation.state.startResource.bread,
                juice = currentResource.juice - simulation.state.startResource.juice,
                fish = currentResource.fish - simulation.state.startResource.fish,
            }

            -- Done
            simulation.result = {
                resource = earnedResource,
                rps = {
                    money = earnedResource.money / simulation.state.time,
                    fabric = earnedResource.fabric / simulation.state.time,
                    bread = earnedResource.bread / simulation.state.time,
                    juice = earnedResource.juice / simulation.state.time,
                    fish = earnedResource.fish / simulation.state.time,
                },
                duration = simulation.state.time,
                xp = simulation.state.xp,
                xpps = simulation.state.xp / simulation.state.time
            }
            simulation.state = nil
            return true
        end

        if simulation.state.time - simulation.state.lastMouseHitTime > 0.3 then
            simulation.state.lastMouseHitTime = simulation.state.time
            simulation.state.mouse[1], simulation.state.mouse[2] = getBestMousePositionInWorld()
        end

        world:_enableMouseHarvester(simulation.state.mouse[1], simulation.state.mouse[2])

        local dtsessupdate = love.timer.getTime() - tsessupdate
        if (love.timer.getTime() - tstart + dtsessupdate) >= SIMULATION_TIME_BUDGET then
            -- Simulation incomplete
            return false
        end
    end
end



---@return _Simulation.Result
function simulation.getResult()
    assert(simulation.result, "simulation is in progress or not run yet")
    return simulation.result
end



return simulation
