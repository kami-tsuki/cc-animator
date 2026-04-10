---@diagnostic disable: undefined-global, undefined-field
local animations = require("animator.animations")
local config = require("animator.config")
local manifestModel = require("animator.manifest")
local renderer = require("animator.render")
local screens = require("animator.ui.screens")
local ui = require("animator.ui")
local themes = require("animator.themes")
local util = require("animator.util")

local M = {}

local sin, floor = math.sin, math.floor

local RUNTIME_PRESETS = {
    cinematic = { label = "Cinematic", speedPercent = 85, intensityPercent = 110, sparklePercent = 75, variationPercent = 60, fpsOverride = 10 },
    chaotic = { label = "Chaotic", speedPercent = 145, intensityPercent = 140, sparklePercent = 150, variationPercent = 165, fpsOverride = 18 },
    calm = { label = "Calm", speedPercent = 70, intensityPercent = 85, sparklePercent = 60, variationPercent = 45, fpsOverride = 9 },
    storm = { label = "Storm", speedPercent = 120, intensityPercent = 145, sparklePercent = 125, variationPercent = 110, fpsOverride = 14 },
    club = { label = "Club", speedPercent = 130, intensityPercent = 125, sparklePercent = 160, variationPercent = 140, fpsOverride = 16 },
}

local function parseRequestedMonitors(...)
    local requested = {}
    for _, value in ipairs({ ... }) do
        for name in tostring(value):gmatch("[^,%s]+") do
            requested[#requested + 1] = name
        end
    end
    return requested
end

local function saveState(state)
    config.saveRuntime({
        animation = state.selectedAnimation,
        theme = state.selectedTheme,
        runtime = state.runtimeSettings,
        layout = state.settingsLayout,
        page = state.currentPage,
        showLayoutPreview = state.showLayoutPreview,
    })
end

local function updateDerivedTuning(state)
    local runtime = state.runtimeSettings
    local seed = tonumber(runtime.rngSeed) or 1337
    local variation = (runtime.variationPercent or 100) / 100

    local function seedNoise(offset)
        local value = sin((seed + offset * 37.17) * 12.9898) * 43758.5453
        return value - floor(value)
    end

    state.derivedTuning = {
        speedA = ((runtime.speedPercent or 100) / 100) * (0.92 + seedNoise(1) * 0.16 * variation),
        energy = ((runtime.intensityPercent or 100) / 100) * (0.94 + seedNoise(2) * 0.18 * variation),
        sparkle = ((runtime.sparklePercent or 100) / 100) * (0.90 + seedNoise(3) * 0.24 * variation),
        bias = (seedNoise(4) - 0.5) * 0.08 * variation,
        phase = seedNoise(5) * 9.0 * variation,
        chaos = 1.0 + seedNoise(6) * 0.60 * variation,
        warp = 0.8 + seedNoise(7) * 0.9 * variation,
        jitter = (seedNoise(8) - 0.5) * 0.20 * variation,
    }
end

local function syncPerformanceSettings(state)
    local gpuConfig = state.config.gpu or {}
    local minScale = util.clamp(gpuConfig.minScale or 1, 1, 6)
    local maxScale = util.clamp(gpuConfig.maxScale or 4, minScale, 6)
    local adaptiveDefault = (gpuConfig.mode or "adaptive") ~= "manual"
    local adaptive = (state.runtimeSettings.gpuAdaptive == nil) and adaptiveDefault or state.runtimeSettings.gpuAdaptive

    state.runtimeSettings.gpuScale = util.clamp(state.runtimeSettings.gpuScale or gpuConfig.defaultScale or 1, minScale, maxScale)
    state.runtimeSettings.gpuAdaptive = adaptive

    state.performance = state.performance or {}
    state.performance.mode = adaptive and "adaptive" or "manual"
    state.performance.minScale = minScale
    state.performance.maxScale = maxScale
    state.performance.targetBudgetRatio = util.clamp(gpuConfig.targetBudgetRatio or 0.85, 0.5, 0.98)

    state.performance.renderScale = util.clamp(state.runtimeSettings.gpuScale or state.performance.renderScale or 1, minScale, maxScale)
end

local function loadDisplayMeta(appConfig)
    local meta = manifestModel.load() or {}
    local authors = type(meta.author) == "table" and meta.author or {}
    local credits = type(meta.credits) == "table" and meta.credits or {}

    if #authors == 0 then
        authors = { "tsuki_kami_" }
    end

    return {
        tabletName = util.trim(meta.tabletName or appConfig.title or "Kami-Animator"),
        version = util.trim(meta.version or appConfig.version or "0.0.0"),
        subtitle = util.trim(appConfig.subtitle or "Modular multi-monitor animation wall"),
        author = authors,
        credits = credits,
        license = util.trim(meta.license or ""),
    }
end

local function makeState(requestedMonitors)
    local appConfig = config.loadGeneral()
    local saved = config.loadRuntime()
    local runtime = util.deepMerge(config.defaultRuntimeSettings(), saved.runtime or {})

    local selectedAnimation = (saved.animation and animations.all[saved.animation]) and saved.animation or appConfig.defaultAnimation
    local selectedTheme = (saved.theme and themes.all[saved.theme]) and saved.theme or appConfig.defaultTheme

    local state = {
        config = appConfig,
        meta = loadDisplayMeta(appConfig),
        requestedMonitors = requestedMonitors,
        selectedAnimation = selectedAnimation,
        selectedTheme = selectedTheme,
        currentPage = saved.page or "home",
        showLayoutPreview = (saved.showLayoutPreview == nil) and appConfig.showPreviewOnBoot or saved.showLayoutPreview,
        statusMessage = "",
        settingsLayout = type(saved.layout) == "table" and saved.layout or {},
        runtimeSettings = runtime,
        derivedTuning = {},
        listScroll = {
            animations = 0,
            themes = 0,
        },
        selectedMonitorIndex = 1,
        monitorTiles = {},
        monitorName = nil,
        width = 0,
        height = 0,
        fps = 12,
        frameTime = 1 / 12,
        renderCellCount = 0,
        uiButtons = {},
        previewDirty = true,
        xNorm = {},
        yNorm = {},
        adaptiveXGrid = {},
        adaptiveYGrid = {},
        rowChars = {},
        rowFg = {},
        rowBg = {},
        performance = {
            mode = "adaptive",
            minScale = 1,
            maxScale = 4,
            renderScale = runtime.gpuScale or 1,
            targetBudgetRatio = 0.85,
            avgRenderCost = 0,
            lastRenderCost = 0,
            lastFps = 0,
        },
        sampleScale = 1,
        sampleWidth = 1,
        sampleHeight = 1,
        sampleStep = 1,
        sampleXMap = {},
        sampleYMap = {},
        sampleXStart = {},
        sampleXEnd = {},
        sampleYStart = {},
        sampleYEnd = {},
        sampleYNorm = {},
        renderContext = nil,
    }

    syncPerformanceSettings(state)
    updateDerivedTuning(state)
    return state
end

local function redraw(state, message)
    renderer.applyTheme(state, themes.get(state.selectedTheme))
    screens.drawControlPanel(state, animations, themes, message)
end

local function setAnimation(state, id, persist)
    if not animations.all[id] then
        return false
    end

    state.selectedAnimation = id
    renderer.refreshSamplingState(state)
    state.previewDirty = true

    if persist then
        saveState(state)
    end

    redraw(state, "Saved animation: " .. animations.get(id).label)
    return true
end

local function setTheme(state, id, persist)
    if not themes.all[id] then
        return false
    end

    state.selectedTheme = id
    renderer.applyTheme(state, themes.get(id))
    renderer.rebuildLayout(state)

    if persist then
        saveState(state)
    end

    redraw(state, "Saved theme: " .. themes.get(id).label)
    return true
end

local function adjustRuntimeSetting(state, key, delta)
    if key == "rngSeed" then
        state.runtimeSettings.rngSeed = util.clamp((state.runtimeSettings.rngSeed or 1337) + delta, 1, 999999)
    elseif key == "fpsOverride" then
        state.runtimeSettings.fpsOverride = util.clamp((state.runtimeSettings.fpsOverride or 0) + delta, 0, 30)
    elseif key == "speedPercent" then
        state.runtimeSettings.speedPercent = util.clamp((state.runtimeSettings.speedPercent or 100) + delta, 50, 200)
    elseif key == "intensityPercent" then
        state.runtimeSettings.intensityPercent = util.clamp((state.runtimeSettings.intensityPercent or 100) + delta, 50, 200)
    elseif key == "sparklePercent" then
        state.runtimeSettings.sparklePercent = util.clamp((state.runtimeSettings.sparklePercent or 100) + delta, 50, 200)
    elseif key == "variationPercent" then
        state.runtimeSettings.variationPercent = util.clamp((state.runtimeSettings.variationPercent or 100) + delta, 0, 200)
    elseif key == "brightnessPercent" then
        state.runtimeSettings.brightnessPercent = util.clamp((state.runtimeSettings.brightnessPercent or 100) + delta, 35, 150)
    elseif key == "gpuScale" then
        local minimum = (state.performance and state.performance.minScale) or 1
        local maximum = (state.performance and state.performance.maxScale) or 4
        state.runtimeSettings.gpuScale = util.clamp((state.runtimeSettings.gpuScale or 1) + delta, minimum, maximum)
    else
        return false
    end

    syncPerformanceSettings(state)
    updateDerivedTuning(state)
    renderer.applyTheme(state, themes.get(state.selectedTheme))
    renderer.rebuildLayout(state)
    saveState(state)
    redraw(state, "Updated setting: " .. key)
    return true
end

local function randomizeSeed(state)
    state.runtimeSettings.rngSeed = math.random(1, 999999)
    updateDerivedTuning(state)
    renderer.rebuildLayout(state)
    saveState(state)
    redraw(state, "Randomized RNG seed to " .. state.runtimeSettings.rngSeed)
    return true
end

local function setFpsAuto(state)
    state.runtimeSettings.fpsOverride = 0
    updateDerivedTuning(state)
    renderer.rebuildLayout(state)
    saveState(state)
    redraw(state, "FPS set back to Auto.")
    return true
end

local function toggleGpuMode(state)
    state.runtimeSettings.gpuAdaptive = not state.runtimeSettings.gpuAdaptive
    syncPerformanceSettings(state)
    renderer.refreshSamplingState(state)
    saveState(state)

    if state.runtimeSettings.gpuAdaptive then
        redraw(state, "GPU renderer switched to adaptive mode.")
    else
        redraw(state, "GPU renderer locked to x" .. tostring(state.runtimeSettings.gpuScale) .. ".")
    end

    return true
end

local function applyRuntimePreset(state, id)
    local preset = RUNTIME_PRESETS[id]
    if not preset then
        return false
    end

    state.runtimeSettings.speedPercent = preset.speedPercent
    state.runtimeSettings.intensityPercent = preset.intensityPercent
    state.runtimeSettings.sparklePercent = preset.sparklePercent
    state.runtimeSettings.variationPercent = preset.variationPercent
    state.runtimeSettings.fpsOverride = preset.fpsOverride

    updateDerivedTuning(state)
    renderer.rebuildLayout(state)
    saveState(state)
    redraw(state, "Applied preset: " .. preset.label)
    return true
end

local function cycleSelectedMonitor(state)
    if #state.monitorTiles == 0 then
        return false
    end

    state.selectedMonitorIndex = (state.selectedMonitorIndex % #state.monitorTiles) + 1
    state.previewDirty = true
    redraw(state, "Selected monitor: " .. state.monitorTiles[state.selectedMonitorIndex].name)
    return true
end

local function toggleLayoutPreview(state)
    state.showLayoutPreview = not state.showLayoutPreview
    state.previewDirty = true
    saveState(state)

    if state.showLayoutPreview then
        renderer.drawPreviewWall(state)
        redraw(state, "Letter preview enabled for easier alignment.")
    else
        renderer.clearDisplayWall(state)
        redraw(state, "Letter preview disabled.")
    end

    return true
end

local function rescanMonitors(state)
    renderer.bindMonitors(state)
    renderer.applyTheme(state, themes.get(state.selectedTheme))
    saveState(state)
    redraw(state, (#state.monitorTiles > 0) and ("Output wall: " .. tostring(state.monitorName) .. string.format("  (%dx%d @ %dfps)", state.width, state.height, state.fps)) or "Waiting for advanced monitors...")
    return true
end

local function resetLayout(state)
    state.selectedMonitorIndex = 1
    state.settingsLayout = {}
    state.showLayoutPreview = true
    rescanMonitors(state)
    if #state.monitorTiles >= 4 then
        renderer.autoArrangeSmart(state)
        saveState(state)
        redraw(state, "Layout reset and auto-packed for the larger wall.")
    else
        renderer.autoArrangeRow(state)
        saveState(state)
        redraw(state, "Layout reset and arranged left-to-right.")
    end
    return true
end

local function scrollList(state, page, delta)
    local visibleCount = ui.visibleListCount()

    if page == "animations" then
        local maxScroll = math.max(0, #animations.order - visibleCount)
        state.listScroll.animations = math.max(0, math.min((state.listScroll.animations or 0) + delta, maxScroll))
    elseif page == "themes" then
        local maxScroll = math.max(0, #themes.order - visibleCount)
        state.listScroll.themes = math.max(0, math.min((state.listScroll.themes or 0) + delta, maxScroll))
    else
        return false
    end

    redraw(state)
    return true
end

local function handleUiAction(state, action)
    if not action then
        return false
    end

    if action.type == "page" then
        state.currentPage = action.id or "home"
        saveState(state)
        redraw(state, "Opened " .. screens.getPageLabel(state.currentPage))
        return true
    elseif action.type == "animation" then
        return setAnimation(state, action.id, true)
    elseif action.type == "theme" then
        return setTheme(state, action.id, true)
    elseif action.type == "setting_adjust" then
        return adjustRuntimeSetting(state, action.key, action.delta)
    elseif action.type == "seed_random" then
        return randomizeSeed(state)
    elseif action.type == "fps_auto" then
        return setFpsAuto(state)
    elseif action.type == "gpu_toggle" then
        return toggleGpuMode(state)
    elseif action.type == "preset" then
        return applyRuntimePreset(state, action.id)
    elseif action.type == "scroll" then
        return scrollList(state, action.page, action.delta)
    elseif action.type == "cycle" then
        return cycleSelectedMonitor(state)
    elseif action.type == "preview" then
        return toggleLayoutPreview(state)
    elseif action.type == "reset" then
        return resetLayout(state)
    elseif action.type == "invert" then
        renderer.invertLayout(state)
        saveState(state)
        redraw(state, "Inverted monitor order.")
        return true
    elseif action.type == "auto_row" then
        renderer.autoArrangeRow(state)
        saveState(state)
        redraw(state, "Auto-arranged monitor wall left-to-right.")
        return true
    elseif action.type == "auto_column" then
        renderer.autoArrangeColumn(state)
        saveState(state)
        redraw(state, "Auto-arranged monitor wall bottom-to-top.")
        return true
    elseif action.type == "move" then
        if renderer.moveSelectedMonitor(state, action.dx or 0, action.dy or 0) then
            saveState(state)
            local tile = state.monitorTiles[state.selectedMonitorIndex]
            redraw(state, string.format("Moved %s to (%d,%d)", tile.name, tile.x, tile.y))
            return true
        end
    elseif action.type == "rescan" then
        return rescanMonitors(state)
    elseif action.type == "quit" then
        return "quit"
    end

    return false
end

function M.run(...)
    math.randomseed((os.epoch and os.epoch("utc")) or os.time())

    local state = makeState(parseRequestedMonitors(...))
    renderer.bindMonitors(state)
    renderer.applyTheme(state, themes.get(state.selectedTheme))
    redraw(state, "Animator ready")

    local keyToAnimation = {
        [keys.one] = "energy",
        [keys.two] = "plasma",
        [keys.three] = "lattice",
        [keys.four] = "lightning",
        [keys.five] = "rave",
        [keys.six] = "aurora",
        [keys.seven] = "vortex",
        [keys.eight] = "dna",
        [keys.nine] = "matrix",
        [keys.zero] = "waterfall",
    }

    local running = true
    local time = 0
    local lastClock = os.clock()
    local timer = os.startTimer(0)

    while running do
        local event, p1, p2, p3 = os.pullEvent()

        if event == "timer" and p1 == timer then
            local now = os.clock()
            local dt = now - lastClock
            lastClock = now

            if dt <= 0 or dt > 1 then
                dt = state.frameTime
            end

            time = time + dt

            local renderCost = 0
            if #state.monitorTiles > 0 then
                local renderStart = os.clock()
                renderer.renderFrame(state, animations.get(state.selectedAnimation), time)
                renderCost = os.clock() - renderStart

                if renderer.updatePerformance(state, renderCost) then
                    redraw(state, "Adaptive renderer scale changed to x" .. tostring(state.sampleScale or 1) .. ".")
                end
            end

            timer = os.startTimer(math.max(0, state.frameTime - renderCost))

        elseif event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
            rescanMonitors(state)

        elseif event == "mouse_click" then
            local result = handleUiAction(state, ui.hitTest(state, p2, p3))
            if result == "quit" then
                running = false
            end

        elseif event == "mouse_scroll" then
            if state.currentPage == "animations" or state.currentPage == "themes" then
                scrollList(state, state.currentPage, p1)
            end

        elseif event == "key" then
            if p1 == keys.q then
                running = false
            elseif p1 == keys.r then
                rescanMonitors(state)
            elseif p1 == keys.tab then
                cycleSelectedMonitor(state)
            elseif p1 == keys.a then
                renderer.autoArrangeRow(state)
                saveState(state)
                redraw(state, "Auto-arranged monitor wall left-to-right.")
            elseif p1 == keys.c then
                renderer.autoArrangeColumn(state)
                saveState(state)
                redraw(state, "Auto-arranged monitor wall bottom-to-top.")
            elseif p1 == keys.p then
                toggleLayoutPreview(state)
            elseif p1 == keys.x then
                resetLayout(state)
            elseif p1 == keys.left then
                if renderer.moveSelectedMonitor(state, -1, 0) then
                    saveState(state)
                    redraw(state, "Moved selected monitor left.")
                end
            elseif p1 == keys.right then
                if renderer.moveSelectedMonitor(state, 1, 0) then
                    saveState(state)
                    redraw(state, "Moved selected monitor right.")
                end
            elseif p1 == keys.up then
                if renderer.moveSelectedMonitor(state, 0, -1) then
                    saveState(state)
                    redraw(state, "Moved selected monitor up.")
                end
            elseif p1 == keys.down then
                if renderer.moveSelectedMonitor(state, 0, 1) then
                    saveState(state)
                    redraw(state, "Moved selected monitor down.")
                end
            elseif keyToAnimation[p1] then
                setAnimation(state, keyToAnimation[p1], true)
            end
        end
    end

    renderer.clearDisplayWall(state)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    return true
end

return M
