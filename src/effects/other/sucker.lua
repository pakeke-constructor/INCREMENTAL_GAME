local SUCKING_POWER = 32

g.defineEffect("black_cube", "Black Cube", {
    description = "Pull crops towards mouse position",
    image = "blackhole_effect",

    update = function(_, dt)
        local w = g.getMainWorld()
        local ww, wh = g.getWorldDimensions()
        local mx = w.mouseX or (ww / 2)
        local my = w.mouseY or (wh / 2)

        for _, gtok in ipairs(g.getMainWorld().tokens) do
            ---@cast gtok g.Token
            if not gtok.bossfight and helper.magnitude(gtok.y - my, gtok.x - mx) >= 16 then
                local rot = math.atan2(gtok.y - my, gtok.x - mx)
                gtok.x = helper.clamp(gtok.x - math.cos(rot) * SUCKING_POWER * dt, 0, ww)
                gtok.y = helper.clamp(gtok.y - math.sin(rot) * SUCKING_POWER * dt, 0, wh)
            end
        end
    end
})
