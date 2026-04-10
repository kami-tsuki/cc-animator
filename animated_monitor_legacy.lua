---@diagnostic disable: undefined-global, undefined-field

-- ###############
-- # Boot / CLI #
-- ###############

local sin, cos = math.sin, math.cos
local floor, min, max, abs = math.floor, math.min, math.max, math.abs

local requestedMonitors = {}
for _, value in ipairs({ ... }) do
    for name in tostring(value):gmatch("[^,%s]+") do
        requestedMonitors[#requestedMonitors + 1] = name
    end
end

local SETTINGS_PATH = ".animated_monitor_settings"

-- ###############
-- # Configuration #
-- ###############

local CONFIG = {
    preferredScale = 0.5,
    minFps = 8,
    maxFps = 18,
    title = "Kami-Animator",
    version = "1.0",
    subtitle = "Kami's animation monitor",
}

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

local MATRIX_GLYPHS = { "0", "1", "2", "A", "E", "F", "K", "M", "N", "R", "X", "#", "%", "$", "+" }

local ANIMATION_ORDER = { "energy", "plasma", "lattice", "lightning", "rave", "aurora", "vortex", "matrix", "circuit", "beam", "tube", "waterfall", "arcstorm" }
local ANIMATIONS = {
    energy = {
        label = "Energy Flow",
    },
    plasma = {
        label = "Plasma Drift",
    },
    lattice = {
        label = "Pulse Lattice",
    },
    lightning = {
        label = "Storm Lightning",
    },
    rave = {
        label = "Rave Wave",
    },
    aurora = {
        label = "Aurora Veil",
    },
    vortex = {
        label = "Vortex Tunnel",
    },
    matrix = {
        label = "Matrix",
    },
    circuit = {
        label = "Circuit",
    },
    beam = {
        label = "Ion Beam",
    },
    tube = {
        label = "Lightning Tube",
    },
    waterfall = {
        label = "Neo Falls",
    },
    arcstorm = {
        label = "Arc Storm",
    },
}

local COLOR_SCHEME_ORDER = { "neon", "glacier", "toxic", "matrix", "motherboard", "sunset", "ember", "synthwave", "ocean", "mono", "candy", "redblack", "obsidian" }
local COLOR_SCHEMES = {
    neon = {
        label = "Neon",
        palette = {
            [colors.black] = { 0.02, 0.03, 0.07 },
            [colors.gray] = { 0.08, 0.11, 0.18 },
            [colors.lightGray] = { 0.25, 0.30, 0.40 },
            [colors.purple] = { 0.30, 0.07, 0.50 },
            [colors.blue] = { 0.05, 0.16, 0.58 },
            [colors.lightBlue] = { 0.12, 0.50, 1.00 },
            [colors.cyan] = { 0.00, 0.92, 0.84 },
            [colors.green] = { 0.17, 1.00, 0.60 },
            [colors.pink] = { 1.00, 0.20, 0.78 },
            [colors.white] = { 0.87, 0.98, 1.00 },
        },
    },
    glacier = {
        label = "Glacier",
        palette = {
            [colors.black] = { 0.01, 0.03, 0.09 },
            [colors.gray] = { 0.06, 0.12, 0.20 },
            [colors.lightGray] = { 0.24, 0.34, 0.46 },
            [colors.purple] = { 0.20, 0.20, 0.46 },
            [colors.blue] = { 0.05, 0.24, 0.72 },
            [colors.lightBlue] = { 0.35, 0.70, 1.00 },
            [colors.cyan] = { 0.50, 0.98, 1.00 },
            [colors.green] = { 0.58, 1.00, 0.92 },
            [colors.pink] = { 0.72, 0.84, 1.00 },
            [colors.white] = { 0.92, 0.99, 1.00 },
        },
    },
    toxic = {
        label = "Toxic",
        palette = {
            [colors.black] = { 0.02, 0.05, 0.02 },
            [colors.gray] = { 0.07, 0.12, 0.06 },
            [colors.lightGray] = { 0.20, 0.28, 0.16 },
            [colors.purple] = { 0.18, 0.22, 0.04 },
            [colors.blue] = { 0.10, 0.32, 0.06 },
            [colors.lightBlue] = { 0.32, 0.68, 0.10 },
            [colors.cyan] = { 0.58, 0.92, 0.10 },
            [colors.green] = { 0.72, 1.00, 0.18 },
            [colors.pink] = { 0.86, 0.98, 0.22 },
            [colors.white] = { 0.96, 1.00, 0.72 },
        },
    },
    sunset = {
        label = "Sunset",
        palette = {
            [colors.black] = { 0.07, 0.02, 0.06 },
            [colors.gray] = { 0.14, 0.06, 0.10 },
            [colors.lightGray] = { 0.28, 0.16, 0.18 },
            [colors.purple] = { 0.42, 0.08, 0.36 },
            [colors.blue] = { 0.30, 0.10, 0.32 },
            [colors.lightBlue] = { 0.82, 0.22, 0.52 },
            [colors.cyan] = { 1.00, 0.36, 0.44 },
            [colors.green] = { 1.00, 0.56, 0.26 },
            [colors.pink] = { 1.00, 0.28, 0.72 },
            [colors.white] = { 1.00, 0.88, 0.72 },
        },
    },
    ember = {
        label = "Ember",
        palette = {
            [colors.black] = { 0.06, 0.02, 0.01 },
            [colors.gray] = { 0.14, 0.06, 0.03 },
            [colors.lightGray] = { 0.28, 0.14, 0.08 },
            [colors.purple] = { 0.38, 0.06, 0.08 },
            [colors.blue] = { 0.44, 0.10, 0.03 },
            [colors.lightBlue] = { 0.78, 0.28, 0.04 },
            [colors.cyan] = { 0.94, 0.44, 0.05 },
            [colors.green] = { 1.00, 0.60, 0.12 },
            [colors.pink] = { 0.98, 0.24, 0.12 },
            [colors.white] = { 1.00, 0.92, 0.70 },
        },
    },
    synthwave = {
        label = "Synthwave",
        palette = {
            [colors.black] = { 0.03, 0.01, 0.06 },
            [colors.gray] = { 0.12, 0.04, 0.14 },
            [colors.lightGray] = { 0.24, 0.10, 0.24 },
            [colors.purple] = { 0.46, 0.05, 0.58 },
            [colors.blue] = { 0.18, 0.10, 0.48 },
            [colors.lightBlue] = { 0.12, 0.62, 0.98 },
            [colors.cyan] = { 0.28, 0.92, 0.96 },
            [colors.green] = { 0.96, 0.68, 0.18 },
            [colors.pink] = { 1.00, 0.16, 0.76 },
            [colors.white] = { 1.00, 0.94, 0.96 },
        },
    },
    ocean = {
        label = "Ocean",
        palette = {
            [colors.black] = { 0.00, 0.02, 0.05 },
            [colors.gray] = { 0.02, 0.08, 0.12 },
            [colors.lightGray] = { 0.10, 0.20, 0.28 },
            [colors.purple] = { 0.04, 0.16, 0.26 },
            [colors.blue] = { 0.00, 0.24, 0.44 },
            [colors.lightBlue] = { 0.08, 0.54, 0.72 },
            [colors.cyan] = { 0.10, 0.84, 0.82 },
            [colors.green] = { 0.30, 0.92, 0.64 },
            [colors.pink] = { 0.24, 0.72, 0.86 },
            [colors.white] = { 0.86, 0.98, 0.96 },
        },
    },
    mono = {
        label = "Mono",
        palette = {
            [colors.black] = { 0.01, 0.01, 0.01 },
            [colors.gray] = { 0.10, 0.10, 0.10 },
            [colors.lightGray] = { 0.24, 0.24, 0.24 },
            [colors.purple] = { 0.36, 0.36, 0.36 },
            [colors.blue] = { 0.48, 0.48, 0.48 },
            [colors.lightBlue] = { 0.62, 0.62, 0.62 },
            [colors.cyan] = { 0.76, 0.76, 0.76 },
            [colors.green] = { 0.86, 0.86, 0.86 },
            [colors.pink] = { 0.94, 0.94, 0.94 },
            [colors.white] = { 1.00, 1.00, 1.00 },
        },
    },
    candy = {
        label = "Candy",
        palette = {
            [colors.black] = { 0.05, 0.02, 0.04 },
            [colors.gray] = { 0.16, 0.08, 0.14 },
            [colors.lightGray] = { 0.30, 0.18, 0.26 },
            [colors.purple] = { 0.62, 0.18, 0.58 },
            [colors.blue] = { 0.22, 0.44, 0.78 },
            [colors.lightBlue] = { 0.24, 0.82, 1.00 },
            [colors.cyan] = { 0.40, 1.00, 0.92 },
            [colors.green] = { 0.96, 0.92, 0.32 },
            [colors.pink] = { 1.00, 0.46, 0.78 },
            [colors.white] = { 1.00, 0.98, 0.98 },
        },
    },
    redblack = {
        label = "Red/Black",
        palette = {
            [colors.black] = { 0.01, 0.00, 0.00 },
            [colors.gray] = { 0.10, 0.02, 0.02 },
            [colors.lightGray] = { 0.20, 0.05, 0.05 },
            [colors.purple] = { 0.28, 0.03, 0.06 },
            [colors.blue] = { 0.40, 0.04, 0.05 },
            [colors.lightBlue] = { 0.62, 0.06, 0.06 },
            [colors.cyan] = { 0.78, 0.10, 0.10 },
            [colors.green] = { 0.90, 0.16, 0.12 },
            [colors.pink] = { 1.00, 0.10, 0.12 },
            [colors.white] = { 1.00, 0.84, 0.84 },
        },
    },
    obsidian = {
        label = "Obsidian",
        palette = {
            [colors.black] = { 0.01, 0.00, 0.03 },
            [colors.gray] = { 0.07, 0.03, 0.10 },
            [colors.lightGray] = { 0.16, 0.09, 0.22 },
            [colors.purple] = { 0.28, 0.08, 0.44 },
            [colors.blue] = { 0.20, 0.06, 0.34 },
            [colors.lightBlue] = { 0.42, 0.18, 0.70 },
            [colors.cyan] = { 0.60, 0.28, 0.88 },
            [colors.green] = { 0.72, 0.40, 0.96 },
            [colors.pink] = { 0.86, 0.32, 1.00 },
            [colors.white] = { 0.94, 0.86, 1.00 },
        },
    },
    matrix = {
        label = "Matrix",
        palette = {
            [colors.black] = { 0.00, 0.02, 0.00 },
            [colors.gray] = { 0.01, 0.08, 0.02 },
            [colors.lightGray] = { 0.06, 0.18, 0.05 },
            [colors.purple] = { 0.02, 0.14, 0.03 },
            [colors.blue] = { 0.04, 0.24, 0.06 },
            [colors.lightBlue] = { 0.08, 0.42, 0.10 },
            [colors.cyan] = { 0.14, 0.68, 0.18 },
            [colors.green] = { 0.26, 0.96, 0.30 },
            [colors.pink] = { 0.56, 1.00, 0.56 },
            [colors.white] = { 0.88, 1.00, 0.88 },
        },
    },
    motherboard = {
        label = "Motherboard",
        palette = {
            [colors.black] = { 0.01, 0.05, 0.03 },
            [colors.gray] = { 0.04, 0.14, 0.08 },
            [colors.lightGray] = { 0.56, 0.62, 0.60 },
            [colors.purple] = { 0.08, 0.24, 0.12 },
            [colors.blue] = { 0.10, 0.28, 0.16 },
            [colors.lightBlue] = { 0.22, 0.50, 0.28 },
            [colors.cyan] = { 0.34, 0.74, 0.40 },
            [colors.green] = { 0.44, 1.00, 0.48 },
            [colors.pink] = { 0.72, 1.00, 0.74 },
            [colors.white] = { 0.94, 0.98, 0.96 },
        },
    },
}

-- ###############
-- # Runtime State #
-- ###############

local monitorTiles = {}
local monitorName = nil
local width, height = 0, 0
local xNorm, yNorm = {}, {}
local fps = 12
local frameTime = 1 / fps
local selectedAnimation = ANIMATION_ORDER[1]
local selectedScheme = COLOR_SCHEME_ORDER[1]
local selectedMonitorIndex = 1
local settingsLayout = {}
local uiButtons = {}
local currentPage = "home"
local showLayoutPreview = false
local previewDirty = true
local listScroll = {
    animations = 0,
    colors = 0,
}

local RUNTIME_SETTINGS = {
    rngSeed = 1337,
    fpsOverride = 0,
    speedPercent = 100,
    intensityPercent = 100,
    sparklePercent = 100,
    variationPercent = 100,
    brightnessPercent = 100,
}

local RUNTIME_PRESETS = {
    cinematic = { label = "Cinematic", speedPercent = 85, intensityPercent = 110, sparklePercent = 75, variationPercent = 60, fpsOverride = 10 },
    chaotic = { label = "Chaotic", speedPercent = 145, intensityPercent = 140, sparklePercent = 150, variationPercent = 165, fpsOverride = 18 },
    calm = { label = "Calm", speedPercent = 70, intensityPercent = 85, sparklePercent = 60, variationPercent = 45, fpsOverride = 9 },
    storm = { label = "Storm", speedPercent = 120, intensityPercent = 145, sparklePercent = 125, variationPercent = 110, fpsOverride = 14 },
    club = { label = "Club", speedPercent = 130, intensityPercent = 125, sparklePercent = 160, variationPercent = 140, fpsOverride = 16 },
}

local derivedTuning = {
    speedA = 1.0,
    energy = 1.0,
    sparkle = 1.0,
    bias = 0.0,
    phase = 0.0,
    chaos = 1.0,
    warp = 1.0,
    jitter = 0.0,
}

local PAGE_TABS = {
    { id = "home", label = "Home", width = 8, active = colors.pink },
    { id = "animations", label = "Animate", width = 10, active = colors.pink },
    { id = "colors", label = "Themes", width = 8, active = colors.cyan },
    { id = "layout", label = "Layout", width = 8, active = colors.blue },
    { id = "settings", label = "Settings", width = 11, active = colors.green },
}

local statusMessage = ""
local rowChars, rowFg, rowBg = {}, {}, {}
local rowMinX, rowMaxX = {}, {}
local colMinY, colMaxY = {}, {}
local adaptiveXGrid, adaptiveYGrid = {}, {}
local renderStep = 1
local renderCellCount = 0
local bindMonitor

local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function clampValue(value, minValue, maxValue)
    return max(minValue, min(maxValue, value))
end

local function updateDerivedTuning()
    local seed = tonumber(RUNTIME_SETTINGS.rngSeed) or 1337
    local variation = (RUNTIME_SETTINGS.variationPercent or 100) / 100

    local function seedNoise(offset)
        local value = sin((seed + offset * 37.17) * 12.9898) * 43758.5453
        return value - floor(value)
    end

    derivedTuning.speedA = ((RUNTIME_SETTINGS.speedPercent or 100) / 100) * (0.92 + seedNoise(1) * 0.16 * variation)
    derivedTuning.energy = ((RUNTIME_SETTINGS.intensityPercent or 100) / 100) * (0.94 + seedNoise(2) * 0.18 * variation)
    derivedTuning.sparkle = ((RUNTIME_SETTINGS.sparklePercent or 100) / 100) * (0.90 + seedNoise(3) * 0.24 * variation)
    derivedTuning.bias = (seedNoise(4) - 0.5) * 0.08 * variation
    derivedTuning.phase = seedNoise(5) * 9.0 * variation
    derivedTuning.chaos = 1.0 + seedNoise(6) * 0.60 * variation
    derivedTuning.warp = 0.8 + seedNoise(7) * 0.9 * variation
    derivedTuning.jitter = (seedNoise(8) - 0.5) * 0.20 * variation
end

local function getAdaptiveNorm(x, y)
    local sampleX = x
    if renderStep > 1 then
        sampleX = min(width, x + floor((renderStep - 1) * 0.5))
    end

    local rowX = adaptiveXGrid[y]
    local rowY = adaptiveYGrid[y]
    if rowX and rowY then
        return rowX[sampleX] or 0, rowY[sampleX] or 0
    end

    local minRow = rowMinX[y] or 1
    local maxRow = rowMaxX[y] or width
    local minCol = colMinY[sampleX] or 1
    local maxCol = colMaxY[sampleX] or height

    local localNx = (sampleX - (minRow + maxRow) * 0.5) / max(1, (maxRow - minRow + 1) * 0.5)
    local localNy = (y - (minCol + maxCol) * 0.5) / max(1, (maxCol - minCol + 1) * 0.5)
    local globalNx = xNorm[sampleX] or 0
    local globalNy = yNorm[y] or 0

    return globalNx * 0.30 + localNx * 0.70, globalNy * 0.30 + localNy * 0.70
end

-- ###############
-- # Core Helpers #
-- ###############

local function applyPalette(target)
    if not target or not target.setPaletteColor then return end

    local scheme = COLOR_SCHEMES[selectedScheme] or COLOR_SCHEMES.neon
    local brightness = clampValue((RUNTIME_SETTINGS.brightnessPercent or 100) / 100, 0.35, 1.5)
    for color, rgb in pairs(scheme.palette) do
        target.setPaletteColor(
            color,
            clamp01(rgb[1] * brightness),
            clamp01(rgb[2] * brightness),
            clamp01(rgb[3] * brightness)
        )
    end
end

local function getRenderStepForAnimation(animationId)
    if renderCellCount <= 8000 then
        return 1
    end

    local heavy = animationId == "matrix" or animationId == "lightning" or animationId == "arcstorm" or animationId == "tube"
    if heavy then
        return renderCellCount > 16000 and 2 or 1
    end

    return renderCellCount > 22000 and 2 or 1
end

-- ###############
-- # Persistence #
-- ###############

local function loadSettings()
    if not fs or not fs.exists or not fs.exists(SETTINGS_PATH) then return end

    local file = fs.open(SETTINGS_PATH, "r")
    if not file then return end

    local raw = file.readAll()
    file.close()

    local ok, data = pcall(textutils.unserialize, raw)
    if not ok or type(data) ~= "table" then return end

    if ANIMATIONS[data.animation] then
        selectedAnimation = data.animation
    end

    if COLOR_SCHEMES[data.scheme] then
        selectedScheme = data.scheme
    end

    if type(data.runtime) == "table" then
        RUNTIME_SETTINGS.rngSeed = tonumber(data.runtime.rngSeed) or RUNTIME_SETTINGS.rngSeed
        RUNTIME_SETTINGS.fpsOverride = tonumber(data.runtime.fpsOverride) or RUNTIME_SETTINGS.fpsOverride
        RUNTIME_SETTINGS.speedPercent = tonumber(data.runtime.speedPercent) or RUNTIME_SETTINGS.speedPercent
        RUNTIME_SETTINGS.intensityPercent = tonumber(data.runtime.intensityPercent) or RUNTIME_SETTINGS.intensityPercent
        RUNTIME_SETTINGS.sparklePercent = tonumber(data.runtime.sparklePercent) or RUNTIME_SETTINGS.sparklePercent
        RUNTIME_SETTINGS.variationPercent = tonumber(data.runtime.variationPercent) or RUNTIME_SETTINGS.variationPercent
        RUNTIME_SETTINGS.brightnessPercent = tonumber(data.runtime.brightnessPercent) or RUNTIME_SETTINGS.brightnessPercent
    end

    if type(data.layout) == "table" then
        settingsLayout = data.layout
    end
end

local function saveSettings()
    if not fs or not fs.open then return end

    local file = fs.open(SETTINGS_PATH, "w")
    if not file then return end

    file.write(textutils.serialize({
        animation = selectedAnimation,
        scheme = selectedScheme,
        runtime = RUNTIME_SETTINGS,
        layout = settingsLayout,
    }))
    file.close()
end

local function panelWrite(y, text, color)
    local tw, th = term.getSize()
    if y < 1 or y > th then return end

    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.black)
    term.clearLine()
    term.setTextColor(color or colors.white)

    if #text > tw then
        text = text:sub(1, tw)
    end

    term.write(text)
end

local function addButton(x, y, w, label, bg, fg, action)
    local tw, th = term.getSize()
    if y < 1 or y > th or x > tw then return end

    local safeWidth = max(1, min(w, tw - x + 1))

    uiButtons[#uiButtons + 1] = {
        x1 = x,
        y1 = y,
        x2 = x + safeWidth - 1,
        y2 = y,
        action = action,
    }

    term.setCursorPos(x, y)
    term.setBackgroundColor(bg)
    term.setTextColor(fg)

    local text = label
    if #text < safeWidth then
        text = text .. string.rep(" ", safeWidth - #text)
    elseif #text > safeWidth then
        text = text:sub(1, safeWidth)
    end

    term.write(text)
    term.setBackgroundColor(colors.black)
end

-- ###############
-- # UI Helpers #
-- ###############

local getVisibleListCount

local function panelCenter(y, text, color)
    local tw, th = term.getSize()
    if y < 1 or y > th then return end

    text = tostring(text or "")
    if #text > tw then
        text = text:sub(1, tw)
    end

    term.setCursorPos(max(1, floor((tw - #text) / 2) + 1), y)
    term.setBackgroundColor(colors.black)
    term.setTextColor(color or colors.white)
    term.write(text)
end

local function writeKeyValue(y, label, value, color)
    panelWrite(y, string.format("%-10s %s", label .. ":", tostring(value or "")), color or colors.white)
end

local function drawStatusBar(message)
    if message ~= nil then
        statusMessage = tostring(message)
    end

    if statusMessage == "" then return end

    local _, th = term.getSize()
    panelWrite(th, statusMessage, colors.lightGray)
end

local function drawListPage(options)
    local visibleCount = getVisibleListCount()
    local maxScroll = max(0, #options.items - visibleCount)
    listScroll[options.scrollKey] = clampValue(listScroll[options.scrollKey] or 0, 0, maxScroll)

    local startIndex = listScroll[options.scrollKey] + 1
    local endIndex = min(#options.items, startIndex + visibleCount - 1)

    addButton(43, 5, 4, "^", colors.gray, colors.white, { type = "scroll", page = options.page, delta = -1 })
    addButton(43, 5 + visibleCount - 1, 4, "v", colors.gray, colors.white, { type = "scroll", page = options.page, delta = 1 })

    local row = 0
    for index = startIndex, endIndex do
        local id = options.items[index]
        local active = id == options.selectedId
        local label = options.getLabel(index, id)
        addButton(
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

    panelWrite(15, string.format("Showing %d-%d of %d", startIndex, endIndex, #options.items), colors.lightGray)
    panelWrite(16, options.currentText, options.currentColor or colors.cyan)
end

local function drawAdjustRow(y, label, key, step)
    panelWrite(y, string.format("%-6s %3d%%", label, RUNTIME_SETTINGS[key]), colors.white)
    addButton(15, y, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = key, delta = -step })
    addButton(19, y, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = key, delta = step })
end

getVisibleListCount = function()
    local _, th = term.getSize()
    return max(4, min(8, th - 11))
end

local function getMonitorLetter(index)
    return string.char(64 + ((index - 1) % 26) + 1)
end

local function centerWriteOnMonitor(tile, y, text, fg, bg)
    if y < 1 or y > tile.height then return end

    if #text > tile.width then
        text = text:sub(1, tile.width)
    end

    local x = max(1, floor((tile.width - #text) / 2) + 1)
    tile.device.setCursorPos(x, y)
    tile.device.setBackgroundColor(bg)
    tile.device.setTextColor(fg)
    tile.device.write(text)
end

local function drawLayoutMiniMap(originX, originY, mapWidth, mapHeight)
    paintutils.drawBox(originX, originY, originX + mapWidth - 1, originY + mapHeight - 1, colors.lightGray)

    if #monitorTiles == 0 then
        term.setCursorPos(originX + 2, originY + 2)
        term.setTextColor(colors.gray)
        term.write("No monitors")
        return
    end

    local minX, minY = math.huge, math.huge
    local maxXBound, maxYBound = 1, 1

    for _, tile in ipairs(monitorTiles) do
        minX = math.min(minX, tile.x)
        minY = math.min(minY, tile.y)
        maxXBound = math.max(maxXBound, tile.x + tile.width - 1)
        maxYBound = math.max(maxYBound, tile.y + tile.height - 1)
    end

    local spanX = math.max(1, maxXBound - minX + 1)
    local spanY = math.max(1, maxYBound - minY + 1)
    local usableW = math.max(6, mapWidth - 2)
    local usableH = math.max(4, mapHeight - 2)

    for index, tile in ipairs(monitorTiles) do
        local sx = originX + 1 + floor(((tile.x - minX) / spanX) * (usableW - 4))
        local sy = originY + 1 + floor(((tile.y - minY) / spanY) * (usableH - 2))
        local sw = max(4, floor((tile.width / spanX) * usableW + 0.5))
        local sh = max(2, floor((tile.height / spanY) * usableH + 0.5))
        local ex = math.min(originX + mapWidth - 2, sx + sw - 1)
        local ey = math.min(originY + mapHeight - 2, sy + sh - 1)
        local active = index == selectedMonitorIndex

        paintutils.drawFilledBox(sx, sy, ex, ey, active and colors.lightBlue or colors.gray)
        paintutils.drawBox(sx, sy, ex, ey, active and colors.white or colors.lightGray)

        local label = tile.label or getMonitorLetter(index)
        term.setCursorPos(math.min(ex, sx + 1), math.floor((sy + ey) / 2))
        term.setBackgroundColor(active and colors.lightBlue or colors.gray)
        term.setTextColor(active and colors.black or colors.white)
        term.write(label)
        term.setBackgroundColor(colors.black)
    end
end

-- ###############
-- # Interface #
-- ###############

local function getPageLabel(id)
    for _, tab in ipairs(PAGE_TABS) do
        if tab.id == id then
            return tab.label
        end
    end

    return tostring(id or "Page")
end

local function drawPageTabs()
    local x = 1
    for _, tab in ipairs(PAGE_TABS) do
        local active = currentPage == tab.id
        addButton(x, 1, tab.width, tab.label, active and tab.active or colors.gray, active and colors.black or colors.white, { type = "page", id = tab.id })
        x = x + tab.width + 1
    end
end

local function drawHomePage(current, scheme, attached)
    panelCenter(3, CONFIG.title, colors.pink)
    panelCenter(4, "v" .. CONFIG.version .. "  •  " .. CONFIG.subtitle, colors.lightBlue)
    writeKeyValue(6, "Animation", current.label, colors.white)
    writeKeyValue(7, "Theme", scheme.label, colors.white)
    writeKeyValue(8, "Display", attached and string.format("%d monitor(s)  %dx%d  @%dfps", #monitorTiles, width, height, fps) or "Waiting for advanced monitors", attached and colors.green or colors.pink)
    writeKeyValue(9, "Preview", showLayoutPreview and "Enabled" or "Live render", showLayoutPreview and colors.cyan or colors.lightGray)
    panelWrite(11, "Use the tabs above to switch sections.", colors.lightGray)
    panelWrite(13, "Built for persistent multi-monitor cyberpunk visuals.", colors.gray)
end

local function drawAnimationsPage(current)
    panelCenter(3, "Animations", colors.white)
    drawListPage({
        page = "animations",
        scrollKey = "animations",
        items = ANIMATION_ORDER,
        selectedId = selectedAnimation,
        actionType = "animation",
        activeBg = colors.pink,
        activeFg = colors.black,
        getLabel = function(index, id)
            return string.format("%02d  %s", index, ANIMATIONS[id].label)
        end,
        currentText = "Current: " .. current.label,
        currentColor = colors.cyan,
    })
end

local function drawColorsPage(scheme)
    panelCenter(3, "Themes", colors.white)
    drawListPage({
        page = "colors",
        scrollKey = "colors",
        items = COLOR_SCHEME_ORDER,
        selectedId = selectedScheme,
        actionType = "scheme",
        activeBg = colors.cyan,
        activeFg = colors.black,
        getLabel = function(_, id)
            return COLOR_SCHEMES[id].label
        end,
        currentText = "Current: " .. scheme.label,
        currentColor = colors.cyan,
    })
end

local function drawSettingsPage()
    panelCenter(3, "Settings", colors.white)

    writeKeyValue(5, "Seed", RUNTIME_SETTINGS.rngSeed, colors.white)
    addButton(15, 5, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = -1 })
    addButton(19, 5, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "rngSeed", delta = 1 })
    addButton(23, 5, 7, "Random", colors.purple, colors.white, { type = "seed_random" })

    writeKeyValue(6, "FPS", RUNTIME_SETTINGS.fpsOverride == 0 and "Auto" or tostring(RUNTIME_SETTINGS.fpsOverride), colors.white)
    addButton(15, 6, 3, "-", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = -1 })
    addButton(19, 6, 3, "+", colors.gray, colors.white, { type = "setting_adjust", key = "fpsOverride", delta = 1 })
    addButton(23, 6, 7, "Auto", colors.blue, colors.white, { type = "fps_auto" })

    drawAdjustRow(8, "Speed", "speedPercent", 5)
    drawAdjustRow(9, "Power", "intensityPercent", 5)
    drawAdjustRow(10, "Spark", "sparklePercent", 5)
    drawAdjustRow(11, "Varia", "variationPercent", 5)
    drawAdjustRow(12, "Light", "brightnessPercent", 5)

    addButton(31, 8, 8, "Cinema", colors.gray, colors.white, { type = "preset", id = "cinematic" })
    addButton(40, 8, 8, "Chaos", colors.gray, colors.white, { type = "preset", id = "chaotic" })
    addButton(31, 10, 8, "Calm", colors.gray, colors.white, { type = "preset", id = "calm" })
    addButton(40, 10, 8, "Storm", colors.gray, colors.white, { type = "preset", id = "storm" })
    addButton(35, 12, 8, "Club", colors.gray, colors.white, { type = "preset", id = "club" })
end

local function drawLayoutPage(attached, selectedTile)
    panelCenter(3, "Layout", colors.white)
    panelWrite(4, attached and "Arrange and preview the monitor wall." or "Connect advanced monitors to build the wall.", attached and colors.lightBlue or colors.pink)

    drawLayoutMiniMap(2, 6, 22, 8)

    addButton(26, 6, 10, "Prev", colors.blue, colors.white, { type = "cycle" })
    addButton(37, 6, 10, showLayoutPreview and "Hide" or "Show", showLayoutPreview and colors.pink or colors.gray, showLayoutPreview and colors.black or colors.white, { type = "preview" })
    addButton(26, 8, 10, "Auto row", colors.purple, colors.white, { type = "auto_row" })
    addButton(37, 8, 10, "Auto col", colors.purple, colors.white, { type = "auto_column" })
    addButton(26, 9, 10, "Reset", colors.orange, colors.white, { type = "reset" })
    addButton(37, 9, 10, "Invert", colors.lightBlue, colors.black, { type = "invert" })
    addButton(26, 10, 10, "Rescan", colors.cyan, colors.black, { type = "rescan" })
    addButton(31, 12, 5, "^", colors.gray, colors.white, { type = "move", dx = 0, dy = -1 })
    addButton(26, 13, 5, "<", colors.gray, colors.white, { type = "move", dx = -1, dy = 0 })
    addButton(31, 13, 5, "v", colors.gray, colors.white, { type = "move", dx = 0, dy = 1 })
    addButton(36, 13, 5, ">", colors.gray, colors.white, { type = "move", dx = 1, dy = 0 })
    addButton(38, 18, 8, "Quit", colors.red, colors.white, { type = "quit" })

    if selectedTile then
        writeKeyValue(15, "Selected", string.format("%s (%s)", selectedTile.name, selectedTile.label or "?"), colors.white)
        writeKeyValue(16, "Position", string.format("(%d,%d)  %dx%d", selectedTile.x, selectedTile.y, selectedTile.width, selectedTile.height), colors.lightGray)
    else
        writeKeyValue(15, "Selected", "None", colors.gray)
        writeKeyValue(16, "Position", "No monitor wall detected", colors.lightGray)
    end

    writeKeyValue(17, "Canvas", attached and string.format("%dx%d  across %d monitor(s)", width, height, #monitorTiles) or "--", attached and colors.green or colors.gray)
    writeKeyValue(18, "Preview", showLayoutPreview and "Enabled" or "Disabled", showLayoutPreview and colors.cyan or colors.lightGray)
end

local function drawControlPanel(message)
    applyPalette(term)
    term.setBackgroundColor(colors.black)
    term.clear()
    uiButtons = {}

    local current = ANIMATIONS[selectedAnimation] or ANIMATIONS.energy
    local scheme = COLOR_SCHEMES[selectedScheme] or COLOR_SCHEMES.neon
    local attached = #monitorTiles > 0
    local selectedTile = monitorTiles[selectedMonitorIndex]

    drawPageTabs()

    if currentPage == "home" then
        drawHomePage(current, scheme, attached)
    elseif currentPage == "animations" then
        drawAnimationsPage(current)
    elseif currentPage == "colors" then
        drawColorsPage(scheme)
    elseif currentPage == "settings" then
        drawSettingsPage()
    elseif currentPage == "layout" then
        drawLayoutPage(attached, selectedTile)
    end

    drawStatusBar(message)
end

-- ###############
-- # Monitor Wall #
-- ###############

local function clearDisplayWall()
    for _, tile in ipairs(monitorTiles) do
        tile.device.setBackgroundColor(colors.black)
        tile.device.clear()
    end
end

local function drawLetterPreviewWall()
    clearDisplayWall()

    for index, tile in ipairs(monitorTiles) do
        local isSelected = index == selectedMonitorIndex
        local bg = isSelected and colors.gray or colors.black
        local fg = isSelected and colors.white or colors.cyan
        local label = tile.label or getMonitorLetter(index)

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

local function rebuildLayout()
    if #monitorTiles == 0 then
        width, height = 0, 0
        fps = 12
        frameTime = 1 / fps
        previewDirty = true
        return
    end

    width, height = 0, 0
    local autoX = 1
    local minX, minY = math.huge, math.huge

    for _, tile in ipairs(monitorTiles) do
        pcall(function()
            tile.device.setTextScale(CONFIG.preferredScale)
        end)

        applyPalette(tile.device)
        tile.width, tile.height = tile.device.getSize()

        local saved = settingsLayout[tile.name]
        if type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number" then
            tile.x = max(1, floor(saved.x))
            tile.y = max(1, floor(saved.y))
        else
            tile.x = autoX
            tile.y = 1
            settingsLayout[tile.name] = { x = tile.x, y = tile.y }
            autoX = autoX + tile.width
        end

        minX = math.min(minX, tile.x)
        minY = math.min(minY, tile.y)
    end

    local shiftX = (minX == math.huge) and 0 or (minX - 1)
    local shiftY = (minY == math.huge) and 0 or (minY - 1)

    rowMinX, rowMaxX = {}, {}
    colMinY, colMaxY = {}, {}

    for _, tile in ipairs(monitorTiles) do
        tile.x = max(1, tile.x - shiftX)
        tile.y = max(1, tile.y - shiftY)
        settingsLayout[tile.name] = { x = tile.x, y = tile.y }

        local tileMaxX = tile.x + tile.width - 1
        local tileMaxY = tile.y + tile.height - 1

        width = max(width, tileMaxX)
        height = max(height, tileMaxY)

        for row = tile.y, tileMaxY do
            rowMinX[row] = rowMinX[row] and math.min(rowMinX[row], tile.x) or tile.x
            rowMaxX[row] = rowMaxX[row] and math.max(rowMaxX[row], tileMaxX) or tileMaxX
        end

        for column = tile.x, tileMaxX do
            colMinY[column] = colMinY[column] and math.min(colMinY[column], tile.y) or tile.y
            colMaxY[column] = colMaxY[column] and math.max(colMaxY[column], tileMaxY) or tileMaxY
        end
    end

    local cx = (width + 1) * 0.5
    local cy = (height + 1) * 0.5
    local span = max(1, max(width, height) * 0.5)

    for x = 1, width do
        xNorm[x] = (x - cx) / span
    end

    for y = 1, height do
        yNorm[y] = (y - cy) / span
    end

    adaptiveXGrid, adaptiveYGrid = {}, {}
    for y = 1, height do
        local rowX, rowY = {}, {}
        local minRow = rowMinX[y] or 1
        local maxRow = rowMaxX[y] or width
        local rowMid = (minRow + maxRow) * 0.5
        local rowScale = max(1, (maxRow - minRow + 1) * 0.5)

        for x = 1, width do
            local minCol = colMinY[x] or 1
            local maxCol = colMaxY[x] or height
            local colMid = (minCol + maxCol) * 0.5
            local colScale = max(1, (maxCol - minCol + 1) * 0.5)
            local localNx = (x - rowMid) / rowScale
            local localNy = (y - colMid) / colScale

            rowX[x] = (xNorm[x] or 0) * 0.30 + localNx * 0.70
            rowY[x] = (yNorm[y] or 0) * 0.30 + localNy * 0.70
        end

        adaptiveXGrid[y] = rowX
        adaptiveYGrid[y] = rowY
    end

    local cells = width * height
    renderCellCount = cells
    renderStep = 1

    local autoFps = max(CONFIG.minFps, min(CONFIG.maxFps, floor(19 - cells / 450)))
    if (RUNTIME_SETTINGS.fpsOverride or 0) > 0 then
        fps = clampValue(RUNTIME_SETTINGS.fpsOverride, CONFIG.minFps, 24)
    else
        fps = min(autoFps, 24)
    end
    frameTime = 1 / max(1, min(fps, 24))

    clearDisplayWall()
    previewDirty = true
end

local function setAnimation(id, persist)
    if not ANIMATIONS[id] then return false end

    selectedAnimation = id
    if persist then
        saveSettings()
    end

    drawControlPanel("Saved animation: " .. ANIMATIONS[id].label)
    return true
end

local function setColorScheme(id, persist)
    if not COLOR_SCHEMES[id] then return false end

    selectedScheme = id
    applyPalette(term)
    clearDisplayWall()
    rebuildLayout()
    previewDirty = true

    if persist then
        saveSettings()
    end

    drawControlPanel("Saved color scheme: " .. COLOR_SCHEMES[id].label)
    return true
end

local function adjustRuntimeSetting(key, delta)
    if key == "rngSeed" then
        RUNTIME_SETTINGS.rngSeed = clampValue((RUNTIME_SETTINGS.rngSeed or 1337) + delta, 1, 999999)
    elseif key == "fpsOverride" then
        RUNTIME_SETTINGS.fpsOverride = clampValue((RUNTIME_SETTINGS.fpsOverride or 0) + delta, 0, 30)
    elseif key == "speedPercent" then
        RUNTIME_SETTINGS.speedPercent = clampValue((RUNTIME_SETTINGS.speedPercent or 100) + delta, 50, 200)
    elseif key == "intensityPercent" then
        RUNTIME_SETTINGS.intensityPercent = clampValue((RUNTIME_SETTINGS.intensityPercent or 100) + delta, 50, 200)
    elseif key == "sparklePercent" then
        RUNTIME_SETTINGS.sparklePercent = clampValue((RUNTIME_SETTINGS.sparklePercent or 100) + delta, 50, 200)
    elseif key == "variationPercent" then
        RUNTIME_SETTINGS.variationPercent = clampValue((RUNTIME_SETTINGS.variationPercent or 100) + delta, 0, 200)
    elseif key == "brightnessPercent" then
        RUNTIME_SETTINGS.brightnessPercent = clampValue((RUNTIME_SETTINGS.brightnessPercent or 100) + delta, 35, 150)
    end

    updateDerivedTuning()
    rebuildLayout()
    saveSettings()
    drawControlPanel("Updated setting: " .. key)
    return true
end

local function randomizeSeed()
    RUNTIME_SETTINGS.rngSeed = math.random(1, 999999)
    updateDerivedTuning()
    rebuildLayout()
    saveSettings()
    drawControlPanel("Randomized RNG seed to " .. RUNTIME_SETTINGS.rngSeed)
    return true
end

local function setFpsAuto()
    RUNTIME_SETTINGS.fpsOverride = 0
    updateDerivedTuning()
    rebuildLayout()
    saveSettings()
    drawControlPanel("FPS set back to Auto.")
    return true
end

local function applyRuntimePreset(id)
    local preset = RUNTIME_PRESETS[id]
    if not preset then return false end

    RUNTIME_SETTINGS.speedPercent = preset.speedPercent
    RUNTIME_SETTINGS.intensityPercent = preset.intensityPercent
    RUNTIME_SETTINGS.sparklePercent = preset.sparklePercent
    RUNTIME_SETTINGS.variationPercent = preset.variationPercent
    RUNTIME_SETTINGS.fpsOverride = preset.fpsOverride

    updateDerivedTuning()
    rebuildLayout()
    saveSettings()
    drawControlPanel("Applied preset: " .. preset.label)
    return true
end

local function cycleSelectedMonitor()
    if #monitorTiles == 0 then return end
    selectedMonitorIndex = (selectedMonitorIndex % #monitorTiles) + 1
    previewDirty = true
    drawControlPanel("Selected monitor: " .. monitorTiles[selectedMonitorIndex].name)
end

local function moveSelectedMonitor(dx, dy)
    local tile = monitorTiles[selectedMonitorIndex]
    if not tile then return end

    local stepX = tile.width
    local stepY = tile.height
    local newX = max(1, tile.x + dx * stepX)
    local newY = max(1, tile.y + dy * stepY)

    settingsLayout[tile.name] = { x = newX, y = newY }

    rebuildLayout()
    previewDirty = true
    saveSettings()
    drawControlPanel(string.format("Moved %s by one block to (%d,%d)", tile.name, newX, newY))
end

local function autoArrangeMonitorsRow()
    local cursorX = 1
    for _, tile in ipairs(monitorTiles) do
        settingsLayout[tile.name] = { x = cursorX, y = 1 }
        cursorX = cursorX + tile.width
    end

    rebuildLayout()
    previewDirty = true
    saveSettings()
    drawControlPanel("Auto-arranged monitor wall left-to-right.")
end

local function autoArrangeMonitorsColumn()
    local cursorY = 1
    for index = #monitorTiles, 1, -1 do
        local tile = monitorTiles[index]
        settingsLayout[tile.name] = { x = 1, y = cursorY }
        cursorY = cursorY + tile.height
    end

    rebuildLayout()
    previewDirty = true
    saveSettings()
    drawControlPanel("Auto-arranged monitor wall bottom-to-top.")
end

local function invertMonitorLayout()
    if #monitorTiles <= 1 then return end

    local positions = {}
    for index, tile in ipairs(monitorTiles) do
        positions[index] = { x = tile.x, y = tile.y }
    end

    for index, tile in ipairs(monitorTiles) do
        local mirrored = positions[#positions - index + 1]
        settingsLayout[tile.name] = { x = mirrored.x, y = mirrored.y }
    end

    rebuildLayout()
    previewDirty = true
    saveSettings()
    drawControlPanel("Inverted monitor order.")
end

local function autoArrangeMonitorsSmart(silent)
    if #monitorTiles == 0 then return end

    local count = #monitorTiles
    local maxTileWidth, maxTileHeight = 1, 1
    for _, tile in ipairs(monitorTiles) do
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

    for index, tile in ipairs(monitorTiles) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        settingsLayout[tile.name] = {
            x = 1 + column * maxTileWidth,
            y = 1 + row * maxTileHeight,
        }
    end

    rebuildLayout()
    previewDirty = true
    saveSettings()

    if not silent then
        drawControlPanel("Auto-packed large monitor wall into a smart grid.")
    end
end

local function resetLayout()
    selectedMonitorIndex = 1
    settingsLayout = {}
    showLayoutPreview = true

    if bindMonitor then
        bindMonitor()
    end

    if #monitorTiles >= 4 then
        autoArrangeMonitorsSmart(true)
        drawControlPanel("Layout reset and auto-packed for the larger wall.")
    else
        autoArrangeMonitorsRow()
    end
end

local function toggleLayoutPreview()
    showLayoutPreview = not showLayoutPreview
    previewDirty = true

    if showLayoutPreview then
        drawLetterPreviewWall()
        drawControlPanel("Letter preview enabled for easier alignment.")
    else
        clearDisplayWall()
        drawControlPanel("Letter preview disabled.")
    end
end

bindMonitor = function()
    local names = {}
    local missingLayout = false

    if #requestedMonitors > 0 then
        for _, name in ipairs(requestedMonitors) do
            names[#names + 1] = name
        end
    else
        for _, name in ipairs(peripheral.getNames()) do
            names[#names + 1] = name
        end
        table.sort(names)
    end

    monitorTiles = {}
    for _, name in ipairs(names) do
        if peripheral.getType(name) == "monitor" then
            local wrapped = peripheral.wrap(name)
            if wrapped and wrapped.isColor and wrapped.isColor() then
                if type(settingsLayout[name]) ~= "table" then
                    missingLayout = true
                end

                monitorTiles[#monitorTiles + 1] = {
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

    if #monitorTiles == 0 then
        monitorName = nil
        width, height = 0, 0
        drawControlPanel("Waiting for advanced monitors...")
        return false
    end

    table.sort(monitorTiles, function(a, b)
        return a.name < b.name
    end)

    for index, tile in ipairs(monitorTiles) do
        tile.label = getMonitorLetter(index)
    end

    if selectedMonitorIndex > #monitorTiles then
        selectedMonitorIndex = 1
    end

    monitorName = (#monitorTiles == 1) and monitorTiles[1].name or (tostring(#monitorTiles) .. " monitors")
    rebuildLayout()

    if missingLayout and #monitorTiles >= 4 then
        autoArrangeMonitorsSmart(true)
    end

    saveSettings()
    drawControlPanel("Output wall: " .. monitorName .. string.format("  (%dx%d @ %dfps)", width, height, fps))
    return true
end

-- ###############
-- # Animation Renderers #
-- ###############

local function shadeCell(energy, sparkle)
    local paletteSize = #SHADE_HEX

    energy = clamp01(energy * (derivedTuning.energy or 1) + (derivedTuning.bias or 0))
    sparkle = (sparkle or 0) * (derivedTuning.sparkle or 1)

    local idx = floor(energy * (paletteSize - 1) + 1.5)

    if idx < 1 then idx = 1 end
    if idx > paletteSize then idx = paletteSize end

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

local function setRenderSample(x, ch, fg, bg)
    local sampleEnd = min(width, x + renderStep - 1)
    for sampleX = x, sampleEnd do
        rowChars[sampleX], rowFg[sampleX], rowBg[sampleX] = ch, fg, bg
    end
end

local function blitPreparedRow(y)
    local chars = table.concat(rowChars, "", 1, width)
    local fg = table.concat(rowFg, "", 1, width)
    local bg = table.concat(rowBg, "", 1, width)

    for _, tile in ipairs(monitorTiles) do
        local localY = y - tile.y + 1
        if localY >= 1 and localY <= tile.height then
            local startX = tile.x
            local endX = tile.x + tile.width - 1

            tile.device.setCursorPos(1, localY)
            tile.device.blit(chars:sub(startX, endX), fg:sub(startX, endX), bg:sub(startX, endX))
        end
    end
end

local function renderEnergyFlow(t)
    local t1 = t * 1.35
    local ax = sin(t1 * 0.80) * 0.58
    local ay = cos(t1 * 1.15) * 0.34
    local bx = cos(t1 * 0.55 + 1.40) * 0.42
    local by = sin(t1 * 0.95 + 0.80) * 0.52
    local scanY = ((t1 * 3.2) % (height + 8)) - 4

    for y = 1, height do
        local scanBoost = 0.10 / (1 + (y - scanY) * (y - scanY) * 0.9)

        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)

            local flowA = sin(nx * 11.0 + t1 * 2.8 + sin(ny * 4.0 - t1 * 1.2) * 2.2)
            local flowB = cos((nx * 5.5 - ny * 8.0) * 2.4 - t1 * 3.2)
            local flowC = sin((nx * nx * 13.0 + ny * ny * 17.0) * 5.2 - t1 * 4.6)
            local stream = sin((nx + ny * 0.35) * 18.0 - t1 * 4.8 + sin(nx * 6.0 + t1))

            local dx1 = nx - ax
            local dy1 = ny - ay
            local dx2 = nx - bx
            local dy2 = ny - by

            local nodeGlow = 0.90 / (1 + 18 * (dx1 * dx1 + dy1 * dy1))
                           + 0.72 / (1 + 22 * (dx2 * dx2 + dy2 * dy2))

            local vignette = max(0, 1 - (nx * nx * 0.68 + ny * ny * 1.10))
            local energy = 0.36
                + flowA * 0.13
                + flowB * 0.11
                + flowC * 0.10
                + stream * 0.12
                + nodeGlow * 0.55
                + scanBoost

            energy = clamp01(energy * (0.55 + vignette * 0.62))

            local sparkle = sin(t1 * 7.0 + nx * 21.0 - ny * 17.0)
                          + cos(t1 * 5.0 + nx * 13.0 + ny * 19.0)

            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

local function renderPlasmaDrift(t)
    local t1 = t * 1.25

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local ring = nx * nx + ny * ny

            local plasma = sin(nx * 9.5 + t1 * 2.1)
                         + cos(ny * 11.5 - t1 * 2.8)
                         + sin((nx + ny) * 8.0 + t1 * 1.7)
                         + cos(ring * 26.0 - t1 * 5.2)

            local tunnel = 0.95 / (1 + ring * 10.5)
            local drift = sin((nx * nx * 9.0 - ny * 13.0) - t1 * 3.6)
            local energy = 0.28 + plasma * 0.10 + drift * 0.12 + tunnel * 0.72

            local sparkle = sin(t1 * 6.5 + nx * 23.0) + cos(t1 * 4.2 - ny * 18.0)
            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

local function renderPulseLattice(t)
    local t1 = t * 1.55
    local px = sin(t1 * 0.9) * 0.45
    local py = cos(t1 * 1.2) * 0.38

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local gx = abs(sin(nx * 13.0 + t1 * 2.4))
            local gy = abs(cos(ny * 11.0 - t1 * 2.0))
            local grid = gx * gx * gx * gx * 0.42 + gy * gy * gy * gy * 0.42

            local pulse = sin((nx * nx + ny * ny) * 42.0 - t1 * 7.0)
            local diagonal = cos((nx - ny * 0.8) * 16.0 + t1 * 3.5)

            local dx = nx - px
            local dy = ny - py
            local core = 1.05 / (1 + 20 * (dx * dx + dy * dy))

            local energy = 0.18 + grid + pulse * 0.14 + diagonal * 0.08 + core * 0.60
            local sparkle = sin(nx * 17.0 + t1 * 7.8) + cos(ny * 21.0 - t1 * 5.5)

            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

local function renderStormLightning(t)
    local chaos = derivedTuning.chaos or 1
    local warp = derivedTuning.warp or 1
    local jitter = derivedTuning.jitter or 0
    local t1 = t * (1.8 + chaos * 0.22)
    local columnBias = min(2.8, max(1.0, height / max(1, width)))
    local boltA = sin(t1 * (1.6 + chaos * 0.25)) * ((0.26 + jitter) / columnBias)
    local boltB = cos(t1 * (1.0 + chaos * 0.20) + 1.4) * ((0.22 - jitter * 0.4) / columnBias)
    local pulse = 0.5 + 0.5 * sin(t1 * (5.5 + chaos))

    for y = 1, height do
        local ny = yNorm[y] or 0
        local spine = sin(ny * ((8.0 + columnBias) * warp) + t1 * 2.2) * ((0.18 + jitter * 0.4) / columnBias)
                    + cos(ny * ((13.0 + columnBias * 1.5) * warp) - t1 * 3.4) * ((0.10 + abs(jitter) * 0.2) / columnBias)
        local branch = sin(ny * ((20.0 + columnBias * 2.0) * warp) - t1 * (5.2 + chaos * 0.5)) * ((0.12 + jitter * 0.3) / columnBias)

        for x = 1, width, renderStep do
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
            setRenderSample(x, shadeCell(energy, sparkle + strike * (1 + chaos * 0.2)))
        end

        blitPreparedRow(y)
    end
end

local function renderArcStorm(t)
    local chaos = derivedTuning.chaos or 1
    local warp = derivedTuning.warp or 1
    local jitter = derivedTuning.jitter or 0
    local t1 = t * (1.9 + chaos * 0.24)
    local columnBias = min(2.8, max(1.0, height / max(1, width)))
    local boltA = sin(t1 * (1.5 + chaos * 0.18)) * ((0.20 + jitter * 0.2) / columnBias)
    local boltB = cos(t1 * (1.1 + chaos * 0.16) + 1.4) * ((0.18 - jitter * 0.15) / columnBias)
    local boltC = sin(t1 * (0.9 + chaos * 0.12) + 2.1) * ((0.16 + abs(jitter) * 0.1) / columnBias)
    local pulse = 0.5 + 0.5 * sin(t1 * (4.8 + chaos * 0.4))

    for y = 1, height do
        local ny = yNorm[y] or 0
        local spine = sin(ny * ((8.0 + columnBias) * warp) + t1 * 2.2) * ((0.13 + jitter * 0.2) / columnBias)
                    + cos(ny * ((14.5 + columnBias) * warp) - t1 * 3.1) * ((0.08 + abs(jitter) * 0.1) / columnBias)
        local branchA = sin(ny * ((23.0 + columnBias * 2.0) * warp) - t1 * (5.4 + chaos * 0.4)) * ((0.10 + jitter * 0.2) / columnBias)
        local branchB = cos(ny * ((31.0 + columnBias * 2.8) * warp) + t1 * (6.2 + chaos * 0.5)) * ((0.07 + abs(jitter) * 0.1) / columnBias)

        for x = 1, width, renderStep do
            local nx, localNy = getAdaptiveNorm(x, y)

            local distMain = abs(nx - (boltA + spine + sin(localNy * 11.0 + t1) * 0.025 * chaos))
            local distBranch1 = abs(nx - (boltB - spine * 0.6 + branchA + cos(localNy * 15.0 - t1) * 0.018 * chaos))
            local distBranch2 = abs(nx - (boltC + spine * 0.45 + branchB - sin(localNy * 19.0 + t1 * 0.7) * 0.015 * chaos))

            local strike = 1.05 / (1 + distMain * (42.0 + columnBias * 5.0 + chaos * 6.0))
                         + 0.78 / (1 + distBranch1 * (58.0 + columnBias * 5.0 + chaos * 8.0))
                         + 0.62 / (1 + distBranch2 * (76.0 + columnBias * 6.0 + chaos * 10.0))

            local micro = abs(sin((nx * 52.0 + localNy * 17.0) * warp - t1 * (10.0 + chaos))) * 0.12
                        + abs(cos((nx * 37.0 - localNy * 23.0) * warp + t1 * (8.0 + chaos * 0.6))) * 0.09
            local ripples = sin((nx * (18.0 * warp) - localNy * 7.0) - t1 * (7.2 + chaos * 0.4)) * 0.08
                          + cos((nx * 11.0 + localNy * (13.0 * warp)) + t1 * (5.2 + chaos * 0.3)) * 0.06

            local glow = max(0, 1 - (nx * nx * 0.90 + localNy * localNy * 0.78)) * (0.12 + chaos * 0.02)
            local energy = 0.08 + strike * (0.42 + pulse * 0.20) + micro + ripples + glow

            local sparkle = sin(t1 * (11.5 + chaos) + nx * 33.0) + cos(t1 * (8.4 + chaos * 0.6) - localNy * 27.0)
            setRenderSample(x, shadeCell(energy, sparkle + strike * (0.9 + chaos * 0.12)))
        end

        blitPreparedRow(y)
    end
end

local function renderLightningTube(t)
    local chaos = derivedTuning.chaos or 1
    local warp = derivedTuning.warp or 1
    local jitter = derivedTuning.jitter or 0
    local t1 = t * (1.85 + chaos * 0.22)
    local aspect = min(2.8, max(1.0, height / max(1, width)))
    local pulse = 0.5 + 0.5 * sin(t1 * (4.6 + chaos * 0.35))

    for y = 1, height do
        local ny = yNorm[y] or 0
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

        for x = 1, width, renderStep do
            local nx, localNy = getAdaptiveNorm(x, y)
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

            setRenderSample(x, shadeCell(energy, sparkle + strike))
        end

        blitPreparedRow(y)
    end
end

local function renderRaveWave(t)
    local t1 = t * 2.1
    local beat = 0.5 + 0.5 * sin(t1 * 3.5)

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local ribbonA = sin(nx * 14.0 + t1 * 4.8 + sin(ny * 7.0 - t1 * 1.5) * 2.5)
            local ribbonB = cos(ny * 16.0 - t1 * 3.9 + cos(nx * 5.5 + t1) * 2.0)
            local tunnel = sin((nx + ny) * 10.0 + t1 * 2.8) + cos((nx - ny * 0.7) * 13.0 - t1 * 4.4)
            local strobe = sin((nx * nx + ny * ny) * 60.0 - t1 * 10.0)

            local energy = 0.28
                + ribbonA * 0.16
                + ribbonB * 0.16
                + tunnel * 0.10
                + strobe * 0.08
                + beat * 0.24

            local sparkle = sin(t1 * 13.0 + nx * 31.0) + cos(t1 * 9.0 + ny * 29.0) + beat
            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

local function renderAuroraVeil(t)
    local t1 = t * 1.45

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local curtainA = sin(ny * 12.0 - t1 * 2.4 + sin(nx * 5.0 + t1) * 2.1)
            local curtainB = cos(nx * 7.5 + t1 * 1.7 + cos(ny * 4.5 - t1) * 1.8)
            local shimmer = sin((nx + ny * 0.6) * 16.0 + t1 * 4.1)
            local skyGlow = max(0, 1 - abs(nx) * 1.15) * 0.24

            local energy = 0.24
                + curtainA * 0.18
                + curtainB * 0.14
                + shimmer * 0.10
                + skyGlow

            local sparkle = sin(t1 * 8.0 + nx * 19.0) + cos(t1 * 5.5 - ny * 23.0)
            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

local function renderVortexTunnel(t)
    local t1 = t * 1.75

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local ring = nx * nx + ny * ny
            local spiralA = sin((nx * 10.0 + ny * 9.0) + t1 * 4.0)
            local spiralB = cos((nx * 12.0 - ny * 11.0) - t1 * 3.3)
            local tunnel = sin(ring * 56.0 - t1 * 8.5)
            local core = 1.15 / (1 + ring * 13.0)

            local energy = 0.12
                + spiralA * 0.14
                + spiralB * 0.14
                + tunnel * 0.16
                + core * 0.62

            local sparkle = sin(t1 * 9.0 + nx * 28.0 - ny * 12.0) + cos(t1 * 7.0 + ny * 24.0)
            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

local function renderDataRain(t)
    local chaos = derivedTuning.chaos or 1
    local t1 = t * (2.2 + chaos * 0.18)

    for y = 1, height do
        for x = 1, width, renderStep do
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
            local ch, fg, bg = shadeCell(energy, sparkle + stream)

            if stream > 0.02 then
                local glyphIndex = (floor(t1 * 20 + x * 11 + y * 7) % #MATRIX_GLYPHS) + 1
                ch = MATRIX_GLYPHS[glyphIndex]
                if dist < 1 then
                    ch = MATRIX_GLYPHS[(glyphIndex % #MATRIX_GLYPHS) + 1]
                end
            else
                ch = " "
            end

            setRenderSample(x, ch, fg, bg)
        end

        blitPreparedRow(y)
    end
end

local function renderCircuit(t)
    local chaos = derivedTuning.chaos or 1
    local warp = derivedTuning.warp or 1
    local jitter = derivedTuning.jitter or 0
    local t1 = t * (1.18 + chaos * 0.10)
    local columnBias = min(3.2, max(1.0, height / max(1, width)))
    local boardXScale = 0.95 + columnBias * 0.55
    local boardYScale = 1 / (0.85 + (columnBias - 1) * 0.45)
    local pulse = 0.5 + 0.5 * sin(t1 * (2.0 + chaos * 0.2))

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
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
            local ch, fg, bg = shadeCell(energy, sparkle + strike)

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

            setRenderSample(x, ch, fg, bg)
        end

        blitPreparedRow(y)
    end
end

local function renderIonBeam(t)
    local chaos = derivedTuning.chaos or 1
    local warp = derivedTuning.warp or 1
    local jitter = derivedTuning.jitter or 0
    local t1 = t * (1.9 + chaos * 0.25)
    local aspect = min(2.8, max(1.0, height / max(1, width)))

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local wobble = sin(ny * (5.0 * warp) + t1 * 1.8) * (0.05 + chaos * 0.02)
            local shaftA = 1.20 / (1 + abs(nx - sin(t1 * 0.8 + ny * 3.0 * warp) * ((0.18 + jitter * 0.2) / aspect) - wobble) * (45 + aspect * 10 + chaos * 6))
            local shaftB = 1.05 / (1 + abs(nx - cos(t1 * 1.1 - ny * 2.0 * warp) * ((0.14 + jitter * 0.2) / aspect) + wobble * 0.6) * (55 + aspect * 8 + chaos * 7))
            local surge = sin(ny * (28.0 * warp) - t1 * (8.0 + chaos)) * 0.14 + cos(ny * (16.0 * warp) + t1 * (5.0 + chaos * 0.6)) * 0.10
            local halo = max(0, 1 - abs(nx) * (1.6 + aspect * 0.3)) * (0.18 + chaos * 0.04)
            local energy = 0.10 + shaftA * 0.56 + shaftB * 0.44 + surge + halo
            local sparkle = sin(t1 * (12.0 + chaos) + ny * 34.0) + cos(t1 * (7.0 + chaos * 0.5) + nx * 26.0)
            setRenderSample(x, shadeCell(energy, sparkle + shaftA * (1 + chaos * 0.15)))
        end

        blitPreparedRow(y)
    end
end

local function renderNeoFalls(t)
    local chaos = derivedTuning.chaos or 1
    local warp = derivedTuning.warp or 1
    local jitter = derivedTuning.jitter or 0
    local t1 = t * (1.55 + chaos * 0.18)
    local aspect = min(2.5, max(1.0, height / max(1, width)))

    for y = 1, height do
        for x = 1, width, renderStep do
            local nx, ny = getAdaptiveNorm(x, y)
            local bandA = sin(ny * ((18.0 + aspect * 4.0) * warp) - t1 * (4.8 + chaos * 0.4) + sin(nx * 5.0 + t1 * 0.7) * (1.8 + chaos * 0.3))
            local bandB = cos(ny * ((11.0 + aspect * 3.0) * warp) + t1 * (3.6 + chaos * 0.3) + cos(nx * 6.5 - t1 * 0.5) * (1.6 + chaos * 0.2))
            local seam = abs(sin(nx * (14.0 + chaos * 2.0) + t1 * (1.2 + jitter)))
            local splash = sin((ny * 34.0 - nx * 7.0) * warp - t1 * (7.2 + chaos)) * 0.10
            local fall = max(0, bandA * 0.20 + bandB * 0.18 + seam * 0.26 + splash)
            local energy = 0.14 + fall + max(0, 1 - abs(nx) * 1.3) * (0.16 + chaos * 0.04)
            local sparkle = sin(t1 * (9.5 + chaos) + ny * 24.0) + cos(t1 * (6.0 + chaos * 0.6) - nx * 22.0)
            setRenderSample(x, shadeCell(energy, sparkle))
        end

        blitPreparedRow(y)
    end
end

ANIMATIONS.energy.render = renderEnergyFlow
ANIMATIONS.plasma.render = renderPlasmaDrift
ANIMATIONS.lattice.render = renderPulseLattice
ANIMATIONS.lightning.render = renderStormLightning
ANIMATIONS.rave.render = renderRaveWave
ANIMATIONS.aurora.render = renderAuroraVeil
ANIMATIONS.vortex.render = renderVortexTunnel
ANIMATIONS.matrix.render = renderDataRain
ANIMATIONS.circuit.render = renderCircuit
ANIMATIONS.beam.render = renderIonBeam
ANIMATIONS.tube.render = renderLightningTube
ANIMATIONS.waterfall.render = renderNeoFalls
ANIMATIONS.arcstorm.render = renderArcStorm

local function renderFrame(t)
    if #monitorTiles == 0 then return end

    if showLayoutPreview then
        if previewDirty then
            drawLetterPreviewWall()
            previewDirty = false
        end
        return
    end

    local animation = ANIMATIONS[selectedAnimation] or ANIMATIONS.energy
    renderStep = getRenderStepForAnimation(selectedAnimation)
    animation.render(t * (derivedTuning.speedA or 1) + (derivedTuning.phase or 0))
end

local function handleUiAction(action)
    if not action then return false end

    if action.type == "page" then
        currentPage = action.id or "home"
        drawControlPanel("Opened " .. getPageLabel(currentPage))
        return true
    elseif action.type == "animation" then
        return setAnimation(action.id, true)
    elseif action.type == "scheme" then
        return setColorScheme(action.id, true)
    elseif action.type == "setting_adjust" then
        return adjustRuntimeSetting(action.key, action.delta)
    elseif action.type == "seed_random" then
        return randomizeSeed()
    elseif action.type == "fps_auto" then
        return setFpsAuto()
    elseif action.type == "preset" then
        return applyRuntimePreset(action.id)
    elseif action.type == "scroll" then
        return scrollList(action.page, action.delta)
    elseif action.type == "cycle" then
        cycleSelectedMonitor()
        return true
    elseif action.type == "preview" then
        toggleLayoutPreview()
        return true
    elseif action.type == "reset" then
        resetLayout()
        return true
    elseif action.type == "invert" then
        invertMonitorLayout()
        return true
    elseif action.type == "auto_row" then
        autoArrangeMonitorsRow()
        return true
    elseif action.type == "auto_column" then
        autoArrangeMonitorsColumn()
        return true
    elseif action.type == "move" then
        moveSelectedMonitor(action.dx, action.dy)
        return true
    elseif action.type == "rescan" then
        bindMonitor()
        return true
    elseif action.type == "quit" then
        return "quit"
    end

    return false
end

local function scrollList(page, delta)
    local visibleCount = getVisibleListCount()

    if page == "animations" then
        local maxScroll = max(0, #ANIMATION_ORDER - visibleCount)
        listScroll.animations = clampValue((listScroll.animations or 0) + delta, 0, maxScroll)
    elseif page == "colors" then
        local maxScroll = max(0, #COLOR_SCHEME_ORDER - visibleCount)
        listScroll.colors = clampValue((listScroll.colors or 0) + delta, 0, maxScroll)
    else
        return false
    end

    drawControlPanel(nil)
    return true
end

local function getUiActionAt(x, y)
    for _, button in ipairs(uiButtons) do
        if x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
            return button.action
        end
    end
end

-- ###############
-- # Main Loop #
-- ###############

loadSettings()
updateDerivedTuning()
bindMonitor()
drawControlPanel("Kami-Animator ready")

local keyToAnimation = {
    [keys.one] = "energy",
    [keys.two] = "plasma",
    [keys.three] = "lattice",
    [keys.four] = "lightning",
    [keys.five] = "rave",
    [keys.six] = "aurora",
    [keys.seven] = "vortex",
    [keys.eight] = "matrix",
    [keys.nine] = "beam",
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
            dt = frameTime
        end

        time = time + dt

        local renderCost = 0
        if #monitorTiles > 0 then
            local renderStart = os.clock()
            renderFrame(time)
            renderCost = os.clock() - renderStart
        end

        timer = os.startTimer(max(0, frameTime - renderCost))

    elseif event == "monitor_resize" then
        bindMonitor()

    elseif event == "peripheral" or event == "peripheral_detach" then
        bindMonitor()

    elseif event == "mouse_click" then
        local result = handleUiAction(getUiActionAt(p2, p3))
        if result == "quit" then
            running = false
        end

    elseif event == "mouse_scroll" then
        if currentPage == "animations" or currentPage == "colors" then
            scrollList(currentPage, p1)
        end

    elseif event == "key" then
        if p1 == keys.q then
            running = false
        elseif p1 == keys.r then
            bindMonitor()
        elseif p1 == keys.tab then
            cycleSelectedMonitor()
        elseif p1 == keys.a then
            autoArrangeMonitorsRow()
        elseif p1 == keys.c then
            autoArrangeMonitorsColumn()
        elseif p1 == keys.p then
            toggleLayoutPreview()
        elseif p1 == keys.x then
            resetLayout()
        elseif p1 == keys.left then
            moveSelectedMonitor(-1, 0)
        elseif p1 == keys.right then
            moveSelectedMonitor(1, 0)
        elseif p1 == keys.up then
            moveSelectedMonitor(0, -1)
        elseif p1 == keys.down then
            moveSelectedMonitor(0, 1)
        elseif keyToAnimation[p1] then
            setAnimation(keyToAnimation[p1], true)
        end
    end
end

if #monitorTiles > 0 then
    clearDisplayWall()
end

drawControlPanel("Animation stopped.")