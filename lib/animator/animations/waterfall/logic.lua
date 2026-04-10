local sin, cos = math.sin, math.cos
local min, max = math.min, math.max

local M = {}

function M.render(ctx, t, config)
    local chaos = ctx.derivedTuning.chaos or 1
    local warp = ctx.derivedTuning.warp or 1
    local jitter = ctx.derivedTuning.jitter or 0
    local t1 = t * (config.speed or (1.55 + chaos * 0.18))
    local aspect = min(2.5, max(1.0, ctx.height / max(1, ctx.width)))

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local bandA = sin(ny * ((18.0 + aspect * 4.0) * warp) - t1 * (4.8 + chaos * 0.4) + sin(nx * 5.0 + t1 * 0.7) * (1.8 + chaos * 0.3))
            local bandB = cos(ny * ((11.0 + aspect * 3.0) * warp) + t1 * (3.6 + chaos * 0.3) + cos(nx * 6.5 - t1 * 0.5) * (1.6 + chaos * 0.2))
            local seam = math.abs(sin(nx * (14.0 + chaos * 2.0) + t1 * (1.2 + jitter)))
            local splash = sin((ny * 34.0 - nx * 7.0) * warp - t1 * (7.2 + chaos)) * 0.10
            local fall = max(0, bandA * 0.20 + bandB * 0.18 + seam * 0.26 + splash)
            local energy = 0.14 + fall + max(0, 1 - math.abs(nx) * 1.3) * (0.16 + chaos * 0.04)
            local sparkle = sin(t1 * (9.5 + chaos) + ny * 24.0) + cos(t1 * (6.0 + chaos * 0.6) - nx * 22.0)
            ctx.setSample(x, ctx.shade(energy, sparkle))
        end

        ctx.blitRow(y)
    end
end

return M
