---@diagnostic disable: undefined-global
local M = {}
local UTF8_PATTERN = "[%z\1-\127\194-\244][\128-\191]*"

function M.baseDir()
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

function M.combine(base, path)
    if not base or base == "" then
        return path
    end
    return fs.combine(base, path)
end

function M.clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function M.clamp01(value)
    return M.clamp(tonumber(value) or 0, 0, 1)
end

function M.trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, item in pairs(value) do
        copy[key] = M.deepCopy(item)
    end
    return copy
end

function M.deepMerge(base, overrides)
    local result = M.deepCopy(base or {})

    for key, value in pairs(overrides or {}) do
        if type(result[key]) == "table" and type(value) == "table" then
            result[key] = M.deepMerge(result[key], value)
        else
            result[key] = M.deepCopy(value)
        end
    end

    return result
end

function M.ensureDir(path)
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

function M.readFile(path)
    if not fs.exists(path) then
        return nil, "missing file"
    end

    local handle = fs.open(path, "r")
    if not handle then
        return nil, "failed to open file"
    end

    local data = handle.readAll()
    handle.close()
    return data
end

function M.writeFile(path, contents)
    M.ensureDir(path)

    local handle = fs.open(path, "w")
    if not handle then
        return false, "failed to open file"
    end

    handle.write(contents)
    handle.close()
    return true
end

function M.readJson(path)
    local body, err = M.readFile(path)
    if not body then
        return nil, err
    end

    local parsed = textutils.unserializeJSON(body)
    if type(parsed) ~= "table" then
        return nil, "invalid JSON"
    end

    return parsed
end

function M.writeJson(path, value)
    local encoder = textutils.serialiseJSON or textutils.serializeJSON
    local encoded

    if encoder then
        encoded = encoder(value, true)
    else
        encoded = textutils.serialize(value)
    end

    return M.writeFile(path, encoded)
end

function M.urlEncode(value)
    return (tostring(value):gsub("([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

function M.encodePath(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        parts[#parts + 1] = M.urlEncode(part)
    end
    return table.concat(parts, "/")
end

function M.textWidth(value)
    local width = 0
    for _ in tostring(value or ""):gmatch(UTF8_PATTERN) do
        width = width + 1
    end
    return width
end

function M.fitTextWidth(value, width)
    width = math.max(0, tonumber(width) or 0)
    if width == 0 then
        return ""
    end

    local chars = {}
    for char in tostring(value or ""):gmatch(UTF8_PATTERN) do
        chars[#chars + 1] = char
        if #chars >= width then
            break
        end
    end

    return table.concat(chars)
end

function M.truncate(value, width)
    value = tostring(value or "")
    width = math.max(0, tonumber(width) or 0)
    if width == 0 then
        return ""
    end
    if M.textWidth(value) <= width then
        return value
    end
    if width <= 3 then
        return string.rep(".", width)
    end
    return M.fitTextWidth(value, width - 3) .. "..."
end

function M.makeProgressBar(width, ratio, filledGlyph, emptyGlyph)
    width = math.max(0, tonumber(width) or 0)
    ratio = M.clamp01(ratio or 0)
    filledGlyph = filledGlyph or "="
    emptyGlyph = emptyGlyph or "-"

    local filled = math.floor((width * ratio) + 0.5)
    local empty = math.max(0, width - filled)
    return string.rep(filledGlyph, filled) .. string.rep(emptyGlyph, empty)
end

function M.safeFormatTime()
    local ok, formatted = pcall(textutils.formatTime, os.time(), true)
    if ok then
        return formatted
    end
    return tostring(os.time())
end

return M
