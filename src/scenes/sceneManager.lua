

local sceneManager = {}


local currentScene



local nameToScene = {--[[
    [name] -> Scene
]]}



local allScenes = objects.Array()

local SCENE_PATH = "src/scenes/"
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
    nameToScene[name] = scene
end



function sceneManager.gotoScene(sceneName)
    assert(nameToScene[sceneName])
    currentScene = nameToScene[sceneName]
end


function sceneManager.getCurrentScene()
    return currentScene
end

return sceneManager

