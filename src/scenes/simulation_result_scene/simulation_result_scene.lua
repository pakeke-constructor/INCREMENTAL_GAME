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

    self.result = result
    self.mode = 0
    self.drawGraph = {
        {"Purchased Upgrades", result.graphs.purchasedUpgradesGraph},
        {"New Purchased Upgrades", result.graphs.newPurchasedUpgradesGraph},
        {"Resource (Money)", result.graphs.resourceGraph.money},
        {"Resource/second (Money)", result.graphs.rpsGraph.money},
    }
    love.window.setTitle("Simulation Result: "..datetime)
end

function simresult:leave()
    love.event.quit()
end

---@param k love.KeyConstant
function simresult:keyreleased(k)
    if k == "escape" then
        love.event.quit()
    elseif k == "left" then
        self.mode = (self.mode - 1) % 5
    elseif k == "right" then
        self.mode = (self.mode + 1) % 5
    end
end



---@param text string
---@param font love.Font
---@param x number
---@param y number
local function drawSimpleTextRightCenter(text, font, x, y)
    local w = font:getWidth(text)
    love.graphics.print(text, font, x, y, 0, 1, 1, w, font:getHeight() / 2)
end

---@param font love.Font
---@param x number
---@param y number
local function drawSimpleTextCenterTop(text, font, x, y)
    text = tostring(text)
    local w = font:getWidth(text)
    love.graphics.print(text, font, x, y, 0, 1, 1, w / 2, 0)
end

---@param r kirigami.Region
---@param name string
---@param graphData _Simulation.Graph<number>[]
local function drawGraph(r, name, graphData)
    local graphR = r:padRatio(0.3)

    local gx, gy, gw, gh = graphR:get()
    local xmin, xmax, ymin, ymax = math.huge, -math.huge, math.huge, -math.huge

    for _, g in ipairs(graphData) do
        xmin = math.min(g.x, xmin)
        xmax = math.max(g.x, xmax)
        ymin = math.min(g.y, ymin)
        ymax = math.max(g.y, ymax)
    end

    -- Add 5% leighway
    local diffy = ymax - ymin
    ymin = math.floor(ymin - diffy * 0.05)
    ymax = math.ceil(ymax + diffy * 0.05)

    ---@type number[]
    local lines = {}
    for _, g in ipairs(graphData) do
        lines[#lines+1] = gx + gw * helper.remap(g.x, xmin, xmax, 0, 1)
        lines[#lines+1] = gy + gh * helper.remap(g.y, ymin, ymax, 1, 0)
    end

    local textR = r:set(nil, nil, nil, graphR.y - r.y)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", gx, gy, gw, gh)
    love.graphics.line(lines)
    -- TODO: Automatic label indicator
    love.graphics.line(graphR.x - 6, graphR.y, graphR.x, graphR.y)
    love.graphics.line(graphR.x - 6, graphR.y + graphR.h / 2, graphR.x, graphR.y + graphR.h / 2)
    love.graphics.line(graphR.x - 6, graphR.y + graphR.h, graphR.x, graphR.y + graphR.h)
    love.graphics.line(graphR.x, graphR.y + graphR.h, graphR.x, graphR.y + graphR.h + 6)
    love.graphics.line(graphR.x + graphR.w / 2, graphR.y + graphR.h, graphR.x + graphR.w / 2, graphR.y + graphR.h + 6)
    love.graphics.line(graphR.x + graphR.w, graphR.y + graphR.h, graphR.x + graphR.w, graphR.y + graphR.h + 6)

    love.graphics.printf(name, g.getBigFont(48), textR.x, textR.y, textR.w, "center")
    local f = g.getSmallFont(32)
    drawSimpleTextRightCenter(g.formatNumber(ymin), f, graphR.x - 8, graphR.y + graphR.h)
    drawSimpleTextRightCenter(g.formatNumber(helper.lerp(ymin, ymax, 0.5)), f, graphR.x - 8, graphR.y + graphR.h / 2)
    drawSimpleTextRightCenter(g.formatNumber(ymax), f, graphR.x - 8, graphR.y)
    drawSimpleTextCenterTop(xmin, f, graphR.x, graphR.y + graphR.h + 8)
    drawSimpleTextCenterTop(math.floor(xmax + 0.5), f, graphR.x + graphR.w, graphR.y + graphR.h + 8)
    drawSimpleTextCenterTop(math.floor(helper.lerp(xmin, xmax, 0.5) + 0.5), f, graphR.x + graphR.w / 2, graphR.y + graphR.h + 8)
end

function simresult:draw()
    ui.startUI()
    love.graphics.push("all")
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineWidth(2)

    local r = ui.getScreenRegion()

    if self.mode == 0 then
        local grid = r:grid(2, 2)
        for i, g in ipairs(grid) do
            local m = self.drawGraph[i]
            love.graphics.push()
            love.graphics.translate(g.x, g.y)
            love.graphics.scale(0.5)
            drawGraph(r, m[1], m[2])
            love.graphics.pop()
        end
    else
        local m = self.drawGraph[self.mode]
        drawGraph(r, m[1], m[2])
    end

    love.graphics.pop()
    ui.endUI()
end



return simresult
