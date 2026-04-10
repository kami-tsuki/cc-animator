---@diagnostic disable: undefined-global
local util = require("animator.util")

local M = {}

local floor, min, max = math.floor, math.min, math.max

local SHADE_COLORS = {
    colors.black,
    colors.gray,
    colors.purple,
    colors.blue,
    colors.lightBlue,
    colors.cyan,
    colors.green,
    colors.pink,
    colors.white,
}

local SHADE_HEX = {}
for i = 1, #SHADE_COLORS do
    SHADE_HEX[i] = colors.toBlit(SHADE_COLORS[i])
end

M.MATRIX_GLYPHS = { "0", "1", "2", "A", "E", "F", "K", "M", "N", "R", "X", "#", "%", "$", "+" }

local function centerWriteOnMonitor(tile, y, text, fg, bg)
    if y < 1 or y > tile.height then
        return
    end

    text = util.fitTextWidth(text, tile.width)
    local x = max(1, floor((tile.width - util.textWidth(text)) / 2) + 1)
    tile.device.setCursorPos(x, y)
    tile.device.setBackgroundColor(bg)
    tile.device.setTextColor(fg)
    tile.device.write(text)
end

local function getRenderStepForAnimation(animationId, renderCellCount)
    local cells = renderCellCount or 0
    if cells <= 6000 then
        return 1
    end

    local heavy = animationId == "matrix" or animationId == "lightning" or animationId == "arcstorm" or animationId == "tube"
    if heavy then
        if cells > 26000 then
            return 3
        end
        return cells > 14000 and 2 or 1
    end

    if cells > 30000 then
        return 3
    end

    return cells > 18000 and 2 or 1
end

local function getQualityScale(state, animationId)
    local performance = state.performance or {}
    local minScale = util.clamp(performance.minScale or 1, 1, 6)
    local maxScale = util.clamp(performance.maxScale or 4, minScale, 6)
    local scale = util.clamp(performance.renderScale or 1, minScale, maxScale)

    if performance.mode ~= "adaptive" then
        return scale
    end

    local cells = state.renderCellCount or 0
    local heavy = animationId == "matrix" or animationId == "lightning" or animationId == "arcstorm" or animationId == "tube"

    if cells > 36000 then
        scale = max(scale, heavy and 4 or 3)
    elseif cells > 22000 then
        scale = max(scale, heavy and 3 or 2)
    elseif cells > 12000 and heavy then
        scale = max(scale, 2)
    end

    return util.clamp(scale, minScale, maxScale)
end

local function refreshSamplingState(state)
    local scale = getQualityScale(state, state.selectedAnimation)
    local sampleWidth = max(1, floor((state.width + scale - 1) / scale))
    local sampleHeight = max(1, floor((state.height + scale - 1) / scale))

    state.sampleScale = scale
    state.sampleWidth = sampleWidth
    state.sampleHeight = sampleHeight
    state.sampleStep = getRenderStepForAnimation(state.selectedAnimation, state.renderCellCount)
    state.sampleXMap, state.sampleYMap = {}, {}
    state.sampleXStart, state.sampleXEnd = {}, {}
    state.sampleYStart, state.sampleYEnd = {}, {}
    state.sampleYNorm = {}

    for sampleX = 1, sampleWidth do
        local startX = ((sampleX - 1) * scale) + 1
        local endX = min(state.width, sampleX * scale)
        state.sampleXStart[sampleX] = startX
        state.sampleXEnd[sampleX] = endX
        state.sampleXMap[sampleX] = min(state.width, startX + floor((endX - startX) * 0.5))
    end

    for sampleY = 1, sampleHeight do
        local startY = ((sampleY - 1) * scale) + 1
        local endY = min(state.height, sampleY * scale)
        local worldY = min(state.height, startY + floor((endY - startY) * 0.5))

        state.sampleYStart[sampleY] = startY
        state.sampleYEnd[sampleY] = endY
        state.sampleYMap[sampleY] = worldY
        state.sampleYNorm[sampleY] = state.yNorm[worldY] or 0
    end
end

M.refreshSamplingState = refreshSamplingState

local function shadeCell(state, energy, sparkle)
    local tune = state.derivedTuning or {}
    local paletteSize = #SHADE_HEX

    energy = util.clamp01(energy * (tune.energy or 1) + (tune.bias or 0))
    sparkle = (sparkle or 0) * (tune.sparkle or 1)

    local idx = floor(energy * (paletteSize - 1) + 1.5)
    idx = util.clamp(idx, 1, paletteSize)

    local ch = " "
    local fgIndex = idx
    local bgIndex = idx

    if energy > 0.92 and sparkle > 1.10 then
        ch = "*"
        fgIndex = min(paletteSize, idx + 1)
        bgIndex = max(1, idx - 2)
    elseif energy > 0.76 and sparkle > 0.74 then
        ch = "."
        fgIndex = min(paletteSize, idx + 1)
        bgIndex = max(1, idx - 1)
    end

    return ch, SHADE_HEX[fgIndex], SHADE_HEX[bgIndex]
end

function M.applyTheme(state, theme)
    if not theme or type(theme.palette) ~= "table" then
        return
    end

    local brightness = (state.runtimeSettings and state.runtimeSettings.brightnessPercent or 100) / 100
    brightness = util.clamp(brightness, 0.35, 1.5)

    local function apply(target)
        if not target or type(target.setPaletteColor) ~= "function" then
            return
        end

        for color, rgb in pairs(theme.palette) do
            pcall(target.setPaletteColor, color,
                util.clamp01((rgb[1] or 0) * brightness),
                util.clamp01((rgb[2] or 0) * brightness),
                util.clamp01((rgb[3] or 0) * brightness))
        end
    end

    apply(term)
    for _, tile in ipairs(state.monitorTiles or {}) do
        apply(tile.device)
    end
end

function M.clearDisplayWall(state)
    for _, tile in ipairs(state.monitorTiles or {}) do
        tile.device.setBackgroundColor(colors.black)
        tile.device.clear()
    end
end

function M.drawPreviewWall(state)
    M.clearDisplayWall(state)

    for index, tile in ipairs(state.monitorTiles or {}) do
        local isSelected = index == state.selectedMonitorIndex
        local bg = isSelected and colors.gray or colors.black
        local fg = isSelected and colors.white or colors.cyan
        local label = tile.label or string.char(64 + ((index - 1) % 26) + 1)

        tile.device.setBackgroundColor(bg)
        tile.device.clear()
        centerWriteOnMonitor(tile, max(1, floor(tile.height / 2) - 1), "[" .. label .. "]", colors.pink, bg)

        if tile.height >= 3 then
            centerWriteOnMonitor(tile, floor(tile.height / 2), tile.name, fg, bg)
        end

        if tile.height >= 4 then
            centerWriteOnMonitor(tile, min(tile.height, floor(tile.height / 2) + 1), string.format("%d,%d", tile.x, tile.y), colors.lightBlue, bg)
        end
    end
end

function M.rebuildLayout(state)
    if #(state.monitorTiles or {}) == 0 then
        state.width = 0
        state.height = 0
        state.fps = 12
        state.frameTime = 1 / state.fps
        state.previewDirty = true
        return
    end

    state.width = 0
    state.height = 0
    local autoX = 1
    local minX, minY = math.huge, math.huge
    state.rowMinX, state.rowMaxX = {}, {}
    state.colMinY, state.colMaxY = {}, {}

    for _, tile in ipairs(state.monitorTiles) do
        pcall(function()
            tile.device.setTextScale(state.config.preferredScale)
        end)

        tile.width, tile.height = tile.device.getSize()

        local saved = state.settingsLayout[tile.name]
        if type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number" then
            tile.x = max(1, floor(saved.x))
            tile.y = max(1, floor(saved.y))
        else
            tile.x = autoX
            tile.y = 1
            state.settingsLayout[tile.name] = { x = tile.x, y = tile.y }
            autoX = autoX + tile.width
        end

        minX = math.min(minX, tile.x)
        minY = math.min(minY, tile.y)
    end

    local shiftX = (minX == math.huge) and 0 or (minX - 1)
    local shiftY = (minY == math.huge) and 0 or (minY - 1)

    for _, tile in ipairs(state.monitorTiles) do
        tile.x = max(1, tile.x - shiftX)
        tile.y = max(1, tile.y - shiftY)
        state.settingsLayout[tile.name] = { x = tile.x, y = tile.y }

        local tileMaxX = tile.x + tile.width - 1
        local tileMaxY = tile.y + tile.height - 1

        state.width = max(state.width, tileMaxX)
        state.height = max(state.height, tileMaxY)

        for row = tile.y, tileMaxY do
            state.rowMinX[row] = state.rowMinX[row] and math.min(state.rowMinX[row], tile.x) or tile.x
            state.rowMaxX[row] = state.rowMaxX[row] and math.max(state.rowMaxX[row], tileMaxX) or tileMaxX
        end

        for column = tile.x, tileMaxX do
            state.colMinY[column] = state.colMinY[column] and math.min(state.colMinY[column], tile.y) or tile.y
            state.colMaxY[column] = state.colMaxY[column] and math.max(state.colMaxY[column], tileMaxY) or tileMaxY
        end
    end

    local cx = (state.width + 1) * 0.5
    local cy = (state.height + 1) * 0.5
    local span = max(1, max(state.width, state.height) * 0.5)

    state.xNorm, state.yNorm = {}, {}
    for x = 1, state.width do
        state.xNorm[x] = (x - cx) / span
    end
    for y = 1, state.height do
        state.yNorm[y] = (y - cy) / span
    end

    state.adaptiveXGrid, state.adaptiveYGrid = {}, {}
    for y = 1, state.height do
        local rowX, rowY = {}, {}
        local minRow = state.rowMinX[y] or 1
        local maxRow = state.rowMaxX[y] or state.width
        local rowMid = (minRow + maxRow) * 0.5
        local rowScale = max(1, (maxRow - minRow + 1) * 0.5)

        for x = 1, state.width do
            local minCol = state.colMinY[x] or 1
            local maxCol = state.colMaxY[x] or state.height
            local colMid = (minCol + maxCol) * 0.5
            local colScale = max(1, (maxCol - minCol + 1) * 0.5)
            local localNx = (x - rowMid) / rowScale
            local localNy = (y - colMid) / colScale

            rowX[x] = (state.xNorm[x] or 0) * 0.30 + localNx * 0.70
            rowY[x] = (state.yNorm[y] or 0) * 0.30 + localNy * 0.70
        end

        state.adaptiveXGrid[y] = rowX
        state.adaptiveYGrid[y] = rowY
    end

    state.renderCellCount = state.width * state.height
    local autoFps = max(state.config.minFps, min(state.config.maxFps, floor(19 - state.renderCellCount / 450)))
    if (state.runtimeSettings.fpsOverride or 0) > 0 then
        state.fps = util.clamp(state.runtimeSettings.fpsOverride, state.config.minFps, 24)
    else
        state.fps = min(autoFps, 24)
    end

    state.frameTime = 1 / max(1, min(state.fps, 24))
    refreshSamplingState(state)
    state.previewDirty = true
    M.clearDisplayWall(state)
end

function M.autoArrangeRow(state)
    local cursorX = 1
    for _, tile in ipairs(state.monitorTiles or {}) do
        state.settingsLayout[tile.name] = { x = cursorX, y = 1 }
        cursorX = cursorX + tile.width
    end
    M.rebuildLayout(state)
end

function M.autoArrangeColumn(state)
    local cursorY = 1
    for index = #(state.monitorTiles or {}), 1, -1 do
        local tile = state.monitorTiles[index]
        state.settingsLayout[tile.name] = { x = 1, y = cursorY }
        cursorY = cursorY + tile.height
    end
    M.rebuildLayout(state)
end

function M.autoArrangeSmart(state)
    if #(state.monitorTiles or {}) == 0 then
        return
    end

    local count = #state.monitorTiles
    local maxTileWidth, maxTileHeight = 1, 1
    for _, tile in ipairs(state.monitorTiles) do
        tile.width, tile.height = tile.device.getSize()
        maxTileWidth = max(maxTileWidth, tile.width)
        maxTileHeight = max(maxTileHeight, tile.height)
    end

    local columns = max(1, math.ceil(math.sqrt(count)))
    if count <= 2 then
        columns = count
    elseif count == 3 then
        columns = 2
    end

    for index, tile in ipairs(state.monitorTiles) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        state.settingsLayout[tile.name] = {
            x = 1 + column * maxTileWidth,
            y = 1 + row * maxTileHeight,
        }
    end

    M.rebuildLayout(state)
end

function M.invertLayout(state)
    if #(state.monitorTiles or {}) <= 1 then
        return
    end

    local positions = {}
    for index, tile in ipairs(state.monitorTiles) do
        positions[index] = { x = tile.x, y = tile.y }
    end

    for index, tile in ipairs(state.monitorTiles) do
        local mirrored = positions[#positions - index + 1]
        state.settingsLayout[tile.name] = { x = mirrored.x, y = mirrored.y }
    end

    M.rebuildLayout(state)
end

function M.moveSelectedMonitor(state, dx, dy)
    local tile = state.monitorTiles and state.monitorTiles[state.selectedMonitorIndex]
    if not tile then
        return false
    end

    local newX = max(1, tile.x + (dx * tile.width))
    local newY = max(1, tile.y + (dy * tile.height))
    state.settingsLayout[tile.name] = { x = newX, y = newY }
    M.rebuildLayout(state)
    return true
end

function M.bindMonitors(state)
    local names = {}
    local missingLayout = false

    if #(state.requestedMonitors or {}) > 0 then
        for _, name in ipairs(state.requestedMonitors) do
            names[#names + 1] = name
        end
    else
        for _, name in ipairs(peripheral.getNames()) do
            names[#names + 1] = name
        end
        table.sort(names)
    end

    state.monitorTiles = {}
    for _, name in ipairs(names) do
        if peripheral.getType(name) == "monitor" then
            local wrapped = peripheral.wrap(name)
            if wrapped and wrapped.isColor and wrapped.isColor() then
                if type(state.settingsLayout[name]) ~= "table" then
                    missingLayout = true
                end

                state.monitorTiles[#state.monitorTiles + 1] = {
                    name = name,
                    device = wrapped,
                    x = 1,
                    y = 1,
                    width = 1,
                    height = 1,
                }
            end
        end
    end

    if #state.monitorTiles == 0 then
        state.monitorName = nil
        state.width = 0
        state.height = 0
        state.previewDirty = true
        return false
    end

    table.sort(state.monitorTiles, function(left, right)
        return left.name < right.name
    end)

    for index, tile in ipairs(state.monitorTiles) do
        tile.label = string.char(64 + ((index - 1) % 26) + 1)
    end

    state.selectedMonitorIndex = util.clamp(state.selectedMonitorIndex or 1, 1, #state.monitorTiles)
    state.monitorName = (#state.monitorTiles == 1) and state.monitorTiles[1].name or (tostring(#state.monitorTiles) .. " monitors")

    M.rebuildLayout(state)

    if missingLayout and #state.monitorTiles >= 4 then
        M.autoArrangeSmart(state)
    end

    return true
end

local function setRenderSample(state, sampleX, renderStep, ch, fg, bg)
    local sampleLimit = state.sampleWidth or state.width
    local sampleEnd = min(sampleLimit, sampleX + renderStep - 1)
    local realStart = (state.sampleXStart and state.sampleXStart[sampleX]) or sampleX
    local realEnd = (state.sampleXEnd and state.sampleXEnd[sampleEnd]) or sampleEnd

    for realX = realStart, realEnd do
        state.rowChars[realX] = ch
        state.rowFg[realX] = fg
        state.rowBg[realX] = bg
    end
end

local function blitPreparedRow(state, sampleY)
    if state.width <= 0 then
        return
    end

    local chars = table.concat(state.rowChars, "", 1, state.width)
    local fg = table.concat(state.rowFg, "", 1, state.width)
    local bg = table.concat(state.rowBg, "", 1, state.width)
    local worldStartY = (state.sampleYStart and state.sampleYStart[sampleY]) or sampleY
    local worldEndY = (state.sampleYEnd and state.sampleYEnd[sampleY]) or worldStartY

    for _, tile in ipairs(state.monitorTiles) do
        local localStartY = max(1, worldStartY - tile.y + 1)
        local localEndY = min(tile.height, worldEndY - tile.y + 1)
        if localStartY <= localEndY then
            local startX = tile.x
            local endX = tile.x + tile.width - 1
            local tileChars = chars:sub(startX, endX)
            local tileFg = fg:sub(startX, endX)
            local tileBg = bg:sub(startX, endX)

            for localY = localStartY, localEndY do
                tile.device.setCursorPos(1, localY)
                tile.device.blit(tileChars, tileFg, tileBg)
            end
        end
    end
end

function M.makeContext(state)
    local ctx = state.renderContext
    if not ctx then
        ctx = {}
        state.renderContext = ctx

        ctx.getAdaptiveNorm = function(sampleX, sampleY)
            local renderStep = ctx.renderStep or 1
            local sampleMidX = sampleX
            if renderStep > 1 then
                sampleMidX = min(ctx.width, sampleX + floor((renderStep - 1) * 0.5))
            end

            local worldX = (state.sampleXMap and state.sampleXMap[sampleMidX]) or sampleMidX
            local worldY = (state.sampleYMap and state.sampleYMap[sampleY]) or sampleY
            local rowX = state.adaptiveXGrid[worldY]
            local rowY = state.adaptiveYGrid[worldY]

            if rowX and rowY then
                return rowX[worldX] or 0, rowY[worldX] or 0
            end

            return state.xNorm[worldX] or 0, state.yNorm[worldY] or 0
        end

        ctx.shade = function(energy, sparkle)
            return shadeCell(state, energy, sparkle)
        end

        ctx.setSample = function(sampleX, ch, fg, bg)
            return setRenderSample(state, sampleX, ctx.renderStep or 1, ch, fg, bg)
        end

        ctx.blitRow = function(sampleY)
            return blitPreparedRow(state, sampleY)
        end
    end

    ctx.width = state.sampleWidth or state.width
    ctx.height = state.sampleHeight or state.height
    ctx.outputWidth = state.width
    ctx.outputHeight = state.height
    ctx.renderStep = state.sampleStep or getRenderStepForAnimation(state.selectedAnimation, state.renderCellCount)
    ctx.sampleScale = state.sampleScale or 1
    ctx.derivedTuning = state.derivedTuning
    ctx.yNorm = state.sampleYNorm or state.yNorm
    ctx.matrixGlyphs = M.MATRIX_GLYPHS
    return ctx
end

function M.updatePerformance(state, renderCost)
    local performance = state.performance or {}
    state.performance = performance

    performance.lastRenderCost = renderCost or 0
    if performance.lastRenderCost > 0 then
        performance.avgRenderCost = (performance.avgRenderCost and performance.avgRenderCost > 0)
            and (performance.avgRenderCost * 0.82 + performance.lastRenderCost * 0.18)
            or performance.lastRenderCost
        performance.lastFps = 1 / performance.lastRenderCost
    end

    if performance.mode ~= "adaptive" then
        return false
    end

    local now = os.clock()
    if performance.lastScaleChangeAt and (now - performance.lastScaleChangeAt) < 0.75 then
        return false
    end

    local minScale = util.clamp(performance.minScale or 1, 1, 6)
    local maxScale = util.clamp(performance.maxScale or 4, minScale, 6)
    local currentScale = util.clamp(performance.renderScale or 1, minScale, maxScale)
    local targetBudget = max(0.001, (state.frameTime or (1 / 12)) * (performance.targetBudgetRatio or 0.85))
    local nextScale = currentScale

    if (performance.avgRenderCost or 0) > targetBudget * 1.10 and currentScale < maxScale then
        nextScale = currentScale + 1
    elseif (performance.avgRenderCost or 0) < targetBudget * 0.55 and currentScale > minScale then
        nextScale = currentScale - 1
    end

    if nextScale ~= currentScale then
        performance.renderScale = nextScale
        performance.lastScaleChangeAt = now
        refreshSamplingState(state)
        state.previewDirty = true
        return true
    end

    return false
end

function M.renderFrame(state, animation, time)
    if #(state.monitorTiles or {}) == 0 then
        return
    end

    if state.showLayoutPreview then
        if state.previewDirty then
            M.drawPreviewWall(state)
            state.previewDirty = false
        end
        return
    end

    local ctx = M.makeContext(state)
    local adjustedTime = time * (state.derivedTuning.speedA or 1) + (state.derivedTuning.phase or 0)
    animation.render(ctx, adjustedTime, animation.settings or {})
end

return M
