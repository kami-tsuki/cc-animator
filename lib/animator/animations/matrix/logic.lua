local sin, cos, abs = math.sin, math.cos, math.abs
local floor, max = math.floor, math.max

local M = {}

function M.render(ctx, t, config)
    local getAdaptiveNorm = ctx.getAdaptiveNorm
    local setSample = ctx.setSample
    local shade = ctx.shade
    local blitRow = ctx.blitRow
    local glyphs = ctx.matrixGlyphs
    local width = ctx.width
    local height = ctx.height
    local step = ctx.renderStep
    local chaos = ctx.derivedTuning.chaos or 1
    local t1 = t * (config.speed or (2.2 + chaos * 0.18))

    for y = 1, height do
        for x = 1, width, step do
            local nx, ny = getAdaptiveNorm(x, y)
            local lane = abs(sin(nx * 19.0 + sin(t1 * 0.7 + nx * 4.0) * 1.6))
            local column = lane ^ 8
            local fallSpeed = 8.0 + column * 18.0 + chaos * 2.5
            local head = (t1 * fallSpeed + x * 3.7 + sin(x * 0.45 + t1) * 3.0) % (height + 18)
            local dist = head - y
            local tailLen = 6 + floor(column * 12 + 0.5)

            local stream = 0
            if dist >= 0 and dist <= tailLen then
                stream = (1 - dist / max(1, tailLen)) ^ 1.25
            end

            local shimmer = sin((nx - ny * 0.35) * 14.0 - t1 * 4.2) * 0.04
            local energy = 0.02 + column * 0.10 + stream * (0.82 + column * 0.28) + shimmer
            local sparkle = sin(t1 * 8.5 + nx * 28.0) + cos(t1 * 5.8 - ny * 22.0)
            local ch, fg, bg = shade(energy, sparkle + stream)

            if stream > 0.02 then
                local glyphIndex = (floor(t1 * 20 + x * 11 + y * 7) % #glyphs) + 1
                ch = glyphs[glyphIndex]
                if dist < 1 then
                    ch = glyphs[(glyphIndex % #glyphs) + 1]
                end
            else
                ch = " "
            end

            setSample(x, ch, fg, bg)
        end

        blitRow(y)
    end
end

return M
