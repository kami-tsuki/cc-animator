local sin, cos = math.sin, math.cos

local M = {}

function M.render(ctx, t, config)
    local getAdaptiveNorm = ctx.getAdaptiveNorm
    local setSample = ctx.setSample
    local shade = ctx.shade
    local blitRow = ctx.blitRow
    local width = ctx.width
    local height = ctx.height
    local step = ctx.renderStep
    local t1 = t * (config.speed or 1.75)

    for y = 1, height do
        for x = 1, width, step do
            local nx, ny = getAdaptiveNorm(x, y)
            local ring = nx * nx + ny * ny
            local spiralA = sin((nx * 10.0 + ny * 9.0) + t1 * 4.0)
            local spiralB = cos((nx * 12.0 - ny * 11.0) - t1 * 3.3)
            local tunnel = sin(ring * 56.0 - t1 * 8.5)
            local core = 1.15 / (1 + ring * 13.0)

            local energy = 0.12 + spiralA * 0.14 + spiralB * 0.14 + tunnel * 0.16 + core * 0.62
            local sparkle = sin(t1 * 9.0 + nx * 28.0 - ny * 12.0) + cos(t1 * 7.0 + ny * 24.0)
            setSample(x, shade(energy, sparkle))
        end

        blitRow(y)
    end
end

return M
