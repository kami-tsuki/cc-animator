local sin, cos = math.sin, math.cos
local max = math.max

local M = {}

function M.render(ctx, t, config)
    local t1 = t * (config.speed or 1.45)

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local curtainA = sin(ny * 12.0 - t1 * 2.4 + sin(nx * 5.0 + t1) * 2.1)
            local curtainB = cos(nx * 7.5 + t1 * 1.7 + cos(ny * 4.5 - t1) * 1.8)
            local shimmer = sin((nx + ny * 0.6) * 16.0 + t1 * 4.1)
            local skyGlow = max(0, 1 - math.abs(nx) * 1.15) * 0.24

            local energy = 0.24 + curtainA * 0.18 + curtainB * 0.14 + shimmer * 0.10 + skyGlow
            local sparkle = sin(t1 * 8.0 + nx * 19.0) + cos(t1 * 5.5 - ny * 23.0)
            ctx.setSample(x, ctx.shade(energy, sparkle))
        end

        ctx.blitRow(y)
    end
end

return M
