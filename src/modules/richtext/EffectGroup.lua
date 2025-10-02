---@class text.EffectGroup: objects.Class
local EffectGroup = objects.Class("text:EffectGroup")

function EffectGroup:init()
    ---@type table<string, fun(context:any,characters:text.Character)>
    self.effectList = {}

    ---@type table<string, {texture:love.Texture, quad?:love.Quad}>
    self.imageList = {}
end


---@param name string
---@return "EFFECT"|"IMAGE"|nil type The "type" of effect
function EffectGroup:getType(name)
    if self.imageList[name] then
        return "IMAGE"
    elseif self.effectList[name] then
        return "EFFECT"
    end
end



---Add new effect for rich text formatting.
---@generic T
---@param name string Effect name.
---@param effectupdate fun(context:T,characters:text.Character) Function that apply the effect to subtext.
function EffectGroup:defineEffect(name, effectupdate)
    self.effectList[name] = effectupdate
end


---Define an image that can be embedded in the rich text.
---@param name string image id.
---@param tex love.Texture
---@param quad love.Quad?
function EffectGroup:defineImage(name, tex, quad)
    self.imageList[name] = {
        texture = tex,
        quad = quad
    }
end


---Get effect info.
---
---This is internal function.
---@generic T
---@param name string Effect name.
---@return function
function EffectGroup:getEffectInfo(name)
    return self.effectList[name]
end


---Get image info.
---
---This is internal function.
---@generic T
---@param name string Effect name.
---@return {texture:love.Texture,quad?:love.Quad}
function EffectGroup:getImageInfo(name)
    return self.imageList[name]
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
        result.effectList[k] = v
    end
    for k,v in pairs(self.imageList) do
        result.imageList[k] = v
    end

    return result
end

return EffectGroup
