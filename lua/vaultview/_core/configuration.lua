--- All functions and data to help customize `vaultview` for this user.


local logging = require("mega.logging")

local _LOGGER = logging.get_logger("vaultview._core.configuration")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_vaultview = false

---@type vaultview.Configuration
M.DATA = {}

-- TODO: (you) If you use the mega.logging module for built-in logging, keep
-- the `logging` section. Otherwise delete it.
--
-- It's recommended to keep the `display` section in any case.
--
---@type vaultview.Configuration
local _DEFAULTS = {
    logging = { level = "info", use_console = false, use_file = false },
}

-- TODO: (you) Update these sections depending on your intended plugin features.
local _EXTRA_DEFAULTS = {
    commands = {
        open = {},
        close = {},
    },
}

_DEFAULTS = vim.tbl_deep_extend("force", _DEFAULTS, _EXTRA_DEFAULTS)

--- Setup `vaultview` for the first time, if needed.
function M.initialize_data_if_needed()
    if vim.g.loaded_vaultview then
        return
    end

    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.vaultview_configuration or {})

    vim.g.loaded_vaultview = true

    local configuration = M.DATA.logging or {}
    ---@cast configuration mega.logging.SparseLoggerOptions
    logging.set_configuration("vaultview", configuration)

    _LOGGER:fmt_debug("Initialized vaultview's configuration.")
end

--- Merge `data` with the user's current configuration.
---
---@param data vaultview.Configuration? All extra customizations for this plugin.
---@return vaultview.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    M.initialize_data_if_needed()

    return vim.tbl_deep_extend("force", M.DATA, data or {})
end

return M
