---@class text.EffectGroup: objects.Class
local EffectGroup = objects.Class("text:EffectGroup")

function EffectGroup:init()
    ---@type table<string, fun(context:any,characters:text.Character)>
    self.effectList = {}
end

---Add new effect for rich text formatting.
---@generic T
---@param name string Effect name.
---@param effectupdate fun(context:T,characters:text.Character) Function that apply the effect to subtext.
function EffectGroup:addEffect(name, effectupdate)
    self.effectList[name] = effectupdate
end

---Get effect info.
---
---This is internal function.
---@param name string Effect name.
function EffectGroup:getEffectInfo(name)
    return self.effectList[name]
end

---Remove the effect.
---@param name string Effect name.
function EffectGroup:removeEffect(name)
    self.effectList[name] = nil
end

if false then
    ---Create new effect group.
    ---@return text.EffectGroup
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function EffectGroup() end
end

---Duplicate the current effect group, copying all the added effects in this effect group to new one.
---@return text.EffectGroup effectgroup The new effect group.
function EffectGroup:clone()
    local result = EffectGroup()
    for k, v in pairs(self.effectList) do
        result:addEffect(k, v)
    end

    return result
end

return EffectGroup
