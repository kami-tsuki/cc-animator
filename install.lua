---@diagnostic disable: undefined-global
local APP_NAME = "cc-animator"
local REPO = "kami-tsuki/cc-animator"
local BRANCH = "master"
local MANIFEST_PATH = "manifest.json"
local RUNTIME_PATH_FILE = ".cc-animator.runtime_path"
local LOCAL_CORE_PATHS = {
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

local function currentDir()
    if shell and shell.dir then
        return shell.dir()
    end
    return "/"
end

local function ensureDir(path)
    local dir = fs.getDir(path)
    if dir == "" then
        return
    end

    local cursor = ""
    for part in string.gmatch(dir, "[^/]+") do
        cursor = cursor == "" and part or fs.combine(cursor, part)
        if not fs.exists(cursor) then
            fs.makeDir(cursor)
        end
    end
end

local function readUrl(url, headers)
    local lastError = "request failed"

    for attempt = 1, 3 do
        local ok, response = pcall(http.get, url, headers, true)
        if ok and response then
            local body = response.readAll()
            response.close()
            return true, body
        end

        lastError = tostring(response)
        sleep(0.2 * attempt)
    end

    return false, lastError
end

local function writeBody(path, body)
    ensureDir(path)
    local handle = fs.open(path, "wb") or fs.open(path, "w")
    if not handle then
        return false, "failed to write " .. path
    end

    handle.write(body)
    handle.close()
    return true
end

local function readLocalFile(path)
    if not fs.exists(path) then
        return nil, "missing file"
    end

    local handle = fs.open(path, "r")
    if not handle then
        return nil, "failed to open " .. path
    end

    local body = handle.readAll()
    handle.close()
    return body
end

local function trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function encodePath(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        parts[#parts + 1] = (part:gsub("([^%w%-_%.~])", function(char)
            return string.format("%%%02X", string.byte(char))
        end))
    end
    return table.concat(parts, "/")
end

local function rawUrl(path, repo, branch)
    return string.format(
        "https://raw.githubusercontent.com/%s/%s/%s",
        repo or REPO,
        branch or BRANCH,
        encodePath(path)
    )
end

local function makeTreeUrl(repo, branch)
    return string.format(
        "https://api.github.com/repos/%s/git/trees/%s?recursive=1",
        repo or REPO,
        encodePath(branch or BRANCH)
    )
end

local function hasWildcard(value)
    value = tostring(value or "")
    return value:find("*", 1, true) ~= nil or value:find("?", 1, true) ~= nil
end

local function globToPattern(glob)
    local parts = { "^" }
    for index = 1, #glob do
        local char = glob:sub(index, index)
        if char == "*" then
            parts[#parts + 1] = ".*"
        elseif char == "?" then
            parts[#parts + 1] = "."
        elseif char:match("[%^%$%(%)%%%.%[%]%+%-%]]") then
            parts[#parts + 1] = "%" .. char
        else
            parts[#parts + 1] = char
        end
    end
    parts[#parts + 1] = "$"
    return table.concat(parts)
end

local function fetchRepoFiles(repo, branch)
    local ok, bodyOrError = readUrl(makeTreeUrl(repo, branch), {
        ["Accept"] = "application/vnd.github+json",
        ["User-Agent"] = "cc-animator-installer"
    })
    if not ok then
        return nil, bodyOrError
    end

    local parsed = textutils.unserializeJSON(bodyOrError)
    if type(parsed) ~= "table" or type(parsed.tree) ~= "table" then
        return nil, "invalid repository tree response"
    end

    local files = {}
    for _, node in ipairs(parsed.tree) do
        if type(node) == "table" and node.type == "blob" and type(node.path) == "string" then
            files[#files + 1] = node.path
        end
    end

    return files
end

local function normalizeFileEntry(entry)
    if type(entry) == "string" then
        local path = trim(entry)
        if path == "" then
            return nil, "file entry path is empty"
        end

        return {
            path = path,
            source = path,
            isPattern = hasWildcard(path)
        }
    end

    if type(entry) ~= "table" then
        return nil, "file entry must be a string or object"
    end

    local path = trim(entry.path or entry.destination or "")
    if path == "" then
        return nil, "file entry is missing 'path'"
    end

    local source = trim(entry.source or entry.path or path)
    if (hasWildcard(source) or hasWildcard(path)) and path ~= source then
        return nil, "pattern entries currently require matching 'path' and 'source'"
    end

    return {
        path = path,
        source = source,
        isPattern = hasWildcard(source) or hasWildcard(path)
    }
end

local function expandFileEntries(files, repo, branch)
    local expanded = {}
    local seen = {}
    local repoFiles = nil

    for _, entry in ipairs(files) do
        if entry.isPattern then
            if not repoFiles then
                local loaded, err = fetchRepoFiles(repo, branch)
                if not loaded then
                    return nil, err
                end
                repoFiles = loaded
            end

            local pattern = globToPattern(entry.source)
            local matched = false
            for _, path in ipairs(repoFiles) do
                if path:match(pattern) then
                    matched = true
                    if not seen[path] then
                        seen[path] = true
                        expanded[#expanded + 1] = {
                            path = path,
                            source = path,
                            isPattern = false
                        }
                    end
                end
            end

            if not matched then
                return nil, "pattern did not match any files: " .. entry.source
            end
        elseif not seen[entry.path] then
            seen[entry.path] = true
            expanded[#expanded + 1] = entry
        end
    end

    table.sort(expanded, function(left, right)
        return left.path < right.path
    end)

    return expanded
end

local function normalizeStringList(items)
    local values = {}
    local lookup = {}

    for _, item in ipairs(items or {}) do
        local value = trim(item)
        if value ~= "" and not lookup[value] then
            lookup[value] = true
            values[#values + 1] = value
        end
    end

    return values, lookup
end

local function absolutePath(baseDir, path)
    path = trim(path)
    if path == "" then
        return (baseDir ~= "" and baseDir) or "/"
    end
    if path:sub(1, 1) == "/" then
        return path
    end
    return (baseDir ~= "" and fs.combine(baseDir, path)) or path
end

local function samePath(left, right)
    return absolutePath("/", left or "") == absolutePath("/", right or "")
end

local function promptYesNo(prompt, defaultYes)
    write(prompt .. (defaultYes and " [Y/n] " or " [y/N] "))
    local answer = trim(read() or ""):lower()
    if answer == "" then
        return defaultYes or false
    end
    return answer == "y" or answer == "yes"
end

local function detectStorageTargets(appFolder)
    local candidates = {}
    local seen = {}

    local function addCandidate(path)
        path = trim(path)
        if path == "" or seen[path] then
            return
        end

        local parent = fs.getDir(path)
        if fs.exists(path) then
            if fs.isDir(path) then
                seen[path] = true
                candidates[#candidates + 1] = path
            end
            return
        end

        if parent == "" or fs.exists(parent) then
            seen[path] = true
            candidates[#candidates + 1] = path
        end
    end

    if peripheral and disk and type(disk.getMountPath) == "function" then
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "drive" then
                local ok, mountPath = pcall(disk.getMountPath, name)
                if ok and mountPath then
                    addCandidate(mountPath)
                    addCandidate(fs.combine(mountPath, appFolder))
                end
            end
        end
    end

    for _, name in ipairs(fs.list("/")) do
        local rootPath = fs.combine("/", name)
        if fs.isDir(rootPath) and (name:match("^disk") or name:match("^drive") or name:match("^mnt")) then
            addCandidate(rootPath)
            addCandidate(fs.combine(rootPath, appFolder))
        end
    end

    table.sort(candidates)
    return candidates
end

local function targetPathFor(baseDir, runtimeRoot, relativePath)
    if samePath(runtimeRoot, baseDir) or LOCAL_CORE_PATHS[relativePath] then
        return absolutePath(baseDir, relativePath)
    end
    return absolutePath(runtimeRoot, relativePath)
end

local function saveRuntimePath(runtimeRoot, baseDir)
    local pointerPath = absolutePath(baseDir, RUNTIME_PATH_FILE)
    if samePath(runtimeRoot, baseDir) then
        if fs.exists(pointerPath) then
            fs.delete(pointerPath)
        end
        return true
    end

    return writeBody(pointerPath, absolutePath(baseDir, runtimeRoot) .. "\n")
end

local function promptRuntimeRoot(baseDir)
    if not promptYesNo("Store the main runtime on external/shared storage?", false) then
        return absolutePath(baseDir, "")
    end

    local candidates = detectStorageTargets(APP_NAME)
    if #candidates > 0 then
        print("Detected removable/shared storage paths:")
        for index, path in ipairs(candidates) do
            print(string.format("  %d. %s", index, path))
        end
    else
        print("No mounted disk paths were auto-detected; you can still enter a path manually.")
    end

    local suggested = candidates[1] or fs.combine("/disk", APP_NAME)
    write("Enter runtime install path [" .. suggested .. "]: ")
    local entered = trim(read() or "")
    local runtimeRoot = absolutePath(baseDir, entered ~= "" and entered or suggested)

    if not fs.exists(runtimeRoot) then
        ensureDir(fs.combine(runtimeRoot, "placeholder"))
        if not fs.exists(runtimeRoot) then
            fs.makeDir(runtimeRoot)
        end
    end

    if not fs.exists(runtimeRoot) or not fs.isDir(runtimeRoot) then
        error("Runtime path is not a valid directory: " .. tostring(runtimeRoot))
    end

    return runtimeRoot
end

local function isPreservedPath(manifest, path)
    path = trim(path)
    if path == "" then
        return false
    end

    if manifest.preserveLookup[path] then
        return true
    end

    for _, value in ipairs(manifest.preserve or {}) do
        if hasWildcard(value) and path:match(globToPattern(value)) then
            return true
        end
    end

    return false
end

local function parseManifestBody(body)
    local parsed = textutils.unserializeJSON(body)
    if type(parsed) ~= "table" then
        return nil, "invalid manifest.json"
    end

    local version = trim(parsed.version or "")
    if version == "" then
        return nil, "manifest.json is missing 'version'"
    end

    local files = {}
    for _, entry in ipairs(parsed.files or {}) do
        local normalized, err = normalizeFileEntry(entry)
        if not normalized then
            return nil, err
        end
        files[#files + 1] = normalized
    end

    if #files == 0 then
        return nil, "manifest.json does not contain any files"
    end

    local expandedFiles, expandErr = expandFileEntries(files, trim(parsed.repo or REPO), trim(parsed.branch or BRANCH))
    if not expandedFiles then
        return nil, expandErr
    end

    local obsolete = normalizeStringList(parsed.obsolete or {})
    local preserve, preserveLookup = normalizeStringList(parsed.preserve or {})

    return {
        version = version,
        repo = trim(parsed.repo or REPO),
        branch = trim(parsed.branch or BRANCH),
        files = expandedFiles,
        obsolete = obsolete,
        preserve = preserve,
        preserveLookup = preserveLookup
    }
end

local function loadManifest()
    local ok, bodyOrError = readUrl(rawUrl(MANIFEST_PATH))
    if ok then
        local manifest, parseErr = parseManifestBody(bodyOrError)
        if not manifest then
            return nil, parseErr
        end

        writeBody(MANIFEST_PATH, bodyOrError)
        return manifest, nil, "remote"
    end

    local localBody = readLocalFile(MANIFEST_PATH)
    if not localBody then
        return nil, "unable to download manifest.json: " .. tostring(bodyOrError)
    end

    local manifest, parseErr = parseManifestBody(localBody)
    if not manifest then
        return nil, "remote manifest unavailable and local manifest is invalid: " .. tostring(parseErr)
    end

    return manifest, nil, "local"
end

if not http then
    error("HTTP API is not available. Enable HTTP in CC: Tweaked before running install.lua.")
end

local manifest, manifestErr, manifestSource = loadManifest()
if not manifest then
    error("Failed to load install manifest: " .. tostring(manifestErr))
end

local baseDir = absolutePath(currentDir(), "")
local runtimeRoot = promptRuntimeRoot(baseDir)

print(APP_NAME)
print("Installing runtime files into " .. baseDir)
print("Target version: " .. tostring(manifest.version))
print("Runtime location: " .. tostring(runtimeRoot))
if manifestSource == "local" then
    print("Remote manifest unavailable, using the existing local manifest.json.")
end
print("")

local failures = {}

for _, path in ipairs(manifest.obsolete) do
    local targetPath = targetPathFor(baseDir, runtimeRoot, path)
    if fs.exists(targetPath) and not isPreservedPath(manifest, path) then
        fs.delete(targetPath)
        print("Removed obsolete " .. targetPath)
    end
end

if #manifest.obsolete > 0 then
    print("")
end

for _, entry in ipairs(manifest.files) do
    local targetPath = targetPathFor(baseDir, runtimeRoot, entry.path)
    if isPreservedPath(manifest, entry.path) and fs.exists(targetPath) then
        print("Keeping existing " .. targetPath)
    else
        write("Downloading " .. entry.path .. " ... ")
        local ok, bodyOrError = readUrl(rawUrl(entry.source, manifest.repo, manifest.branch))
        if ok then
            local written, writeErr = writeBody(targetPath, bodyOrError)
            if written then
                print("ok")
            else
                print("failed")
                failures[#failures + 1] = entry.path .. ": " .. tostring(writeErr)
            end
        else
            print("failed")
            failures[#failures + 1] = entry.path .. ": " .. tostring(bodyOrError)
        end
    end
end

if #failures == 0 then
    local saved, saveErr = saveRuntimePath(runtimeRoot, baseDir)
    if not saved then
        failures[#failures + 1] = "runtime path pointer: " .. tostring(saveErr)
    end
end

print("")
if #failures > 0 then
    print("Install finished with errors:")
    for _, failure in ipairs(failures) do
        print(" - " .. failure)
    end
    error("Installation incomplete.")
end

print("Install complete.")
if samePath(runtimeRoot, baseDir) then
    print("Runtime is stored locally on this computer.")
else
    print("Runtime is stored on external/shared storage at: " .. runtimeRoot)
end
print("Run 'startup' or 'animated_monitor' to launch the animator.")
