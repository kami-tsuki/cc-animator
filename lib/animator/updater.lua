---@diagnostic disable: undefined-global
local httpClient = require("animator.http")
local manifestModel = require("animator.manifest")
local util = require("animator.util")

local M = {}

M.MANIFEST_PATH = manifestModel.DEFAULT_PATH
M.DEFAULT_REPO = manifestModel.DEFAULT_REPO
M.DEFAULT_BRANCH = manifestModel.DEFAULT_BRANCH
M.RUNTIME_PATH_FILE = ".cc-animator.runtime_path"
M.LOCAL_CORE_PATHS = {
    ["animated_monitor.lua"] = true,
    ["startup.lua"] = true,
    ["update.lua"] = true,
    ["install.lua"] = true,
    ["config.json"] = true,
    ["manifest.json"] = true,
    ["README.md"] = true,
    ["LICENSE"] = true,
    ["lib/animator/bootstrap.lua"] = true,
}

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

M.currentBaseDir = currentBaseDir

local function absolutePath(baseDir, path)
    path = util.trim(path or "")
    if path == "" then
        return (baseDir and baseDir ~= "") and baseDir or "/"
    end

    if path:sub(1, 1) == "/" then
        return path
    end

    if baseDir and baseDir ~= "" then
        return fs.combine(baseDir, path)
    end

    return path
end

local function samePath(left, right)
    return absolutePath("/", left or "") == absolutePath("/", right or "")
end

local function resolveManifestSource(localManifest, overrides)
    overrides = overrides or {}

    return {
        repo = overrides.repo or (localManifest and localManifest.repo) or M.DEFAULT_REPO,
        branch = overrides.branch or (localManifest and localManifest.branch) or M.DEFAULT_BRANCH,
        path = overrides.path or M.MANIFEST_PATH
    }
end

local function writeBody(path, body)
    util.ensureDir(path)

    local handle = fs.open(path, "wb") or fs.open(path, "w")
    if not handle then
        return false, "failed to open file"
    end

    handle.write(body)
    handle.close()
    return true
end

local function progress(callback, step, total, message, phase, path)
    if not callback then
        return
    end

    callback({
        step = step,
        total = total,
        ratio = total > 0 and (step / total) or 1,
        message = message,
        phase = phase,
        path = path
    })
end

local function confirm(prompt, defaultYes)
    write(prompt .. (defaultYes and " [Y/n] " or " [y/N] "))
    local answer = util.trim(read() or ""):lower()
    if answer == "" then
        return defaultYes or false
    end
    return answer == "y" or answer == "yes"
end

local function addCandidate(list, seen, path)
    path = util.trim(path or "")
    if path == "" or seen[path] then
        return
    end

    local parent = fs.getDir(path)
    if fs.exists(path) then
        if not fs.isDir(path) then
            return
        end
    elseif parent ~= "" and not fs.exists(parent) then
        return
    end

    seen[path] = true
    list[#list + 1] = path
end

local function targetPathFor(baseDir, runtimeRoot, relativePath, localOnlyPaths)
    relativePath = util.trim(relativePath or "")
    if relativePath == "" then
        return absolutePath(baseDir, "")
    end

    if not runtimeRoot or runtimeRoot == "" or samePath(runtimeRoot, baseDir) or (localOnlyPaths and localOnlyPaths[relativePath]) then
        return absolutePath(baseDir, relativePath)
    end

    return absolutePath(runtimeRoot, relativePath)
end

function M.rawUrl(repo, branch, path)
    return manifestModel.rawUrl(repo, branch, path)
end

function M.loadManifest(path)
    return manifestModel.load(path or M.MANIFEST_PATH)
end

function M.fetchRemoteManifest(repo, branch, path)
    return manifestModel.fetch(repo or M.DEFAULT_REPO, branch or M.DEFAULT_BRANCH, path or M.MANIFEST_PATH)
end

function M.compareVersions(left, right)
    return manifestModel.compareVersions(left, right)
end

function M.readRuntimePath(baseDir)
    baseDir = baseDir or currentBaseDir()
    local body = util.readFile(absolutePath(baseDir, M.RUNTIME_PATH_FILE))
    if not body then
        return nil
    end

    local runtimePath = util.trim(body)
    if runtimePath == "" then
        return nil
    end

    runtimePath = absolutePath(baseDir, runtimePath)
    if fs.exists(runtimePath) and fs.isDir(runtimePath) then
        return runtimePath
    end

    return nil
end

function M.saveRuntimePath(runtimePath, baseDir)
    baseDir = baseDir or currentBaseDir()
    runtimePath = util.trim(runtimePath or "")
    local pointerPath = absolutePath(baseDir, M.RUNTIME_PATH_FILE)

    if runtimePath == "" or samePath(runtimePath, baseDir) then
        if fs.exists(pointerPath) then
            fs.delete(pointerPath)
        end
        return true
    end

    return util.writeFile(pointerPath, absolutePath(baseDir, runtimePath) .. "\n")
end

function M.detectStorageTargets(appFolder)
    appFolder = util.trim(appFolder or "cc-animator")
    local candidates = {}
    local seen = {}

    if peripheral and disk and type(disk.getMountPath) == "function" then
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "drive" then
                local ok, mountPath = pcall(disk.getMountPath, name)
                if ok and mountPath then
                    addCandidate(candidates, seen, mountPath)
                    addCandidate(candidates, seen, fs.combine(mountPath, appFolder))
                end
            end
        end
    end

    for _, name in ipairs(fs.list("/")) do
        local rootPath = fs.combine("/", name)
        if fs.isDir(rootPath) and (name:match("^disk") or name:match("^drive") or name:match("^mnt")) then
            addCandidate(candidates, seen, rootPath)
            addCandidate(candidates, seen, fs.combine(rootPath, appFolder))
        end
    end

    table.sort(candidates)
    return candidates
end

function M.promptRuntimeRoot(options)
    options = options or {}
    local baseDir = options.baseDir or currentBaseDir()
    local currentRuntime = options.currentRuntime or M.readRuntimePath(baseDir) or baseDir
    local appFolder = options.appFolder or "cc-animator"
    local currentlyExternal = not samePath(currentRuntime, baseDir)

    if not confirm(currentlyExternal and ("Store the runtime on external/shared storage? Current: " .. tostring(currentRuntime)) or "Store the runtime on external/shared storage?", currentlyExternal) then
        return baseDir, nil
    end

    local candidates = M.detectStorageTargets(appFolder)
    if #candidates > 0 then
        print("Detected removable/shared storage paths:")
        for index, path in ipairs(candidates) do
            print(string.format("  %d. %s", index, path))
        end
    else
        print("No mounted disk paths were auto-detected; you can still enter a path manually.")
    end

    local suggested = currentlyExternal and currentRuntime or candidates[1] or fs.combine("/disk", appFolder)
    write("Enter runtime install path [" .. suggested .. "]: ")
    local entered = util.trim(read() or "")
    local runtimeRoot = absolutePath(baseDir, entered ~= "" and entered or suggested)

    if not fs.exists(runtimeRoot) then
        util.ensureDir(fs.combine(runtimeRoot, "placeholder"))
        fs.makeDir(runtimeRoot)
    end

    if not fs.exists(runtimeRoot) or not fs.isDir(runtimeRoot) then
        return nil, "invalid directory: " .. tostring(runtimeRoot)
    end

    return runtimeRoot, nil
end

function M.checkForUpdate(options)
    options = options or {}
    local baseDir = options.baseDir or currentBaseDir()
    local localManifest = M.loadManifest(absolutePath(baseDir, M.MANIFEST_PATH))
    local currentVersion = localManifest and localManifest.version or "0.0.0"
    local source = resolveManifestSource(localManifest, options)
    local remoteManifest, err = M.fetchRemoteManifest(source.repo, source.branch, source.path)
    if not remoteManifest then
        return nil, err
    end

    return {
        localManifest = localManifest,
        remoteManifest = remoteManifest,
        source = source,
        currentVersion = currentVersion,
        targetVersion = remoteManifest.version,
        updateAvailable = M.compareVersions(currentVersion, remoteManifest.version) < 0
    }
end

function M.installFromManifest(manifest, options)
    options = options or {}
    local onProgress = options.onProgress
    local baseDir = absolutePath("/", options.baseDir or currentBaseDir())
    local runtimeRoot = util.trim(options.runtimeRoot or "")
    local localOnlyPaths = options.localOnlyPaths or M.LOCAL_CORE_PATHS

    if runtimeRoot == "" then
        runtimeRoot = baseDir
    else
        runtimeRoot = absolutePath(baseDir, runtimeRoot)
    end

    local normalized, err = manifestModel.normalize(manifest)
    if not normalized then
        return false, err
    end

    local expandedFiles, expandErr = manifestModel.expandFiles(normalized.files, normalized.repo, normalized.branch)
    if not expandedFiles then
        return false, expandErr
    end

    normalized.files = expandedFiles

    local downloadQueue = {}
    local skipped = 0
    for _, entry in ipairs(normalized.files) do
        local targetPath = targetPathFor(baseDir, runtimeRoot, entry.path, localOnlyPaths)
        if manifestModel.isPreservedPath(normalized, entry.path) and fs.exists(targetPath) then
            skipped = skipped + 1
        else
            downloadQueue[#downloadQueue + 1] = {
                entry = entry,
                targetPath = targetPath
            }
        end
    end

    local deleteQueue = {}
    for _, path in ipairs(normalized.obsolete) do
        local targetPath = targetPathFor(baseDir, runtimeRoot, path, localOnlyPaths)
        if not manifestModel.isPreservedPath(normalized, path) and fs.exists(targetPath) then
            deleteQueue[#deleteQueue + 1] = {
                path = path,
                targetPath = targetPath
            }
        end
    end

    local writeQueue = {}
    local totalSteps = #downloadQueue + #deleteQueue + #downloadQueue
    local step = 0

    if totalSteps == 0 then
        progress(onProgress, 1, 1, "Already up to date", "done")
        return true, {
            downloaded = 0,
            written = 0,
            deleted = 0,
            skipped = skipped,
            version = normalized.version,
            runtimeRoot = runtimeRoot
        }
    end

    for _, item in ipairs(downloadQueue) do
        step = step + 1
        progress(onProgress, step, totalSteps, "Downloading " .. item.entry.path, "download", item.entry.path)

        local ok, bodyOrError = httpClient.read(M.rawUrl(normalized.repo, normalized.branch, item.entry.source))
        if not ok then
            return false, "Failed to download " .. item.entry.path .. ": " .. tostring(bodyOrError)
        end

        writeQueue[#writeQueue + 1] = {
            entry = item.entry,
            targetPath = item.targetPath,
            body = bodyOrError
        }
    end

    for _, item in ipairs(deleteQueue) do
        step = step + 1
        progress(onProgress, step, totalSteps, "Removing obsolete " .. item.path, "delete", item.path)
        fs.delete(item.targetPath)
    end

    table.sort(writeQueue, function(left, right)
        if left.entry.path == M.MANIFEST_PATH then
            return false
        end
        if right.entry.path == M.MANIFEST_PATH then
            return true
        end
        return left.entry.path < right.entry.path
    end)

    for _, item in ipairs(writeQueue) do
        step = step + 1
        progress(onProgress, step, totalSteps, "Installing " .. item.entry.path, "write", item.entry.path)

        local ok, writeErr = writeBody(item.targetPath, item.body)
        if not ok then
            return false, "Failed to write " .. item.entry.path .. " to " .. item.targetPath .. ": " .. tostring(writeErr)
        end
    end

    return true, {
        downloaded = #downloadQueue,
        written = #writeQueue,
        deleted = #deleteQueue,
        skipped = skipped,
        version = normalized.version,
        runtimeRoot = runtimeRoot
    }
end

function M.installLatest(options)
    local manifest, err = M.fetchRemoteManifest()
    if not manifest then
        return false, err
    end

    return M.installFromManifest(manifest, options)
end

return M
