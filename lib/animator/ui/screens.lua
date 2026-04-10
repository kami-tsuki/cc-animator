---@diagnostic disable: undefined-global
local ui = require("animator.ui")

local M = {}

local PAGE_TABS = {
    { id = "home", label = "Home", width = 8, active = colors.pink },
    { id = "animations", label = "Animate", width = 10, active = colors.pink },
    { id = "themes", label = "Themes", width = 8, active = colors.cyan },
    { id = "layout", label = "Layout", width = 8, active = colors.blue },
    { id = "settings", label = "Settings", width = 11, active = colors.green },
}

local function getPageLabel(id)
    for _, tab in ipairs(PAGE_TABS) do
        if tab.id == id then
            return tab.label
        end
    end
    return tostring(id or "Page")
end

local function drawListPage(state, options)
    local visibleCount = ui.visibleListCount()
    local maxScroll = math.max(0, #options.items - visibleCount)
    state.listScroll[options.scrollKey] = math.max(0, math.min(state.listScroll[options.scrollKey] or 0, maxScroll))

    local startIndex = state.listScroll[options.scrollKey] + 1
    local endIndex = math.min(#options.items, startIndex + visibleCount - 1)

    ui.addButton(state, 43, 5, 4, "^", colors.gray, colors.white, { type = "scroll", page = options.page, delta = -1 })
    ui.addButton(state, 43, 5 + visibleCount - 1, 4, "v", colors.gray, colors.white, { type = "scroll", page = options.page, delta = 1 })

    local row = 0
    for index = startIndex, endIndex do
        local id = options.items[index]
        local active = id == options.selectedId
        local label = options.getLabel(index, id)
        ui.addButton(
            state,
            2,
            5 + row,
            39,
            label,
            active and options.activeBg or colors.gray,
            active and options.activeFg or colors.white,
            { type = options.actionType, id = id }
        )
        row = row + 1
    end

    ui.panelWrite(15, string.format("Showing %d-%d of %d", startIndex, endIndex, #options.items), colors.lightGray)
    ui.panelWrite(16, options.currentText, options.currentColor or colors.cyan)
end

local function drawAdjustRow(state, y, label, key, step)
    ui.panelWrite(y, string.format("%-6s %3d%%", label, state.runtimeSettings[key]), colors.white)
    ui.addButton(state, 15, y, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = key, delta = -step })
    ui.addButton(state, 19, y, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = key, delta = step })
end

local function drawPageTabs(state)
    local x = 1
    for _, tab in ipairs(PAGE_TABS) do
        local active = state.currentPage == tab.id
        ui.addButton(state, x, 1, tab.width, tab.label, active and tab.active or colors.gray, active and colors.black or colors.white, {
            type = "page",
            id = tab.id
        })
        x = x + tab.width + 1
    end
end

local function drawHomePage(state, current, theme)
    local perf = state.performance or {}
    local renderMs = string.format("%.1fms", ((perf.avgRenderCost or perf.lastRenderCost or 0) * 1000))
    local gpuText = string.format("%s x%d", perf.mode == "adaptive" and "Adaptive" or "Manual", state.sampleScale or perf.renderScale or 1)

    ui.panelCenter(3, state.config.title, colors.pink)
    ui.panelCenter(4, "v" .. tostring(state.config.version) .. "  •  " .. tostring(state.config.subtitle), colors.lightBlue)
    ui.writeKeyValue(6, "Animation", current.label, colors.white)
    ui.writeKeyValue(7, "Theme", theme.label, colors.white)
    ui.writeKeyValue(8, "Display", (#state.monitorTiles > 0) and string.format("%d monitor(s)  %dx%d  @%dfps", #state.monitorTiles, state.width, state.height, state.fps) or "Waiting for advanced monitors", (#state.monitorTiles > 0) and colors.green or colors.pink)
    ui.writeKeyValue(9, "Preview", state.showLayoutPreview and "Enabled" or "Live render", state.showLayoutPreview and colors.cyan or colors.lightGray)
    ui.writeKeyValue(10, "Renderer", gpuText .. "  " .. renderMs, colors.cyan)
    ui.panelWrite(12, "Pipeline: batched blits + dynamic upscale shading.", colors.lightGray)
    ui.panelWrite(13, "Large walls now auto-trade pixels for FPS when needed.", colors.gray)
end

local function drawAnimationsPage(state, animations, current)
    ui.panelCenter(3, "Animations", colors.white)
    drawListPage(state, {
        page = "animations",
        scrollKey = "animations",
        items = animations.order,
        selectedId = state.selectedAnimation,
        actionType = "animation",
        activeBg = colors.pink,
        activeFg = colors.black,
        getLabel = function(index, id)
            return string.format("%02d  %s", index, animations.all[id].label)
        end,
        currentText = "Current: " .. current.label,
        currentColor = colors.cyan,
    })
end

local function drawThemesPage(state, themes, current)
    ui.panelCenter(3, "Themes", colors.white)
    drawListPage(state, {
        page = "themes",
        scrollKey = "themes",
        items = themes.order,
        selectedId = state.selectedTheme,
        actionType = "theme",
        activeBg = colors.cyan,
        activeFg = colors.black,
        getLabel = function(_, id)
            return themes.all[id].label
        end,
        currentText = "Current: " .. current.label,
        currentColor = colors.cyan,
    })
end

local function drawSettingsPage(state)
    ui.panelCenter(3, "Settings", colors.white)

    ui.writeKeyValue(5, "Seed", state.runtimeSettings.rngSeed, colors.white)
    ui.addButton(state, 15, 5, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = -1 })
    ui.addButton(state, 19, 5, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = 1 })
    ui.addButton(state, 23, 5, 7, "Random", colors.purple, colors.white, { type = "seed_random" })

    ui.writeKeyValue(6, "FPS", state.runtimeSettings.fpsOverride == 0 and "Auto" or tostring(state.runtimeSettings.fpsOverride), colors.white)
    ui.addButton(state, 15, 6, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = -1 })
    ui.addButton(state, 19, 6, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = 1 })
    ui.addButton(state, 23, 6, 7, "Auto", colors.blue, colors.white, { type = "fps_auto" })

    ui.writeKeyValue(7, "GPU", (state.runtimeSettings.gpuAdaptive and "Adaptive" or "Manual") .. " x" .. tostring(state.sampleScale or state.runtimeSettings.gpuScale or 1), colors.cyan)
    ui.addButton(state, 15, 7, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "gpuScale", delta = -1 })
    ui.addButton(state, 19, 7, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "gpuScale", delta = 1 })
    ui.addButton(state, 23, 7, 8, state.runtimeSettings.gpuAdaptive and "Auto" or "Manual", state.runtimeSettings.gpuAdaptive and colors.cyan or colors.gray, state.runtimeSettings.gpuAdaptive and colors.black or colors.white, { type = "gpu_toggle" })

    drawAdjustRow(state, 8, "Speed", "speedPercent", 5)
    drawAdjustRow(state, 9, "Power", "intensityPercent", 5)
    drawAdjustRow(state, 10, "Spark", "sparklePercent", 5)
    drawAdjustRow(state, 11, "Varia", "variationPercent", 5)
    drawAdjustRow(state, 12, "Light", "brightnessPercent", 5)

    ui.addButton(state, 31, 8, 8, "Cinema", colors.gray, colors.white, { type = "preset", id = "cinematic" })
    ui.addButton(state, 40, 8, 8, "Chaos", colors.gray, colors.white, { type = "preset", id = "chaotic" })
    ui.addButton(state, 31, 10, 8, "Calm", colors.gray, colors.white, { type = "preset", id = "calm" })
    ui.addButton(state, 40, 10, 8, "Storm", colors.gray, colors.white, { type = "preset", id = "storm" })
    ui.addButton(state, 35, 12, 8, "Club", colors.gray, colors.white, { type = "preset", id = "club" })

    local perf = state.performance or {}
    ui.panelWrite(14, string.format("Avg render %.1fms • target %.1fms", (perf.avgRenderCost or 0) * 1000, (state.frameTime or 0) * (perf.targetBudgetRatio or 0.85) * 1000), colors.lightGray)
end

local function drawLayoutPage(state)
    local attached = #state.monitorTiles > 0
    local selectedTile = state.monitorTiles[state.selectedMonitorIndex]

    ui.panelCenter(3, "Layout", colors.white)
    ui.panelWrite(4, attached and "Arrange and preview the monitor wall." or "Connect advanced monitors to build the wall.", attached and colors.lightBlue or colors.pink)

    ui.drawMiniMap(state, 2, 6, 22, 8)

    ui.addButton(state, 26, 6, 10, "Prev", colors.blue, colors.white, { type = "cycle" })
    ui.addButton(state, 37, 6, 10, state.showLayoutPreview and "Hide" or "Show", state.showLayoutPreview and colors.pink or colors.gray, state.showLayoutPreview and colors.black or colors.white, { type = "preview" })
    ui.addButton(state, 26, 8, 10, "Auto row", colors.purple, colors.white, { type = "auto_row" })
    ui.addButton(state, 37, 8, 10, "Auto col", colors.purple, colors.white, { type = "auto_column" })
    ui.addButton(state, 26, 9, 10, "Reset", colors.orange, colors.white, { type = "reset" })
    ui.addButton(state, 37, 9, 10, "Invert", colors.lightBlue, colors.black, { type = "invert" })
    ui.addButton(state, 26, 10, 10, "Rescan", colors.cyan, colors.black, { type = "rescan" })
    ui.addButton(state, 31, 12, 5, "^", colors.gray, colors.white, { type = "move", dx = 0, dy = -1 })
    ui.addButton(state, 26, 13, 5, "<", colors.gray, colors.white, { type = "move", dx = -1, dy = 0 })
    ui.addButton(state, 31, 13, 5, "v", colors.gray, colors.white, { type = "move", dx = 0, dy = 1 })
    ui.addButton(state, 36, 13, 5, ">", colors.gray, colors.white, { type = "move", dx = 1, dy = 0 })
    ui.addButton(state, 38, 18, 8, "Quit", colors.red, colors.white, { type = "quit" })

    if selectedTile then
        ui.writeKeyValue(15, "Selected", string.format("%s (%s)", selectedTile.name, selectedTile.label or "?"), colors.white)
        ui.writeKeyValue(16, "Position", string.format("(%d,%d)  %dx%d", selectedTile.x, selectedTile.y, selectedTile.width, selectedTile.height), colors.lightGray)
    else
        ui.writeKeyValue(15, "Selected", "None", colors.gray)
        ui.writeKeyValue(16, "Position", "No monitor wall detected", colors.lightGray)
    end

    ui.writeKeyValue(17, "Canvas", attached and string.format("%dx%d across %d monitor(s)", state.width, state.height, #state.monitorTiles) or "--", attached and colors.green or colors.gray)
    ui.writeKeyValue(18, "Preview", state.showLayoutPreview and "Enabled" or "Disabled", state.showLayoutPreview and colors.cyan or colors.lightGray)
end

function M.getPageLabel(id)
    return getPageLabel(id)
end

function M.drawControlPanel(state, animations, themes, message)
    if message ~= nil then
        state.statusMessage = tostring(message)
    end

    ui.clear(state)

    local currentAnimation = animations.get(state.selectedAnimation)
    local currentTheme = themes.get(state.selectedTheme)

    drawPageTabs(state)

    if state.currentPage == "home" then
        drawHomePage(state, currentAnimation, currentTheme)
    elseif state.currentPage == "animations" then
        drawAnimationsPage(state, animations, currentAnimation)
    elseif state.currentPage == "themes" then
        drawThemesPage(state, themes, currentTheme)
    elseif state.currentPage == "settings" then
        drawSettingsPage(state)
    elseif state.currentPage == "layout" then
        drawLayoutPage(state)
    end

    ui.drawStatusBar(state)
end

return M
