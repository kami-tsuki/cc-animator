---@diagnostic disable: undefined-global
local ui = require("animator.ui")
local util = require("animator.util")

local M = {}

local PAGE_TABS = {
    { id = "home", label = "Home", compact = "Home", width = 8, active = colors.pink },
    { id = "animations", label = "Animate", compact = "Anim", width = 10, active = colors.purple },
    { id = "themes", label = "Themes", compact = "Theme", width = 8, active = colors.cyan },
    { id = "layout", label = "Layout", compact = "Map", width = 8, active = colors.blue },
    { id = "settings", label = "Settings", compact = "Cfg", width = 10, active = colors.green },
    { id = "about", label = "About", compact = "Info", width = 8, active = colors.orange },
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
        return fallback or "-"
    end
    return table.concat(values, ", ")
end

local function dash(value)
    value = util.trim(value or "")
    return value ~= "" and value or "-"
end

local function contentTop(state)
    return ((state.layoutMetrics or {}).contentTop or 6)
end

local function drawBoxKeyValue(x, y, width, label, value, valueColor)
    local prefix = tostring(label or "") .. ": "
    ui.writeAt(x, y, prefix, colors.lightGray)
    ui.writeAt(x + #prefix, y, util.truncate(dash(value), math.max(1, width - #prefix)), valueColor or colors.white)
end

local function drawHeader(state)
    local tw = term.getSize()
    local appMeta = meta(state)

    ui.panelWrite(1, string.rep(" ", tw), colors.white, colors.pink)
    ui.panelCenter(1, appMeta.tabletName or state.config.title or "Kami-Animator", colors.black, colors.pink)
    ui.panelWrite(2, string.rep(" ", tw), colors.white, colors.black)
    ui.panelCenter(2, string.format("v%s | %s", tostring(appMeta.version or state.config.version or "0.0.0"), tostring(appMeta.subtitle or state.config.subtitle or "Animation wall")), colors.lightBlue, colors.black)
end

local function drawPageTabs(state)
    local tw, th = term.getSize()
    local compact = tw < 58
    local reserveForQuit = 7
    local x, y = 2, 4

    for _, tab in ipairs(PAGE_TABS) do
        local label = compact and (tab.compact or tab.label) or tab.label
        local width = compact and math.max(6, #label + 2) or math.max(tab.width or 0, #label + 2)
        local active = state.currentPage == tab.id

        if x + width - 1 > tw - reserveForQuit then
            y = y + 1
            x = 2
        end

        if y > th - 2 then
            break
        end

        ui.addButton(state, x, y, width, label, active and tab.active or colors.gray, active and colors.black or colors.white, {
            type = "page",
            id = tab.id
        })
        x = x + width + 1
    end

    if x + 5 > tw then
        y = y + 1
        x = 2
    end

    ui.addButton(state, x, math.min(y, th - 1), math.min(6, tw - x + 1), "Quit", colors.red, colors.white, { type = "quit" })

    state.layoutMetrics = state.layoutMetrics or {}
    state.layoutMetrics.tabBottom = y
    state.layoutMetrics.contentTop = math.min(y + 2, th - 2)
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

local function drawQuickRow(state, x, y, width, items)
    if #items == 0 then
        return
    end

    local gap = 1
    local buttonWidth = math.max(4, math.floor((width - ((#items - 1) * gap)) / #items))
    local cursor = x

    for index, item in ipairs(items) do
        local remaining = (x + width - 1) - cursor + 1
        local w = index == #items and remaining or math.min(buttonWidth, remaining)
        if w >= 4 then
            ui.addButton(state, cursor, y, w, item.label, item.bg, item.fg, item.action)
        end
        cursor = cursor + w + gap
    end
end

local function drawHomePage(state, current, theme)
    current = current or { label = "Unknown" }
    theme = theme or { label = "Unknown" }

    local tw, th = term.getSize()
    local top = contentTop(state)
    local perf = state.performance or {}
    local appMeta = meta(state)
    local renderMs = string.format("%.1fms", ((perf.avgRenderCost or perf.lastRenderCost or 0) * 1000))
    local gpuText = string.format("%s x%d", perf.mode == "adaptive" and "Adaptive" or "Manual", state.sampleScale or perf.renderScale or 1)
    local statusText = state.lastError and ("Error: " .. state.lastError) or ((state.statusMessage and state.statusMessage ~= "") and state.statusMessage or "Ready")

    local liveH = math.max(6, math.min(8, th - top - 4))
    if liveH > th - top - 2 then
        liveH = math.max(4, th - top - 2)
    end

    ui.drawFrame(2, top, tw - 2, liveH, colors.pink, colors.black, " Live Session ", colors.white)
    local maxRow = top + liveH - 1

    if top + 1 <= maxRow then
        drawBoxKeyValue(4, top + 1, tw - 6, "Animation", current.label, colors.white)
    end
    if top + 2 <= maxRow then
        drawBoxKeyValue(4, top + 2, tw - 6, "Theme", theme.label, colors.cyan)
    end
    if top + 3 <= maxRow then
        drawBoxKeyValue(4, top + 3, tw - 6, "Display", (#state.monitorTiles > 0) and string.format("%d monitor(s) | %dx%d | %dfps", #state.monitorTiles, state.width, state.height, state.fps) or "Waiting for advanced monitors", (#state.monitorTiles > 0) and colors.green or colors.pink)
    end
    if top + 4 <= maxRow then
        drawBoxKeyValue(4, top + 4, tw - 6, "Preview", state.showLayoutPreview and "Layout preview" or "Live render", state.showLayoutPreview and colors.lightBlue or colors.lightGray)
    end
    if top + 5 <= maxRow then
        drawBoxKeyValue(4, top + 5, tw - 6, "Renderer", gpuText .. " | " .. renderMs, colors.cyan)
    end
    if top + 6 <= maxRow then
        drawBoxKeyValue(4, top + 6, tw - 6, "Status", statusText, state.lastError and colors.pink or colors.lightGray)
    end

    local actionsY = top + liveH + 1
    local actionsH = th - actionsY - 1
    if actionsH >= 3 then
        ui.drawFrame(2, actionsY, tw - 2, actionsH, colors.cyan, colors.black, " Quick Actions ", colors.white)
        drawQuickRow(state, 4, actionsY + 1, math.max(12, tw - 6), {
            { label = "Animate", bg = colors.purple, fg = colors.white, action = { type = "page", id = "animations" } },
            { label = "Themes", bg = colors.cyan, fg = colors.black, action = { type = "page", id = "themes" } },
            { label = "Layout", bg = colors.blue, fg = colors.white, action = { type = "page", id = "layout" } },
        })

        if actionsH >= 4 then
            drawQuickRow(state, 4, actionsY + 2, math.max(12, tw - 6), {
                { label = "Settings", bg = colors.green, fg = colors.black, action = { type = "page", id = "settings" } },
                { label = "About", bg = colors.orange, fg = colors.white, action = { type = "page", id = "about" } },
                { label = "Rescan", bg = colors.gray, fg = colors.white, action = { type = "rescan" } },
            })
        end
    end

    if th >= 3 then
        local footer = string.format("%s v%s | by %s", appMeta.tabletName or state.config.title or "Kami-Animator", appMeta.version or state.config.version or "0.0.0", joinList(appMeta.author, "tsuki_kami_"))
        if dash(appMeta.license) ~= "-" then
            footer = footer .. " | " .. dash(appMeta.license)
        end
        ui.panelWrite(th - 1, " " .. util.truncate(footer, tw - 1), colors.lightBlue, colors.black)
    end
end

local function drawAnimationsPage(state, animations, current)
    current = current or { label = "Unknown" }

    local tw, th = term.getSize()
    local top = contentTop(state)
    local stacked = tw < 56

    if stacked then
        local listHeight = math.max(6, math.min(th - top - 6, ui.visibleListCount() + 3))
        drawListPage(state, {
            x = 2,
            y = top,
            width = tw - 2,
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
                return string.format("%02d %s", index, animations.all[id].label)
            end,
        })

        local infoY = top + listHeight + 1
        local infoH = math.max(4, th - infoY - 1)
        if infoH >= 4 then
            ui.drawFrame(2, infoY, tw - 2, infoH, colors.cyan, colors.black, " Selected Animation ", colors.white)
            drawBoxKeyValue(4, infoY + 1, tw - 6, "Name", current.label, colors.white)
            drawBoxKeyValue(4, infoY + 2, tw - 6, "Shortcut", "1-0 quick select", colors.lightBlue)
            if infoH >= 5 then
                ui.writeWrapped(4, infoY + 3, tw - 6, "Tap a card or press a number key to switch effects fast.", colors.lightGray, colors.black, 2)
            end
        end
        return
    end

    local listHeight = math.max(8, th - top - 1)
    local listWidth = math.max(26, math.floor((tw - 5) * 0.58))
    local rightX = 2 + listWidth + 1
    local rightW = tw - rightX - 1

    drawListPage(state, {
        x = 2,
        y = top,
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

    ui.drawFrame(rightX, top, rightW, listHeight, colors.cyan, colors.black, " Selected Animation ", colors.white)
    drawBoxKeyValue(rightX + 2, top + 1, rightW - 4, "Name", current.label, colors.white)
    drawBoxKeyValue(rightX + 2, top + 2, rightW - 4, "Shortcut", "1-0 quick select", colors.lightBlue)
    drawBoxKeyValue(rightX + 2, top + 3, rightW - 4, "Theme", state.selectedTheme, colors.cyan)
    ui.writeWrapped(rightX + 2, top + 5, rightW - 4, "Switch effects instantly. Adaptive sampling stays tuned for large walls.", colors.lightGray, colors.black, 4)
end

local function drawThemesPage(state, themes, current)
    current = current or { label = "Unknown" }

    local tw, th = term.getSize()
    local top = contentTop(state)
    local stacked = tw < 56

    if stacked then
        local listHeight = math.max(6, math.min(th - top - 6, ui.visibleListCount() + 3))
        drawListPage(state, {
            x = 2,
            y = top,
            width = tw - 2,
            height = listHeight,
            title = " Theme Browser ",
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

        local infoY = top + listHeight + 1
        local infoH = math.max(4, th - infoY - 1)
        if infoH >= 4 then
            ui.drawFrame(2, infoY, tw - 2, infoH, colors.pink, colors.black, " Theme Details ", colors.white)
            drawBoxKeyValue(4, infoY + 1, tw - 6, "Current", current.label, colors.white)
            drawBoxKeyValue(4, infoY + 2, tw - 6, "Display", (#state.monitorTiles > 0) and (tostring(#state.monitorTiles) .. " wall monitor(s)") or "Terminal preview", colors.lightBlue)
        end
        return
    end

    local listHeight = math.max(8, th - top - 1)
    local listWidth = math.max(26, math.floor((tw - 5) * 0.58))
    local rightX = 2 + listWidth + 1
    local rightW = tw - rightX - 1

    drawListPage(state, {
        x = 2,
        y = top,
        width = listWidth,
        height = listHeight,
        title = " Theme Browser ",
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

    ui.drawFrame(rightX, top, rightW, listHeight, colors.pink, colors.black, " Theme Details ", colors.white)
    drawBoxKeyValue(rightX + 2, top + 1, rightW - 4, "Current", current.label, colors.white)
    drawBoxKeyValue(rightX + 2, top + 2, rightW - 4, "Display", (#state.monitorTiles > 0) and (tostring(#state.monitorTiles) .. " wall monitor(s)") or "Terminal preview", colors.lightBlue)
    ui.writeWrapped(rightX + 2, top + 4, rightW - 4, "Theme colors apply to both the terminal UI and the display wall.", colors.lightGray, colors.black, 4)
end

local function drawSettingsPage(state)
    local tw, th = term.getSize()
    local top = contentTop(state)
    local perf = state.performance or {}
    local narrow = tw < 56

    local leftW = narrow and (tw - 2) or math.max(26, math.floor((tw - 5) * 0.58))
    ui.drawFrame(2, top, leftW, 9, colors.green, colors.black, " Runtime Tuning ", colors.white)
    ui.writeAt(4, top + 1, "Seed", colors.white)
    ui.addButton(state, 12, top + 1, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = -1 })
    ui.addButton(state, 16, top + 1, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = 1 })
    ui.addButton(state, 20, top + 1, 8, "Random", colors.purple, colors.white, { type = "seed_random" })
    ui.writeAt(29, top + 1, tostring(state.runtimeSettings.rngSeed), colors.lightBlue)

    ui.writeAt(4, top + 2, "FPS", colors.white)
    ui.addButton(state, 12, top + 2, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = -1 })
    ui.addButton(state, 16, top + 2, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = 1 })
    ui.addButton(state, 20, top + 2, 8, "Auto", colors.blue, colors.white, { type = "fps_auto" })
    ui.writeAt(29, top + 2, state.runtimeSettings.fpsOverride == 0 and "Auto" or tostring(state.runtimeSettings.fpsOverride), colors.lightBlue)

    ui.writeAt(4, top + 3, "GPU", colors.cyan)
    ui.addButton(state, 12, top + 3, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "gpuScale", delta = -1 })
    ui.addButton(state, 16, top + 3, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "gpuScale", delta = 1 })
    ui.addButton(state, 20, top + 3, 9, state.runtimeSettings.gpuAdaptive and "Adaptive" or "Manual", state.runtimeSettings.gpuAdaptive and colors.cyan or colors.gray, state.runtimeSettings.gpuAdaptive and colors.black or colors.white, { type = "gpu_toggle" })
    ui.writeAt(30, top + 3, "x" .. tostring(state.sampleScale or state.runtimeSettings.gpuScale or 1), colors.lightBlue)

    drawAdjustRow(state, 4, top + 5, "Speed", "speedPercent", 5)
    drawAdjustRow(state, 4, top + 6, "Power", "intensityPercent", 5)
    drawAdjustRow(state, 4, top + 7, "Spark", "sparklePercent", 5)
    drawAdjustRow(state, 27, top + 5, "Varia", "variationPercent", 5)
    drawAdjustRow(state, 27, top + 6, "Light", "brightnessPercent", 5)

    if narrow then
        local infoY = top + 10
        local infoH = math.max(4, th - infoY - 1)
        if infoH >= 4 then
            ui.drawFrame(2, infoY, tw - 2, infoH, colors.lightBlue, colors.black, " Presets + Telemetry ", colors.white)
            drawQuickRow(state, 4, infoY + 1, math.max(12, tw - 6), {
                { label = "Cinema", bg = colors.gray, fg = colors.white, action = { type = "preset", id = "cinematic" } },
                { label = "Chaos", bg = colors.gray, fg = colors.white, action = { type = "preset", id = "chaotic" } },
                { label = "Calm", bg = colors.gray, fg = colors.white, action = { type = "preset", id = "calm" } },
            })
            if infoH >= 5 then
                drawQuickRow(state, 4, infoY + 2, math.max(12, tw - 6), {
                    { label = "Storm", bg = colors.gray, fg = colors.white, action = { type = "preset", id = "storm" } },
                    { label = "Club", bg = colors.gray, fg = colors.white, action = { type = "preset", id = "club" } },
                })
            end
            ui.writeWrapped(4, infoY + 3, tw - 6, string.format("Avg render %.1fms | target %.1fms", (perf.avgRenderCost or 0) * 1000, (state.frameTime or 0) * (perf.targetBudgetRatio or 0.85) * 1000), colors.lightGray, colors.black, 2)
        end
        return
    end

    local rightX = leftW + 3
    local rightW = tw - rightX - 1
    ui.drawFrame(rightX, top, rightW, 9, colors.lightBlue, colors.black, " Presets + Telemetry ", colors.white)
    local panelX = rightX + 2
    ui.addButton(state, panelX, top + 1, 8, "Cinema", colors.gray, colors.white, { type = "preset", id = "cinematic" })
    ui.addButton(state, panelX + 9, top + 1, 8, "Chaos", colors.gray, colors.white, { type = "preset", id = "chaotic" })
    ui.addButton(state, panelX, top + 3, 8, "Calm", colors.gray, colors.white, { type = "preset", id = "calm" })
    ui.addButton(state, panelX + 9, top + 3, 8, "Storm", colors.gray, colors.white, { type = "preset", id = "storm" })
    ui.addButton(state, panelX + 4, top + 5, 8, "Club", colors.gray, colors.white, { type = "preset", id = "club" })
    ui.writeWrapped(panelX, top + 6, math.max(12, tw - panelX - 2), string.format("Avg render %.1fms | target %.1fms", (perf.avgRenderCost or 0) * 1000, (state.frameTime or 0) * (perf.targetBudgetRatio or 0.85) * 1000), colors.lightGray, colors.black, 2)
end

local function drawLayoutPage(state)
    local tw, th = term.getSize()
    local top = contentTop(state)
    local attached = #state.monitorTiles > 0
    local selectedTile = state.monitorTiles[state.selectedMonitorIndex]
    local stacked = tw < 56

    if stacked then
        ui.drawFrame(2, top, tw - 2, 8, colors.blue, colors.black, " Wall Overview ", colors.white)
        ui.drawMiniMap(state, 3, top + 1, tw - 4, 6)

        local controlsY = top + 9
        local controlsH = math.max(4, th - controlsY - 1)
        ui.drawFrame(2, controlsY, tw - 2, controlsH, colors.cyan, colors.black, " Layout Actions ", colors.white)
        drawQuickRow(state, 4, controlsY + 1, math.max(12, tw - 6), {
            { label = "Prev", bg = colors.blue, fg = colors.white, action = { type = "cycle" } },
            { label = state.showLayoutPreview and "Hide" or "Show", bg = state.showLayoutPreview and colors.pink or colors.gray, fg = state.showLayoutPreview and colors.black or colors.white, action = { type = "preview" } },
            { label = "Rescan", bg = colors.cyan, fg = colors.black, action = { type = "rescan" } },
        })
        if controlsH >= 5 then
            drawQuickRow(state, 4, controlsY + 2, math.max(12, tw - 6), {
                { label = "Auto row", bg = colors.purple, fg = colors.white, action = { type = "auto_row" } },
                { label = "Auto col", bg = colors.purple, fg = colors.white, action = { type = "auto_column" } },
                { label = "Reset", bg = colors.orange, fg = colors.white, action = { type = "reset" } },
            })
        end
        if selectedTile and controlsH >= 6 then
            drawBoxKeyValue(4, controlsY + 4, tw - 6, "Selected", string.format("%s (%s)", selectedTile.name, selectedTile.label or "?"), colors.white)
        elseif controlsH >= 6 then
            drawBoxKeyValue(4, controlsY + 4, tw - 6, "Selected", attached and "Waiting for selection" or "No monitor wall detected", attached and colors.white or colors.gray)
        end
        return
    end

    local mapW = math.max(22, math.floor((tw - 5) * 0.5))
    local controlsX = 2 + mapW + 1
    local controlsW = tw - controlsX - 1

    ui.drawFrame(2, top, mapW, 10, colors.blue, colors.black, " Wall Overview ", colors.white)
    ui.drawMiniMap(state, 3, top + 1, mapW - 2, 8)

    ui.drawFrame(controlsX, top, controlsW, 10, colors.cyan, colors.black, " Layout Actions ", colors.white)
    ui.addButton(state, controlsX + 2, top + 1, 10, "Prev", colors.blue, colors.white, { type = "cycle" })
    ui.addButton(state, controlsX + 13, top + 1, 10, state.showLayoutPreview and "Hide" or "Show", state.showLayoutPreview and colors.pink or colors.gray, state.showLayoutPreview and colors.black or colors.white, { type = "preview" })
    ui.addButton(state, controlsX + 2, top + 3, 10, "Auto row", colors.purple, colors.white, { type = "auto_row" })
    ui.addButton(state, controlsX + 13, top + 3, 10, "Auto col", colors.purple, colors.white, { type = "auto_column" })
    ui.addButton(state, controlsX + 2, top + 4, 10, "Reset", colors.orange, colors.white, { type = "reset" })
    ui.addButton(state, controlsX + 13, top + 4, 10, "Invert", colors.lightBlue, colors.black, { type = "invert" })
    ui.addButton(state, controlsX + 2, top + 6, 10, "Rescan", colors.cyan, colors.black, { type = "rescan" })
    ui.addButton(state, controlsX + 13, top + 6, 4, "<", colors.gray, colors.white, { type = "move", dx = -1, dy = 0 })
    ui.addButton(state, controlsX + 18, top + 5, 4, "^", colors.gray, colors.white, { type = "move", dx = 0, dy = -1 })
    ui.addButton(state, controlsX + 18, top + 6, 4, "v", colors.gray, colors.white, { type = "move", dx = 0, dy = 1 })
    ui.addButton(state, controlsX + 23, top + 6, 4, ">", colors.gray, colors.white, { type = "move", dx = 1, dy = 0 })

    local statusY = top + 11
    local statusH = math.max(3, th - statusY)
    ui.drawFrame(2, statusY, tw - 2, statusH, colors.green, colors.black, " Layout Status ", colors.white)
    if selectedTile then
        drawBoxKeyValue(4, statusY + 1, tw - 6, "Selected", string.format("%s (%s)", selectedTile.name, selectedTile.label or "?"), colors.white)
        if statusH >= 4 then
            drawBoxKeyValue(4, statusY + 2, tw - 6, "Position", string.format("(%d,%d)  %dx%d", selectedTile.x, selectedTile.y, selectedTile.width, selectedTile.height), colors.lightGray)
        end
    else
        drawBoxKeyValue(4, statusY + 1, tw - 6, "Selected", attached and "Waiting for selection" or "No monitor wall detected", attached and colors.white or colors.gray)
    end
end

local function drawAboutPage(state)
    local tw, th = term.getSize()
    local top = contentTop(state)
    local appMeta = meta(state)
    ui.drawFrame(2, top, tw - 2, th - top, colors.orange, colors.black, " About / Credits / License ", colors.white)

    drawBoxKeyValue(4, top + 1, tw - 6, "Tablet", appMeta.tabletName or state.config.title, colors.white)
    drawBoxKeyValue(4, top + 2, tw - 6, "Version", appMeta.version or state.config.version, colors.lightBlue)
    drawBoxKeyValue(4, top + 3, tw - 6, "Author", joinList(appMeta.author, "tsuki_kami_"), colors.pink)
    drawBoxKeyValue(4, top + 4, tw - 6, "Credits", joinList(appMeta.credits, "CC: Tweaked, modular control wall inspiration"), colors.cyan)
    drawBoxKeyValue(4, top + 5, tw - 6, "License", dash(appMeta.license) ~= "-" and appMeta.license or "Custom attribution license", colors.green)
    ui.writeWrapped(4, top + 7, tw - 6, "Free to use, edit, and build upon. Please keep author credit where practical.", colors.lightGray, colors.black, 4)
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
