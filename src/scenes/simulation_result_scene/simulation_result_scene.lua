local FreeCameraScene = require("src.scenes.FreeCameraScene")
local simulation = require("src.world.simulation")

---@class SimulationResultScene: FreeCameraScene
local simresult = FreeCameraScene()

function simresult:enter()
    g.delSession()
    local result = simulation.getResult()

    -- Save simulation
    local datetime = os.date("!%Y%m%dT%H%M%S")
    local base = "simulation_output/"..datetime
    assert(love.filesystem.createDirectory(base.."/tree_snapshots"))

    love.filesystem.write(base.."/save.json", json.encode(result.save))
    love.filesystem.write(base.."/graph.json", json.encode(result.graphs))
    local basetree = base.."/tree_snapshots"
    for _, tsn in ipairs(result.treeSnapshots) do
        local filename = math.floor(tsn.x + 0.5)..".json"
        love.filesystem.write(basetree.."/"..filename, json.encode(tsn.y))
    end
end

function simresult:leave()
    love.event.quit()
end

return simresult
