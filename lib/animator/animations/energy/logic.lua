local sin, cos = math.sin, math.cos
local max = math.max

local M = {}

function M.render(ctx, t, config)
    local t1 = t * (config.speed or 1.35)
    local ax = sin(t1 * 0.80) * 0.58
    local ay = cos(t1 * 1.15) * 0.34
    local bx = cos(t1 * 0.55 + 1.40) * 0.42
    local by = sin(t1 * 0.95 + 0.80) * 0.52
    local scanY = ((t1 * 3.2) % (ctx.height + 8)) - 4

    for y = 1, ctx.height do
        local scanBoost = 0.10 / (1 + (y - scanY) * (y - scanY) * 0.9)

        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)

            local flowA = sin(nx * 11.0 + t1 * 2.8 + sin(ny * 4.0 - t1 * 1.2) * 2.2)
            local flowB = cos((nx * 5.5 - ny * 8.0) * 2.4 - t1 * 3.2)
            local flowC = sin((nx * nx * 13.0 + ny * ny * 17.0) * 5.2 - t1 * 4.6)
            local stream = sin((nx + ny * 0.35) * 18.0 - t1 * 4.8 + sin(nx * 6.0 + t1))

            local dx1 = nx - ax
            local dy1 = ny - ay
            local dx2 = nx - bx
            local dy2 = ny - by

            local nodeGlow = 0.90 / (1 + 18 * (dx1 * dx1 + dy1 * dy1))
                + 0.72 / (1 + 22 * (dx2 * dx2 + dy2 * dy2))

            local vignette = max(0, 1 - (nx * nx * 0.68 + ny * ny * 1.10))
            local energy = 0.36
                + flowA * 0.13
                + flowB * 0.11
                + flowC * 0.10
                + stream * 0.12
                + nodeGlow * 0.55
                + scanBoost

            energy = math.max(0, math.min(1, energy * (0.55 + vignette * 0.62)))
            local sparkle = sin(t1 * 7.0 + nx * 21.0 - ny * 17.0)
                + cos(t1 * 5.0 + nx * 13.0 + ny * 19.0)

            ctx.setSample(x, ctx.shade(energy, sparkle))
        end

        ctx.blitRow(y)
    end
end

return M
