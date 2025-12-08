


local function defEveryXUpgrade(id, name, def)
    def.description = "Every "
    g.defineUpgrade(id, name, def)
end
