local sin, cos, abs = math.sin, math.cos, math.abs
local min, max = math.min, math.max

local M = {}

function M.render(ctx, t, config)
    local getAdaptiveNorm = ctx.getAdaptiveNorm
    local setSample = ctx.setSample
    local shade = ctx.shade
    local blitRow = ctx.blitRow
    local width = ctx.width
    local height = ctx.height
    local step = ctx.renderStep
    local yNorm = ctx.yNorm
    local chaos = ctx.derivedTuning.chaos or 1
    local warp = ctx.derivedTuning.warp or 1
    local jitter = ctx.derivedTuning.jitter or 0
    local t1 = t * (config.speed or (1.8 + chaos * 0.22))
    local columnBias = min(2.8, max(1.0, height / max(1, width)))
    local boltA = sin(t1 * (1.6 + chaos * 0.25)) * ((0.26 + jitter) / columnBias)
    local boltB = cos(t1 * (1.0 + chaos * 0.20) + 1.4) * ((0.22 - jitter * 0.4) / columnBias)
    local pulse = 0.5 + 0.5 * sin(t1 * (5.5 + chaos))

    for y = 1, height do
        local ny = yNorm[y] or 0
        local spine = sin(ny * ((8.0 + columnBias) * warp) + t1 * 2.2) * ((0.18 + jitter * 0.4) / columnBias)
            + cos(ny * ((13.0 + columnBias * 1.5) * warp) - t1 * 3.4) * ((0.10 + abs(jitter) * 0.2) / columnBias)
        local branch = sin(ny * ((20.0 + columnBias * 2.0) * warp) - t1 * (5.2 + chaos * 0.5)) * ((0.12 + jitter * 0.3) / columnBias)

        for x = 1, width, step do
            local nx, localNy = getAdaptiveNorm(x, y)
            local distMain = abs(nx - (boltA + spine + sin(localNy * 9.0 + t1) * 0.03 * chaos))
            local distBranch = abs(nx - (boltB - spine * 0.7 + branch + cos(localNy * 13.0 - t1) * 0.02 * chaos))
            local strike = 1.30 / (1 + distMain * (34.0 + columnBias * 4.0 + chaos * 6.0))
                + 1.00 / (1 + distBranch * (48.0 + columnBias * 5.0 + chaos * 7.0))

            local ripples = sin((nx * (18.0 * warp) - localNy * 7.0) - t1 * (7.5 + chaos * 0.5)) * 0.10
                + cos((nx * 11.0 + localNy * (13.0 * warp)) + t1 * (5.5 + chaos * 0.4)) * 0.08

            local glow = max(0, 1 - (nx * nx * 0.85 + localNy * localNy * 0.75)) * (0.18 + chaos * 0.03)
            local flash = (pulse > 0.82 and 0.28 or 0.0)
            local energy = 0.10 + strike * (0.52 + pulse * 0.38) + ripples + glow + flash
            local sparkle = sin(t1 * (11.0 + chaos) + nx * 33.0) + cos(t1 * (8.0 + chaos * 0.8) - localNy * 27.0)

            setSample(x, shade(energy, sparkle + strike * (1 + chaos * 0.2)))
        end

        blitRow(y)
    end
end

return M
