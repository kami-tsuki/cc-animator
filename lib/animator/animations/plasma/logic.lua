local sin, cos = math.sin, math.cos

local M = {}

function M.render(ctx, t, config)
    local t1 = t * (config.speed or 1.25)

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local ring = nx * nx + ny * ny

            local plasma = sin(nx * 9.5 + t1 * 2.1)
                + cos(ny * 11.5 - t1 * 2.8)
                + sin((nx + ny) * 8.0 + t1 * 1.7)
                + cos(ring * 26.0 - t1 * 5.2)

            local tunnel = 0.95 / (1 + ring * 10.5)
            local drift = sin((nx * nx * 9.0 - ny * 13.0) - t1 * 3.6)
            local energy = 0.28 + plasma * 0.10 + drift * 0.12 + tunnel * 0.72
            local sparkle = sin(t1 * 6.5 + nx * 23.0) + cos(t1 * 4.2 - ny * 18.0)

            ctx.setSample(x, ctx.shade(energy, sparkle))
        end

        ctx.blitRow(y)
    end
end

return M
