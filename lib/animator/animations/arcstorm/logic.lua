local sin, cos, abs = math.sin, math.cos, math.abs
local min, max = math.min, math.max

local M = {}

function M.render(ctx, t, config)
    local chaos = ctx.derivedTuning.chaos or 1
    local warp = ctx.derivedTuning.warp or 1
    local jitter = ctx.derivedTuning.jitter or 0
    local t1 = t * (config.speed or (1.9 + chaos * 0.24))
    local columnBias = min(2.8, max(1.0, ctx.height / max(1, ctx.width)))
    local boltA = sin(t1 * (1.5 + chaos * 0.18)) * ((0.20 + jitter * 0.2) / columnBias)
    local boltB = cos(t1 * (1.1 + chaos * 0.16) + 1.4) * ((0.18 - jitter * 0.15) / columnBias)
    local boltC = sin(t1 * (0.9 + chaos * 0.12) + 2.1) * ((0.16 + abs(jitter) * 0.1) / columnBias)
    local pulse = 0.5 + 0.5 * sin(t1 * (4.8 + chaos * 0.4))

    for y = 1, ctx.height do
        local ny = ctx.yNorm[y] or 0
        local spine = sin(ny * ((8.0 + columnBias) * warp) + t1 * 2.2) * ((0.13 + jitter * 0.2) / columnBias)
            + cos(ny * ((14.5 + columnBias) * warp) - t1 * 3.1) * ((0.08 + abs(jitter) * 0.1) / columnBias)
        local branchA = sin(ny * ((23.0 + columnBias * 2.0) * warp) - t1 * (5.4 + chaos * 0.4)) * ((0.10 + jitter * 0.2) / columnBias)
        local branchB = cos(ny * ((31.0 + columnBias * 2.8) * warp) + t1 * (6.2 + chaos * 0.5)) * ((0.07 + abs(jitter) * 0.1) / columnBias)

        for x = 1, ctx.width, ctx.renderStep do
            local nx, localNy = ctx.getAdaptiveNorm(x, y)
            local distMain = abs(nx - (boltA + spine + sin(localNy * 11.0 + t1) * 0.025 * chaos))
            local distBranch1 = abs(nx - (boltB - spine * 0.6 + branchA + cos(localNy * 15.0 - t1) * 0.018 * chaos))
            local distBranch2 = abs(nx - (boltC + spine * 0.45 + branchB - sin(localNy * 19.0 + t1 * 0.7) * 0.015 * chaos))

            local strike = 1.05 / (1 + distMain * (42.0 + columnBias * 5.0 + chaos * 6.0))
                + 0.78 / (1 + distBranch1 * (58.0 + columnBias * 5.0 + chaos * 8.0))
                + 0.62 / (1 + distBranch2 * (76.0 + columnBias * 6.0 + chaos * 10.0))

            local micro = abs(sin((nx * 52.0 + localNy * 17.0) * warp - t1 * (10.0 + chaos))) * 0.12
                + abs(cos((nx * 37.0 - localNy * 23.0) * warp + t1 * (8.0 + chaos * 0.6))) * 0.09
            local ripples = sin((nx * (18.0 * warp) - localNy * 7.0) - t1 * (7.2 + chaos * 0.4)) * 0.08
                + cos((nx * 11.0 + localNy * (13.0 * warp)) + t1 * (5.2 + chaos * 0.3)) * 0.06

            local glow = max(0, 1 - (nx * nx * 0.90 + localNy * localNy * 0.78)) * (0.12 + chaos * 0.02)
            local energy = 0.08 + strike * (0.42 + pulse * 0.20) + micro + ripples + glow
            local sparkle = sin(t1 * (11.5 + chaos) + nx * 33.0) + cos(t1 * (8.4 + chaos * 0.6) - localNy * 27.0)
            ctx.setSample(x, ctx.shade(energy, sparkle + strike * (0.9 + chaos * 0.12)))
        end

        ctx.blitRow(y)
    end
end

return M
