---@diagnostic disable: undefined-global
local util = require("animator.util")

local M = {}

M.DEFAULT_PATH = "config.json"
M.SETTINGS_PATH = ".animated_monitor_settings"
M.DEFAULTS = {
    title = "Kami-Animator",
    version = "2.0.0",
    subtitle = "Modular multi-monitor animation wall",
    preferredScale = 0.5,
    minFps = 8,
    maxFps = 18,
    defaultAnimation = "energy",
    defaultTheme = "neon",
    showPreviewOnBoot = false,
    gpu = {
        mode = "adaptive",
        defaultScale = 1,
        minScale = 1,
        maxScale = 4,
        targetBudgetRatio = 0.85
    },
    runtime = {
        rngSeed = 1337,
        fpsOverride = 0,
        speedPercent = 100,
        intensityPercent = 100,
        sparklePercent = 100,
        variationPercent = 100,
        brightnessPercent = 100,
        gpuScale = 1,
        gpuAdaptive = true
    }
}

function M.defaultRuntimeSettings()
    return util.deepCopy(M.DEFAULTS.runtime)
end

function M.loadGeneral(path)
    local parsed, err = util.readJson(path or M.DEFAULT_PATH)
    if not parsed then
        return util.deepCopy(M.DEFAULTS), err
    end

    return util.deepMerge(M.DEFAULTS, parsed)
end

function M.loadRuntime(path)
    path = path or M.SETTINGS_PATH
    if not fs.exists(path) then
        return {}
    end

    local body, err = util.readFile(path)
    if not body then
        return {}, err
    end

    local ok, parsed = pcall(textutils.unserialize, body)
    if not ok or type(parsed) ~= "table" then
        return {}
    end

    return parsed
end

function M.saveRuntime(data, path)
    return util.writeFile(path or M.SETTINGS_PATH, textutils.serialize(data or {}))
end

return M
