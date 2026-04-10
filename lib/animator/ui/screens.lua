---@diagnostic disable: undefined-global
local ui = require("animator.ui")
local util = require("animator.util")

local M = {}

local PAGE_TABS = {
    { id = "home", label = "Home", width = 8, active = colors.pink },
    { id = "animations", label = "Animate", width = 10, active = colors.purple },
    { id = "themes", label = "Themes", width = 8, active = colors.cyan },
    { id = "layout", label = "Layout", width = 8, active = colors.blue },
    { id = "settings", label = "Settings", width = 10, active = colors.green },
    { id = "about", label = "About", width = 8, active = colors.orange },
}

local function getPageLabel(id)
    for _, tab in ipairs(PAGE_TABS) do
        if tab.id == id then
            return tab.label
        end
    end
    return tostring(id or "Page")
end

local function meta(state)
    return state.meta or {}
end

local function joinList(values, fallback)
    if type(values) ~= "table" or #values == 0 then
        return fallback or "—"
    end
    return table.concat(values, ", ")
end

local function shortPath(path)
    path = tostring(path or "")
    if path == "" then
        return "local"
    end
    return util.truncate(path, 24)
end

local function drawBoxKeyValue(x, y, width, label, value, valueColor)
    local prefix = tostring(label or "") .. ": "
    ui.writeAt(x, y, prefix, colors.lightGray)
    ui.writeAt(x + #prefix, y, util.truncate(tostring(value or "—"), math.max(1, width - #prefix)), valueColor or colors.white)
end

local function drawHeader(state)
    local tw = term.getSize()
    local appMeta = meta(state)
    local authorLine = joinList(appMeta.author, "tsuki_kami_")

    ui.panelWrite(1, string.rep(" ", tw), colors.white, colors.pink)
    ui.panelCenter(1, appMeta.tabletName or state.config.title or "Kami-Animator", colors.black, colors.pink)
    ui.panelWrite(2, string.rep(" ", tw), colors.white, colors.black)
    ui.panelCenter(2, string.format("v%s  •  %s  •  by %s", tostring(appMeta.version or state.config.version or "0.0.0"), tostring(appMeta.subtitle or state.config.subtitle or "Animation Wall"), authorLine), colors.lightBlue, colors.black)
end

local function drawPageTabs(state)
    local tw = term.getSize()
    local x = 2

    for _, tab in ipairs(PAGE_TABS) do
        local active = state.currentPage == tab.id
        ui.addButton(state, x, 4, tab.width, tab.label, active and tab.active or colors.gray, active and colors.black or colors.white, {
            type = "page",
            id = tab.id
        })
        x = x + tab.width + 1
    end

    ui.addButton(state, math.max(x, tw - 7), 4, 6, "Quit", colors.red, colors.white, { type = "quit" })
end

local function drawListPage(state, options)
    local visibleCount = math.max(4, math.min(options.height - 3, ui.visibleListCount()))
    local maxScroll = math.max(0, #options.items - visibleCount)
    state.listScroll[options.scrollKey] = math.max(0, math.min(state.listScroll[options.scrollKey] or 0, maxScroll))

    local startIndex = state.listScroll[options.scrollKey] + 1
    local endIndex = math.min(#options.items, startIndex + visibleCount - 1)
    local rowY = options.y + 1

    ui.drawFrame(options.x, options.y, options.width, options.height, options.border or colors.gray, colors.black, options.title, colors.white)
    ui.addButton(state, options.x + options.width - 4, options.y, 3, "^", colors.gray, colors.white, { type = "scroll", page = options.page, delta = -1 })
    ui.addButton(state, options.x + options.width - 4, options.y + options.height - 1, 3, "v", colors.gray, colors.white, { type = "scroll", page = options.page, delta = 1 })

    local row = 0
    for index = startIndex, endIndex do
        local id = options.items[index]
        local active = id == options.selectedId
        ui.addButton(
            state,
            options.x + 1,
            rowY + row,
            options.width - 2,
            options.getLabel(index, id),
            active and options.activeBg or colors.gray,
            active and options.activeFg or colors.white,
            { type = options.actionType, id = id }
        )
        row = row + 1
    end

    ui.writeAt(options.x + 1, options.y + options.height - 1, string.format("%d-%d / %d", startIndex, endIndex, #options.items), colors.lightGray)
end

local function drawAdjustRow(state, x, y, label, key, step)
    ui.writeAt(x, y, string.format("%-6s %3d%%", label, state.runtimeSettings[key]), colors.white)
    ui.addButton(state, x + 13, y, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = key, delta = -step })
    ui.addButton(state, x + 17, y, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = key, delta = step })
end

local function drawHomePage(state, current, theme)
    local tw, th = term.getSize()
    local perf = state.performance or {}
    local appMeta = meta(state)
    local renderMs = string.format("%.1fms", ((perf.avgRenderCost or perf.lastRenderCost or 0) * 1000))
    local gpuText = string.format("%s x%d", perf.mode == "adaptive" and "Adaptive" or "Manual", state.sampleScale or perf.renderScale or 1)

    local leftX, leftY, leftW, leftH = 2, 6, math.max(24, math.floor((tw - 5) * 0.52)), 8
    local rightX = leftX + leftW + 1
    local rightW = math.max(18, tw - rightX - 1)

    ui.drawFrame(leftX, leftY, leftW, leftH, colors.pink, colors.black, " Live Session ", colors.white)
    drawBoxKeyValue(leftX + 2, leftY + 1, leftW - 4, "Animation", current.label, colors.white)
    drawBoxKeyValue(leftX + 2, leftY + 2, leftW - 4, "Theme", theme.label, colors.cyan)
    drawBoxKeyValue(leftX + 2, leftY + 3, leftW - 4, "Display", (#state.monitorTiles > 0) and string.format("%d monitor(s) • %dx%d @ %dfps", #state.monitorTiles, state.width, state.height, state.fps) or "Waiting for advanced monitors", (#state.monitorTiles > 0) and colors.green or colors.pink)
    drawBoxKeyValue(leftX + 2, leftY + 4, leftW - 4, "Preview", state.showLayoutPreview and "Alignment mode" or "Live rendering", state.showLayoutPreview and colors.lightBlue or colors.lightGray)
    drawBoxKeyValue(leftX + 2, leftY + 5, leftW - 4, "Renderer", gpuText .. " • " .. renderMs, colors.cyan)
    drawBoxKeyValue(leftX + 2, leftY + 6, leftW - 4, "Runtime", shortPath(state.runtimePath), colors.orange)

    ui.drawFrame(rightX, leftY, rightW, leftH, colors.cyan, colors.black, " Identity ", colors.white)
    drawBoxKeyValue(rightX + 2, leftY + 1, rightW - 4, "Tablet", appMeta.tabletName or state.config.title, colors.white)
    drawBoxKeyValue(rightX + 2, leftY + 2, rightW - 4, "Version", appMeta.version or state.config.version, colors.lightBlue)
    drawBoxKeyValue(rightX + 2, leftY + 3, rightW - 4, "Author", joinList(appMeta.author, "tsuki_kami_"), colors.pink)
    drawBoxKeyValue(rightX + 2, leftY + 4, rightW - 4, "License", appMeta.license ~= "" and "Custom Attribution" or "—", colors.green)
    ui.writeWrapped(rightX + 2, leftY + 5, rightW - 4, "Free to use and edit. Inspired works should keep author and credits visible.", colors.lightGray, colors.black, 2)

    local footerY = leftY + leftH + 1
    local footerH = math.max(3, th - footerY)
    ui.drawFrame(2, footerY, tw - 2, footerH, colors.green, colors.black, " Quick Access ", colors.white)
    ui.addButton(state, 4, footerY + 1, 9, "Animate", colors.purple, colors.white, { type = "page", id = "animations" })
    ui.addButton(state, 14, footerY + 1, 8, "Themes", colors.cyan, colors.black, { type = "page", id = "themes" })
    ui.addButton(state, 23, footerY + 1, 8, "Layout", colors.blue, colors.white, { type = "page", id = "layout" })
    ui.addButton(state, 32, footerY + 1, 10, "Settings", colors.green, colors.black, { type = "page", id = "settings" })
    ui.addButton(state, 43, footerY + 1, 7, "About", colors.orange, colors.white, { type = "page", id = "about" })
end

local function drawAnimationsPage(state, animations, current)
    local tw, th = term.getSize()
    local listHeight = math.max(8, th - 8)
    local listWidth = math.max(26, math.floor((tw - 5) * 0.58))
    local rightX = 2 + listWidth + 1
    local rightW = tw - rightX - 1

    drawListPage(state, {
        x = 2,
        y = 6,
        width = listWidth,
        height = listHeight,
        title = " Animation Library ",
        border = colors.purple,
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
    })

    ui.drawFrame(rightX, 6, rightW, listHeight, colors.cyan, colors.black, " Selected Animation ", colors.white)
    drawBoxKeyValue(rightX + 2, 7, rightW - 4, "Name", current.label, colors.white)
    drawBoxKeyValue(rightX + 2, 8, rightW - 4, "Shortcut", "1-0 quick select", colors.lightBlue)
    drawBoxKeyValue(rightX + 2, 9, rightW - 4, "Theme", state.selectedTheme, colors.cyan)
    ui.writeWrapped(rightX + 2, 10, rightW - 4, "Use the quick number keys or tap a card to switch effects instantly. The renderer keeps adaptive sampling tuned for larger monitor walls.", colors.lightGray, colors.black, 5)
end

local function drawThemesPage(state, themes, current)
    local tw, th = term.getSize()
    local listHeight = math.max(8, th - 8)
    local listWidth = math.max(26, math.floor((tw - 5) * 0.58))
    local rightX = 2 + listWidth + 1
    local rightW = tw - rightX - 1

    drawListPage(state, {
        x = 2,
        y = 6,
        width = listWidth,
        height = listHeight,
        title = " Palette Browser ",
        border = colors.cyan,
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
    })

    ui.drawFrame(rightX, 6, rightW, listHeight, colors.pink, colors.black, " Theme Details ", colors.white)
    drawBoxKeyValue(rightX + 2, 7, rightW - 4, "Current", current.label, colors.white)
    drawBoxKeyValue(rightX + 2, 8, rightW - 4, "Display", (#state.monitorTiles > 0) and (tostring(#state.monitorTiles) .. " wall monitor(s)") or "Terminal preview", colors.lightBlue)
    ui.writeWrapped(rightX + 2, 10, rightW - 4, "Palettes are applied to both the terminal UI and the display wall for a more unified, modern control surface.", colors.lightGray, colors.black, 4)
end

local function drawSettingsPage(state)
    local tw = term.getSize()
    local perf = state.performance or {}

    ui.drawFrame(2, 6, math.max(26, math.floor((tw - 5) * 0.58)), 9, colors.green, colors.black, " Runtime Tuning ", colors.white)
    ui.writeAt(4, 7, "Seed", colors.white)
    ui.addButton(state, 12, 7, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = -1 })
    ui.addButton(state, 16, 7, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = 1 })
    ui.addButton(state, 20, 7, 8, "Random", colors.purple, colors.white, { type = "seed_random" })
    ui.writeAt(29, 7, tostring(state.runtimeSettings.rngSeed), colors.lightBlue)

    ui.writeAt(4, 8, "FPS", colors.white)
    ui.addButton(state, 12, 8, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = -1 })
    ui.addButton(state, 16, 8, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = 1 })
    ui.addButton(state, 20, 8, 8, "Auto", colors.blue, colors.white, { type = "fps_auto" })
    ui.writeAt(29, 8, state.runtimeSettings.fpsOverride == 0 and "Auto" or tostring(state.runtimeSettings.fpsOverride), colors.lightBlue)

    ui.writeAt(4, 9, "GPU", colors.cyan)
    ui.addButton(state, 12, 9, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "gpuScale", delta = -1 })
    ui.addButton(state, 16, 9, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "gpuScale", delta = 1 })
    ui.addButton(state, 20, 9, 9, state.runtimeSettings.gpuAdaptive and "Adaptive" or "Manual", state.runtimeSettings.gpuAdaptive and colors.cyan or colors.gray, state.runtimeSettings.gpuAdaptive and colors.black or colors.white, { type = "gpu_toggle" })
    ui.writeAt(30, 9, "x" .. tostring(state.sampleScale or state.runtimeSettings.gpuScale or 1), colors.lightBlue)

    drawAdjustRow(state, 4, 11, "Speed", "speedPercent", 5)
    drawAdjustRow(state, 4, 12, "Power", "intensityPercent", 5)
    drawAdjustRow(state, 4, 13, "Spark", "sparklePercent", 5)
    drawAdjustRow(state, 27, 11, "Varia", "variationPercent", 5)
    drawAdjustRow(state, 27, 12, "Light", "brightnessPercent", 5)

    ui.drawFrame(math.max(26, math.floor((tw - 5) * 0.58)) + 3, 6, tw - math.max(26, math.floor((tw - 5) * 0.58)) - 4, 9, colors.lightBlue, colors.black, " Presets + Telemetry ", colors.white)
    local panelX = math.max(26, math.floor((tw - 5) * 0.58)) + 5
    ui.addButton(state, panelX, 7, 8, "Cinema", colors.gray, colors.white, { type = "preset", id = "cinematic" })
    ui.addButton(state, panelX + 9, 7, 8, "Chaos", colors.gray, colors.white, { type = "preset", id = "chaotic" })
    ui.addButton(state, panelX, 9, 8, "Calm", colors.gray, colors.white, { type = "preset", id = "calm" })
    ui.addButton(state, panelX + 9, 9, 8, "Storm", colors.gray, colors.white, { type = "preset", id = "storm" })
    ui.addButton(state, panelX + 4, 11, 8, "Club", colors.gray, colors.white, { type = "preset", id = "club" })
    ui.writeWrapped(panelX, 12, math.max(12, tw - panelX - 2), string.format("Avg render %.1fms • target %.1fms", (perf.avgRenderCost or 0) * 1000, (state.frameTime or 0) * (perf.targetBudgetRatio or 0.85) * 1000), colors.lightGray, colors.black, 2)
end

local function drawLayoutPage(state)
    local tw, th = term.getSize()
    local attached = #state.monitorTiles > 0
    local selectedTile = state.monitorTiles[state.selectedMonitorIndex]
    local mapW = math.max(22, math.floor((tw - 5) * 0.5))
    local controlsX = 2 + mapW + 1
    local controlsW = tw - controlsX - 1

    ui.drawFrame(2, 6, mapW, 10, colors.blue, colors.black, " Wall Overview ", colors.white)
    ui.drawMiniMap(state, 3, 7, mapW - 2, 8)

    ui.drawFrame(controlsX, 6, controlsW, 10, colors.cyan, colors.black, " Layout Actions ", colors.white)
    ui.addButton(state, controlsX + 2, 7, 10, "Prev", colors.blue, colors.white, { type = "cycle" })
    ui.addButton(state, controlsX + 13, 7, 10, state.showLayoutPreview and "Hide" or "Show", state.showLayoutPreview and colors.pink or colors.gray, state.showLayoutPreview and colors.black or colors.white, { type = "preview" })
    ui.addButton(state, controlsX + 2, 9, 10, "Auto row", colors.purple, colors.white, { type = "auto_row" })
    ui.addButton(state, controlsX + 13, 9, 10, "Auto col", colors.purple, colors.white, { type = "auto_column" })
    ui.addButton(state, controlsX + 2, 10, 10, "Reset", colors.orange, colors.white, { type = "reset" })
    ui.addButton(state, controlsX + 13, 10, 10, "Invert", colors.lightBlue, colors.black, { type = "invert" })
    ui.addButton(state, controlsX + 2, 12, 10, "Rescan", colors.cyan, colors.black, { type = "rescan" })
    ui.addButton(state, controlsX + 13, 12, 4, "<", colors.gray, colors.white, { type = "move", dx = -1, dy = 0 })
    ui.addButton(state, controlsX + 18, 11, 4, "^", colors.gray, colors.white, { type = "move", dx = 0, dy = -1 })
    ui.addButton(state, controlsX + 18, 12, 4, "v", colors.gray, colors.white, { type = "move", dx = 0, dy = 1 })
    ui.addButton(state, controlsX + 23, 12, 4, ">", colors.gray, colors.white, { type = "move", dx = 1, dy = 0 })

    ui.drawFrame(2, 17, tw - 2, math.max(2, th - 17), colors.green, colors.black, " Layout Status ", colors.white)
    if selectedTile then
        drawBoxKeyValue(4, 18, tw - 6, "Selected", string.format("%s (%s)", selectedTile.name, selectedTile.label or "?"), colors.white)
        if th >= 20 then
            drawBoxKeyValue(4, 19, tw - 6, "Position", string.format("(%d,%d)  %dx%d", selectedTile.x, selectedTile.y, selectedTile.width, selectedTile.height), colors.lightGray)
        end
    else
        drawBoxKeyValue(4, 18, tw - 6, "Selected", attached and "Waiting for selection" or "No monitor wall detected", attached and colors.white or colors.gray)
    end
end

local function drawAboutPage(state)
    local tw, th = term.getSize()
    local appMeta = meta(state)
    ui.drawFrame(2, 6, tw - 2, th - 6, colors.orange, colors.black, " About / Credits / License ", colors.white)

    drawBoxKeyValue(4, 7, tw - 6, "Tablet", appMeta.tabletName or state.config.title, colors.white)
    drawBoxKeyValue(4, 8, tw - 6, "Version", appMeta.version or state.config.version, colors.lightBlue)
    drawBoxKeyValue(4, 9, tw - 6, "Author", joinList(appMeta.author, "tsuki_kami_"), colors.pink)
    drawBoxKeyValue(4, 10, tw - 6, "Credits", joinList(appMeta.credits, "CC: Tweaked • modular control wall inspiration"), colors.cyan)
    drawBoxKeyValue(4, 11, tw - 6, "License", appMeta.license ~= "" and appMeta.license or "Custom attribution license", colors.green)
    ui.writeWrapped(4, 13, tw - 6, "This project is free to use, edit, and build upon. Edited or inspired versions should continue to mention the original author and keep credit visible in the project or release notes.", colors.lightGray, colors.black, 4)
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

    drawHeader(state)
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
    elseif state.currentPage == "about" then
        drawAboutPage(state)
    end

    ui.drawStatusBar(state)
end

return M
