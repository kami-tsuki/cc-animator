local sin, cos, abs = math.sin, math.cos, math.abs

local M = {}

function M.render(ctx, t, config)
    local t1 = t * (config.speed or 1.55)
    local px = sin(t1 * 0.9) * 0.45
    local py = cos(t1 * 1.2) * 0.38

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local gx = abs(sin(nx * 13.0 + t1 * 2.4))
            local gy = abs(cos(ny * 11.0 - t1 * 2.0))
            local grid = gx * gx * gx * gx * 0.42 + gy * gy * gy * gy * 0.42

            local pulse = sin((nx * nx + ny * ny) * 42.0 - t1 * 7.0)
            local diagonal = cos((nx - ny * 0.8) * 16.0 + t1 * 3.5)

            local dx = nx - px
            local dy = ny - py
            local core = 1.05 / (1 + 20 * (dx * dx + dy * dy))

            local energy = 0.18 + grid + pulse * 0.14 + diagonal * 0.08 + core * 0.60
            local sparkle = sin(nx * 17.0 + t1 * 7.8) + cos(ny * 21.0 - t1 * 5.5)
            ctx.setSample(x, ctx.shade(energy, sparkle))
        end

        ctx.blitRow(y)
    end
end

return M
