local sin, cos, abs = math.sin, math.cos, math.abs
local min, max = math.min, math.max

local M = {}

function M.render(ctx, t, config)
    local chaos = ctx.derivedTuning.chaos or 1
    local warp = ctx.derivedTuning.warp or 1
    local jitter = ctx.derivedTuning.jitter or 0
    local t1 = t * (config.speed or (1.85 + chaos * 0.22))
    local aspect = min(2.8, max(1.0, ctx.height / max(1, ctx.width)))
    local pulse = 0.5 + 0.5 * sin(t1 * (4.6 + chaos * 0.35))

    for y = 1, ctx.height do
        local ny = ctx.yNorm[y] or 0
        local diagonalA = ny * ((0.24 + jitter * 0.2) / aspect)
        local diagonalB = ny * ((-0.18 + jitter * 0.12) / aspect)
        local spineA = diagonalA
            + sin(ny * (6.5 * warp) + t1 * 1.9) * ((0.08 + abs(jitter) * 0.10) / aspect)
            + cos(ny * (11.0 * warp) - t1 * 2.8) * ((0.04 + chaos * 0.01) / aspect)
        local spineB = diagonalB
            + cos(ny * (5.0 * warp) - t1 * 1.6) * ((0.07 + abs(jitter) * 0.08) / aspect)
            + sin(ny * (9.5 * warp) + t1 * 2.4) * ((0.03 + chaos * 0.01) / aspect)
        local branchA = sin(ny * ((20.0 + aspect * 2.5) * warp) - t1 * (5.6 + chaos * 0.5)) * ((0.10 + jitter * 0.2) / aspect)
        local branchB = cos(ny * ((29.0 + aspect * 3.0) * warp) + t1 * (6.6 + chaos * 0.45)) * ((0.07 + abs(jitter) * 0.15) / aspect)

        for x = 1, ctx.width, ctx.renderStep do
            local nx, localNy = ctx.getAdaptiveNorm(x, y)
            local center = spineA * 0.6 + spineB * 0.4

            local core = 1.35 / (1 + abs(nx - center) * (26.0 + aspect * 8.0 + chaos * 5.0))
            local shell = max(0, 1 - abs(nx - center) * (3.4 + aspect * 0.8)) * (0.20 + pulse * 0.16)

            local distA = abs(nx - (spineA + branchA + sin(localNy * 12.0 + t1) * 0.025 * chaos))
            local distB = abs(nx - (spineB - branchA * 0.7 + branchB + cos(localNy * 16.0 - t1) * 0.020 * chaos))
            local distC = abs(nx - (center + branchB * 0.8 - sin(localNy * 19.0 + t1 * 0.8) * 0.018 * chaos))

            local strike = 0.95 / (1 + distA * (44.0 + aspect * 5.0 + chaos * 7.0))
                + 0.78 / (1 + distB * (58.0 + aspect * 6.0 + chaos * 8.0))
                + 0.62 / (1 + distC * (72.0 + aspect * 7.0 + chaos * 10.0))

            local arcNoise = abs(sin((nx * 42.0 - localNy * (14.0 * warp)) + t1 * (8.4 + chaos))) * 0.10
                + abs(cos((nx * 33.0 + localNy * (18.0 * warp)) - t1 * (7.2 + chaos * 0.7))) * 0.08
            local glow = max(0, 1 - (nx * nx * 0.95 + localNy * localNy * 0.72)) * (0.12 + pulse * 0.08)

            local energy = 0.08 + core * 0.42 + shell + strike * (0.44 + pulse * 0.18) + arcNoise + glow
            local sparkle = sin(t1 * (12.0 + chaos) + nx * 34.0) + cos(t1 * (8.5 + chaos * 0.6) - localNy * 28.0)
            ctx.setSample(x, ctx.shade(energy, sparkle + strike))
        end

        ctx.blitRow(y)
    end
end

return M
