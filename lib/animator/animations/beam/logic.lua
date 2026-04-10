local sin, cos = math.sin, math.cos
local min, max = math.min, math.max

local M = {}

function M.render(ctx, t, config)
    local chaos = ctx.derivedTuning.chaos or 1
    local warp = ctx.derivedTuning.warp or 1
    local jitter = ctx.derivedTuning.jitter or 0
    local t1 = t * (config.speed or (1.9 + chaos * 0.25))
    local aspect = min(2.8, max(1.0, ctx.height / max(1, ctx.width)))

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local wobble = sin(ny * (5.0 * warp) + t1 * 1.8) * (0.05 + chaos * 0.02)
            local shaftA = 1.20 / (1 + math.abs(nx - sin(t1 * 0.8 + ny * 3.0 * warp) * ((0.18 + jitter * 0.2) / aspect) - wobble) * (45 + aspect * 10 + chaos * 6))
            local shaftB = 1.05 / (1 + math.abs(nx - cos(t1 * 1.1 - ny * 2.0 * warp) * ((0.14 + jitter * 0.2) / aspect) + wobble * 0.6) * (55 + aspect * 8 + chaos * 7))
            local surge = sin(ny * (28.0 * warp) - t1 * (8.0 + chaos)) * 0.14 + cos(ny * (16.0 * warp) + t1 * (5.0 + chaos * 0.6)) * 0.10
            local halo = max(0, 1 - math.abs(nx) * (1.6 + aspect * 0.3)) * (0.18 + chaos * 0.04)
            local energy = 0.10 + shaftA * 0.56 + shaftB * 0.44 + surge + halo
            local sparkle = sin(t1 * (12.0 + chaos) + ny * 34.0) + cos(t1 * (7.0 + chaos * 0.5) + nx * 26.0)
            ctx.setSample(x, ctx.shade(energy, sparkle + shaftA * (1 + chaos * 0.15)))
        end

        ctx.blitRow(y)
    end
end

return M
