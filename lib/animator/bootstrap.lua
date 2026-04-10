---@diagnostic disable: undefined-global
local M = {}

local RUNTIME_PATH_FILE = ".cc-animator.runtime_path"
local ROM_MODULE_ROOTS = {
    "rom/modules/main",
    "rom/modules/turtle",
    "rom/modules/command",
    "rom/modules/pocket"
}

local function trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function currentBaseDir()
    if shell and shell.getRunningProgram then
        local program = shell.getRunningProgram()
        if program and program ~= "" then
            return fs.getDir(program)
        end
    end

    if shell and shell.dir then
        return shell.dir()
    end

    return ""
end

local function readRuntimeBaseDir(baseDir)
    local pointerPath = fs.combine(baseDir, RUNTIME_PATH_FILE)
    if not fs.exists(pointerPath) or fs.isDir(pointerPath) then
        return nil
    end

    local handle = fs.open(pointerPath, "r")
    if not handle then
        return nil
    end

    local runtimeDir = trim(handle.readAll())
    handle.close()

    if runtimeDir == "" then
        return nil
    end

    if runtimeDir:sub(1, 1) ~= "/" then
        runtimeDir = fs.combine(baseDir, runtimeDir)
    end

    if fs.exists(runtimeDir) and fs.isDir(runtimeDir) then
        return runtimeDir
    end

    return nil
end

local function appendModuleCandidates(candidates, rootDir, relativePath)
    if not rootDir or rootDir == "" then
        return
    end

    candidates[#candidates + 1] = fs.combine(rootDir, relativePath)
    candidates[#candidates + 1] = fs.combine(rootDir, relativePath .. ".lua")
    candidates[#candidates + 1] = fs.combine(rootDir, fs.combine(relativePath, "init.lua"))
    candidates[#candidates + 1] = fs.combine(rootDir, fs.combine("lib", relativePath .. ".lua"))
    candidates[#candidates + 1] = fs.combine(rootDir, fs.combine("lib", fs.combine(relativePath, "init.lua")))
end

local function modulePaths(baseDir, moduleName, runtimeBaseDir)
    local relativePath = moduleName:gsub("%.", "/")
    local candidates = {}

    appendModuleCandidates(candidates, runtimeBaseDir, relativePath)
    if runtimeBaseDir ~= baseDir then
        appendModuleCandidates(candidates, baseDir, relativePath)
    end

    for _, root in ipairs(ROM_MODULE_ROOTS) do
        candidates[#candidates + 1] = fs.combine(root, relativePath)
        candidates[#candidates + 1] = fs.combine(root, relativePath .. ".lua")
        candidates[#candidates + 1] = fs.combine(root, fs.combine(relativePath, "init.lua"))
    end

    return candidates
end

local function resolveModulePath(baseDir, moduleName, runtimeBaseDir)
    for _, path in ipairs(modulePaths(baseDir, moduleName, runtimeBaseDir)) do
        if fs.exists(path) and not fs.isDir(path) then
            return path
        end
    end

    return nil
end

local function createRequire(baseDir, runtimeBaseDir, nativeRequire)
    local cache = {}
    local loading = {}

    local function customRequire(moduleName)
        if cache[moduleName] ~= nil then
            return cache[moduleName]
        end

        if nativeRequire then
            local ok, result = pcall(nativeRequire, moduleName)
            if ok then
                cache[moduleName] = result
                return result
            end
        end

        if loading[moduleName] then
            error("Circular module load detected for '" .. moduleName .. "'.")
        end

        local path = resolveModulePath(baseDir, moduleName, runtimeBaseDir)
        if not path then
            error("Module file not found for '" .. moduleName .. "'.")
        end

        local chunk, err = loadfile(path)
        if not chunk then
            error("Failed to load module '" .. moduleName .. "': " .. tostring(err))
        end

        loading[moduleName] = true
        local ok, result = pcall(chunk)
        loading[moduleName] = nil

        if not ok then
            error(result)
        end

        if result == nil then
            result = true
        end

        cache[moduleName] = result
        return result
    end

    return customRequire
end

function M.run(moduleName, ...)
    local baseDir = currentBaseDir()
    local runtimeBaseDir = readRuntimeBaseDir(baseDir) or baseDir
    local nativeRequire = rawget(_G, "require")
    local customRequire = createRequire(baseDir, runtimeBaseDir, nativeRequire)
    _G.require = customRequire

    local entry = customRequire(moduleName)
    if type(entry) == "table" and type(entry.run) == "function" then
        return entry.run(...)
    end

    if type(entry) == "function" then
        return entry(...)
    end

    error("Module '" .. tostring(moduleName) .. "' has no runnable entry point.")
end

return M
