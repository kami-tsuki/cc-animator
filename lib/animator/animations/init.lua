local util = require("animator.util")

local M = {}

M.order = {
    "energy",
    "plasma",
    "lattice",
    "lightning",
    "rave",
    "aurora",
    "vortex",
    "dna",
    "matrix",
    "circuit",
    "beam",
    "tube",
    "waterfall",
    "arcstorm"
}

M.all = {}

local function loadAnimation(id)
    local logic = require("animator.animations." .. id .. ".logic")
    local configPath = util.combine(util.baseDir(), "lib/animator/animations/" .. id .. "/config.json")
    local config = util.readJson(configPath) or { label = id }

    M.all[id] = {
        id = id,
        label = config.label or id,
        description = config.description or "",
        settings = config.settings or {},
        render = logic.render
    }
end

for _, id in ipairs(M.order) do
    loadAnimation(id)
end

function M.get(id)
    return M.all[id] or M.all.energy
end

function M.list()
    return M.order, M.all
end

return M
