---@diagnostic disable: undefined-global
local util = require("animator.util")

local M = {}

function M.clear(state, background)
    term.setBackgroundColor(background or colors.black)
    term.setTextColor(colors.white)
    term.clear()
    state.uiButtons = {}
end

function M.panelWrite(y, text, color, background)
    local tw, th = term.getSize()
    if y < 1 or y > th then
        return
    end

    term.setCursorPos(1, y)
    term.setBackgroundColor(background or colors.black)
    term.clearLine()
    term.setTextColor(color or colors.white)
    term.write(util.fitTextWidth(tostring(text or ""), tw))
end

function M.panelCenter(y, text, color, background)
    local tw, th = term.getSize()
    if y < 1 or y > th then
        return
    end

    text = util.fitTextWidth(tostring(text or ""), tw)
    local x = math.max(1, math.floor((tw - util.textWidth(text)) / 2) + 1)
    term.setCursorPos(x, y)
    term.setBackgroundColor(background or colors.black)
    term.setTextColor(color or colors.white)
    term.write(text)
end

function M.writeAt(x, y, text, color, background)
    local tw, th = term.getSize()
    if y < 1 or y > th or x > tw then
        return
    end

    x = math.max(1, x)
    term.setCursorPos(x, y)
    term.setBackgroundColor(background or colors.black)
    term.setTextColor(color or colors.white)
    term.write(util.fitTextWidth(tostring(text or ""), tw - x + 1))
end

function M.writeRight(y, text, color, background, padding)
    local tw = term.getSize()
    text = tostring(text or "")
    local x = math.max(1, tw - util.textWidth(text) - (padding or 0) + 1)
    M.writeAt(x, y, text, color, background)
end

function M.writeWrapped(x, y, width, text, color, background, maxLines)
    local lineCount = 0
    for _, line in ipairs(util.wrapText(text or "", math.max(1, width))) do
        if maxLines and lineCount >= maxLines then
            break
        end
        M.writeAt(x, y + lineCount, line, color, background)
        lineCount = lineCount + 1
    end
    return lineCount
end

function M.writeKeyValue(y, label, value, color)
    M.panelWrite(y, string.format("%-10s %s", tostring(label or "") .. ":", tostring(value or "")), color or colors.white)
end

function M.fillRect(x, y, width, height, background)
    if width <= 0 or height <= 0 then
        return
    end
    paintutils.drawFilledBox(x, y, x + width - 1, y + height - 1, background or colors.black)
end

function M.drawFrame(x, y, width, height, border, background, title, titleColor)
    if width <= 1 or height <= 1 then
        return
    end

    M.fillRect(x, y, width, height, background or colors.black)
    paintutils.drawBox(x, y, x + width - 1, y + height - 1, border or colors.gray)

    if title and title ~= "" and width > 4 then
        local header = " " .. util.fitTextWidth(tostring(title), width - 4) .. " "
        M.writeAt(x + 2, y, header, titleColor or colors.white, background or colors.black)
    end
end

function M.addButton(state, x, y, width, label, background, foreground, action)
    local tw, th = term.getSize()
    if y < 1 or y > th or x > tw then
        return
    end

    local safeWidth = math.max(1, math.min(width, tw - x + 1))
    local text = util.fitTextWidth(tostring(label or ""), safeWidth)
    if util.textWidth(text) < safeWidth then
        text = text .. string.rep(" ", safeWidth - util.textWidth(text))
    end

    state.uiButtons[#state.uiButtons + 1] = {
        x1 = x,
        y1 = y,
        x2 = x + safeWidth - 1,
        y2 = y,
        action = action
    }

    term.setCursorPos(x, y)
    term.setBackgroundColor(background or colors.gray)
    term.setTextColor(foreground or colors.white)
    term.write(text)
    term.setBackgroundColor(colors.black)
end

function M.hitTest(state, x, y)
    for _, button in ipairs(state.uiButtons or {}) do
        if x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
            return button.action
        end
    end
end

function M.visibleListCount()
    local _, th = term.getSize()
    return math.max(4, math.min(8, th - 13))
end

function M.getMonitorLetter(index)
    return string.char(64 + ((index - 1) % 26) + 1)
end

function M.drawStatusBar(state, message)
    if message ~= nil then
        state.statusMessage = tostring(message)
    end

    local _, th = term.getSize()
    local text = state.statusMessage
    if not text or text == "" then
        text = "Ready • Q quit • R rescan • Tab select monitor"
    end

    M.panelWrite(th, " " .. text, colors.white, colors.gray)
end

function M.drawMiniMap(state, originX, originY, mapWidth, mapHeight)
    M.drawFrame(originX, originY, mapWidth, mapHeight, colors.lightBlue, colors.black)

    if #(state.monitorTiles or {}) == 0 then
        M.writeAt(originX + 2, originY + 2, "No monitors", colors.gray)
        return
    end

    local minX, minY = math.huge, math.huge
    local maxXBound, maxYBound = 1, 1

    for _, tile in ipairs(state.monitorTiles) do
        minX = math.min(minX, tile.x)
        minY = math.min(minY, tile.y)
        maxXBound = math.max(maxXBound, tile.x + tile.width - 1)
        maxYBound = math.max(maxYBound, tile.y + tile.height - 1)
    end

    local spanX = math.max(1, maxXBound - minX + 1)
    local spanY = math.max(1, maxYBound - minY + 1)
    local usableW = math.max(6, mapWidth - 2)
    local usableH = math.max(4, mapHeight - 2)

    for index, tile in ipairs(state.monitorTiles) do
        local sx = originX + 1 + math.floor(((tile.x - minX) / spanX) * (usableW - 4))
        local sy = originY + 1 + math.floor(((tile.y - minY) / spanY) * (usableH - 2))
        local sw = math.max(4, math.floor((tile.width / spanX) * usableW + 0.5))
        local sh = math.max(2, math.floor((tile.height / spanY) * usableH + 0.5))
        local ex = math.min(originX + mapWidth - 2, sx + sw - 1)
        local ey = math.min(originY + mapHeight - 2, sy + sh - 1)
        local active = index == state.selectedMonitorIndex

        paintutils.drawFilledBox(sx, sy, ex, ey, active and colors.cyan or colors.gray)
        paintutils.drawBox(sx, sy, ex, ey, active and colors.white or colors.lightGray)
        M.writeAt(math.min(ex, sx + 1), math.floor((sy + ey) / 2), tile.label or M.getMonitorLetter(index), active and colors.black or colors.white, active and colors.cyan or colors.gray)
    end
end

return M
