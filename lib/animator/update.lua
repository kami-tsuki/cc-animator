---@diagnostic disable: undefined-global, undefined-field
local updater = require("animator.updater")
local util = require("animator.util")

local M = {}

local function confirm(prompt, defaultYes)
    write(prompt .. (defaultYes and " [Y/n] " or " [y/N] "))
    local answer = util.trim(read() or ""):lower()
    if answer == "" then
        return defaultYes or false
    end
    return answer == "y" or answer == "yes"
end

local function printProgress(info)
    local percent = math.floor(((info and info.ratio) or 0) * 100 + 0.5)
    print(string.format("[%3d%%] %s", percent, info.message or "Working..."))
end

function M.run()
    if not http then
        error("HTTP API is required for updates.")
    end

    local baseDir = updater.currentBaseDir()
    local currentRuntime = updater.readRuntimePath(baseDir) or baseDir
    local updateInfo, updateErr = updater.checkForUpdate({
        baseDir = baseDir
    })
    if not updateInfo then
        error("Update check failed: " .. tostring(updateErr))
    end

    print("Current version: " .. tostring(updateInfo.currentVersion))
    print("Remote version:  " .. tostring(updateInfo.targetVersion))
    print("Runtime path:    " .. tostring(currentRuntime))
    print("")

    local runtimeRoot, pathErr = updater.promptRuntimeRoot({
        baseDir = baseDir,
        currentRuntime = currentRuntime,
        appFolder = "cc-animator"
    })
    if not runtimeRoot then
        error("Runtime path selection failed: " .. tostring(pathErr))
    end

    local switchingLocation = runtimeRoot ~= currentRuntime
    if not updateInfo.updateAvailable and not switchingLocation then
        print("Already up to date.")
        return true
    end

    local actionLabel = updateInfo.updateAvailable and "Apply update now" or "Reinstall current version to the selected runtime path"
    if not confirm(actionLabel .. "?", true) then
        print("Update cancelled.")
        return false
    end

    local ok, resultOrError = updater.installFromManifest(updateInfo.remoteManifest, {
        baseDir = baseDir,
        runtimeRoot = runtimeRoot,
        localOnlyPaths = updater.LOCAL_CORE_PATHS,
        onProgress = printProgress
    })

    if not ok then
        error("Update failed: " .. tostring(resultOrError))
    end

    local saved, saveErr = updater.saveRuntimePath(runtimeRoot, baseDir)
    if not saved then
        error("Update applied, but the runtime path could not be saved: " .. tostring(saveErr))
    end

    local installedVersion = updateInfo.targetVersion
    if type(resultOrError) == "table" and resultOrError.version then
        installedVersion = resultOrError.version
    end

    print("Updated to version " .. tostring(installedVersion) .. ".")
    print("Runtime location: " .. tostring(runtimeRoot))
    if os.reboot and confirm("Reboot now?", false) then
        os.reboot()
    end

    return true
end

return M
