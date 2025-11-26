
local Tree = require("src.upgrades.Tree")

local function getDevTree()
    local tree = Tree()

    local W = math.floor(math.sqrt(#g.UPGRADE_LIST))

    for i, upgId in ipairs(g.UPGRADE_LIST) do
        local x = (i-1) % W
        local y = math.floor((i-1) / W)
        local upg = tree:put(x, y, upgId)
        tree:markAsRoot(upg)
    end

    return tree
end


return getDevTree

