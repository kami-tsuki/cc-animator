local sin, cos, abs = math.sin, math.cos, math.abs
local max = math.max

local M = {}

function M.render(ctx, t, config)
    local getAdaptiveNorm = ctx.getAdaptiveNorm
    local setSample = ctx.setSample
    local shade = ctx.shade
    local blitRow = ctx.blitRow
    local width = ctx.width
    local height = ctx.height
    local step = ctx.renderStep

    local chaos = (ctx.derivedTuning and ctx.derivedTuning.chaos) or 1
    local warp = (ctx.derivedTuning and ctx.derivedTuning.warp) or 1
    local t1 = t * (config.speed or 1.6)
    local twist = (config.twist or 1.0) * (0.9 + chaos * 0.08)
    local bridgeDensity = config.bridgeDensity or 1.0
    local coreGlow = config.coreGlow or 1.0

    for y = 1, height do
        local ny = ctx.yNorm[y] or 0
        local helixPhase = ny * (11.0 * twist * warp) - t1 * 3.4
        local strandOffset = 0.34 + sin(ny * 2.1 + t1 * 0.8) * 0.03
        local leftX = sin(helixPhase) * strandOffset
        local rightX = -leftX
        local pulse = 0.5 + 0.5 * sin(helixPhase * 0.5 - t1 * 2.2)

        for x = 1, width, step do
            local nx, localNy = getAdaptiveNorm(x, y)

            local distLeft = abs(nx - leftX)
            local distRight = abs(nx - rightX)
            local leftStrand = 1.08 / (1 + distLeft * (26.0 + chaos * 4.0))
            local rightStrand = 1.08 / (1 + distRight * (26.0 + chaos * 4.0))

            local bridgeMask = max(0, 1 - abs(sin(helixPhase * (2.8 * bridgeDensity) + nx * 9.0)))
            local bridgeWidth = max(0, 1 - abs(nx) * (3.4 + pulse * 1.2))
            local bridges = bridgeMask * bridgeWidth * (0.38 + pulse * 0.30)

            local nucleus = max(0, 1 - (nx * nx * 3.4 + localNy * localNy * 0.65)) * (0.16 + pulse * 0.18) * coreGlow
            local bioNoise = sin((nx * 18.0 - localNy * 9.0) * warp + t1 * 4.2) * 0.06
                + cos((nx * 9.0 + localNy * 14.0) * warp - t1 * 3.0) * 0.05
            local membrane = max(0, 1 - abs(abs(nx) - strandOffset * 0.72) * 5.2) * 0.12

            local energy = 0.08 + leftStrand * 0.34 + rightStrand * 0.34 + bridges + nucleus + bioNoise + membrane
            local sparkle = sin(t1 * 9.0 + nx * 26.0 - localNy * 11.0)
                + cos(t1 * 7.2 - nx * 19.0 + localNy * 17.0)
                + pulse * 0.5

            local ch, fg, bg = shade(energy, sparkle)

            if bridges > 0.32 then
                ch = (pulse > 0.5) and "=" or "-"
            elseif leftStrand > 0.42 or rightStrand > 0.42 then
                ch = (sin(helixPhase + nx * 6.0) > 0) and "/" or "\\"
            elseif nucleus > 0.18 then
                ch = "."
            else
                ch = " "
            end

            setSample(x, ch, fg, bg)
        end

        blitRow(y)
    end
end

return M
