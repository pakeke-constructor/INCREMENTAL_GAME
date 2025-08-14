

local sceneManager = {}


local currentScene



local nameToScene = {--[[
    [name] -> Scene
]]}

for _, name in ipairs({
    "forest" })
do
    nameToScene[name] = require("src.scenes." .. name .. "." .. name)
end



function sceneManager.gotoScene(sceneName)
    currentScene = nameToScene[sceneName]
end


function sceneManager.getCurrentScene()
    return currentScene
end

return sceneManager

