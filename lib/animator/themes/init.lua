local M = {}

M.order = {
    "neon",
    "glacier",
    "toxic",
    "matrix",
    "motherboard",
    "sunset",
    "ember",
    "synthwave",
    "ocean",
    "mono",
    "candy",
    "redblack",
    "obsidian"
}

M.all = {
    neon = require("animator.themes.neon"),
    glacier = require("animator.themes.glacier"),
    toxic = require("animator.themes.toxic"),
    matrix = require("animator.themes.matrix"),
    motherboard = require("animator.themes.motherboard"),
    sunset = require("animator.themes.sunset"),
    ember = require("animator.themes.ember"),
    synthwave = require("animator.themes.synthwave"),
    ocean = require("animator.themes.ocean"),
    mono = require("animator.themes.mono"),
    candy = require("animator.themes.candy"),
    redblack = require("animator.themes.redblack"),
    obsidian = require("animator.themes.obsidian")
}

function M.get(id)
    return M.all[id] or M.all[M.order[1]]
end

function M.list()
    return M.order, M.all
end

return M
