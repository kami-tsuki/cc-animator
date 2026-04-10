local sin, cos = math.sin, math.cos

local M = {}

function M.render(ctx, t, config)
    local t1 = t * (config.speed or 2.1)
    local beat = 0.5 + 0.5 * sin(t1 * 3.5)

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local ribbonA = sin(nx * 14.0 + t1 * 4.8 + sin(ny * 7.0 - t1 * 1.5) * 2.5)
            local ribbonB = cos(ny * 16.0 - t1 * 3.9 + cos(nx * 5.5 + t1) * 2.0)
            local tunnel = sin((nx + ny) * 10.0 + t1 * 2.8) + cos((nx - ny * 0.7) * 13.0 - t1 * 4.4)
            local strobe = sin((nx * nx + ny * ny) * 60.0 - t1 * 10.0)

            local energy = 0.28 + ribbonA * 0.16 + ribbonB * 0.16 + tunnel * 0.10 + strobe * 0.08 + beat * 0.24
            local sparkle = sin(t1 * 13.0 + nx * 31.0) + cos(t1 * 9.0 + ny * 29.0) + beat
            ctx.setSample(x, ctx.shade(energy, sparkle))
        end

        ctx.blitRow(y)
    end
end

return M
