

---@class SceneManager
local sceneManager = {}


local currentScene, currentSceneName
local lastSceneName


local nameToScene = {--[[
    [name] -> Scene
]]}



local allScenes = objects.Array()

local SCENE_PATH = "src/scenes/"

function sceneManager.loadScenes()
    for _, folder in ipairs(love.filesystem.getDirectoryItems(SCENE_PATH)) do
        if love.filesystem.getInfo(SCENE_PATH .. folder, "directory") then
            allScenes:add(folder)
        end
    end

    for _, name in ipairs(allScenes) do
        local scene = require("src.scenes." .. name .. "." .. name)
        if scene.init then
            scene:init()
        end
        scene.name = name
        nameToScene[name] = scene
    end
end



function sceneManager.gotoScene(sceneName)
    assert(nameToScene[sceneName])
    local oldScene = nameToScene[currentSceneName]
    if oldScene and oldScene.leave then
        oldScene:leave()
    end
    lastSceneName = currentSceneName
    currentSceneName = sceneName
    currentScene = nameToScene[sceneName]
    if currentScene.enter then
        currentScene:enter()
    end
end

function sceneManager.gotoLastScene()
    if lastSceneName then
        return sceneManager.gotoScene(lastSceneName)
    end
end


---@return table
---@return string
function sceneManager.getCurrentScene()
    return currentScene, currentSceneName
end

return sceneManager

