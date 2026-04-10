local sin, cos, abs = math.sin, math.cos, math.abs
local min, max = math.min, math.max

local M = {}

function M.render(ctx, t, config)
    local chaos = ctx.derivedTuning.chaos or 1
    local warp = ctx.derivedTuning.warp or 1
    local jitter = ctx.derivedTuning.jitter or 0
    local t1 = t * (config.speed or (1.18 + chaos * 0.10))
    local columnBias = min(3.2, max(1.0, ctx.height / max(1, ctx.width)))
    local boardXScale = 0.95 + columnBias * 0.55
    local boardYScale = 1 / (0.85 + (columnBias - 1) * 0.45)
    local pulse = 0.5 + 0.5 * sin(t1 * (2.0 + chaos * 0.2))

    for y = 1, ctx.height do
        for x = 1, ctx.width, ctx.renderStep do
            local nx, ny = ctx.getAdaptiveNorm(x, y)
            local bx = nx * boardXScale
            local by = ny * boardYScale

            local traceAVal = abs(sin((bx + by * 0.82) * (10.5 * warp) + t1 * 0.70))
            local traceBVal = abs(cos((bx - by * 0.78) * (9.6 * warp) - t1 * 0.62))
            local traceCVal = abs(sin((bx * 0.72 + by) * (8.8 * warp) + t1 * 0.48))

            local traceA = max(0, 1 - traceAVal * (8.4 + columnBias))
            local traceB = max(0, 1 - traceBVal * (9.0 + columnBias))
            local traceC = max(0, 1 - traceCVal * (10.5 + columnBias * 0.6))
            local traces = max(traceA, traceB, traceC)

            local via1x = sin(t1 * 0.55 + by * 3.0) * 0.34
            local via1y = cos(t1 * 0.70 + bx * 2.5) * 0.28
            local via2x = cos(t1 * 0.40 - by * 2.8) * 0.26
            local via2y = sin(t1 * 0.62 + bx * 2.2) * 0.22

            local dx1, dy1 = bx - via1x, by - via1y
            local dx2, dy2 = bx - via2x, by - via2y
            local padA = max(0, 1 - (dx1 * dx1 + dy1 * dy1) * 26.0)
            local padB = max(0, 1 - (dx2 * dx2 + dy2 * dy2) * 30.0)
            local pads = max(padA, padB)

            local boltA = abs((bx + by * 0.56) - sin(t1 * 1.35 + by * 6.5) * (0.16 + jitter * 0.05))
            local boltB = abs((bx - by * 0.48) - cos(t1 * 1.65 - by * 7.8) * (0.13 + chaos * 0.02))
            local branch = abs((bx + by * 0.28) - sin(t1 * 2.10 + bx * 7.2 + by * 5.4) * 0.10)
            local strike = 0.82 / (1 + boltA * (42.0 + chaos * 7.0))
                + 0.62 / (1 + boltB * (56.0 + chaos * 8.0))
                + 0.38 / (1 + branch * (72.0 + chaos * 10.0))

            local copper = max(0, 1 - abs(sin((bx * 5.0 - by * 4.2) + t1 * 0.3)) * 3.5) * 0.05
            local boardGlow = max(0, 1 - (bx * bx * 0.42 + by * by * 0.86)) * (0.08 + pulse * 0.03)
            local energy = 0.04 + traces * 0.26 + pads * 0.18 + strike * 0.44 + copper + boardGlow
            local sparkle = sin(t1 * (9.6 + chaos) + bx * 24.0) + cos(t1 * (7.0 + chaos * 0.5) - by * 18.0)
            local ch, fg, bg = ctx.shade(energy, sparkle + strike)

            if strike > 0.72 then
                ch = "*"
            elseif pads > 0.34 then
                ch = "o"
            elseif traces > 0.18 then
                if traceA >= traceB and traceA >= traceC then
                    ch = "/"
                elseif traceB >= traceC then
                    ch = "\\"
                else
                    ch = "."
                end
            else
                ch = " "
            end

            ctx.setSample(x, ch, fg, bg)
        end

        ctx.blitRow(y)
    end
end

return M
