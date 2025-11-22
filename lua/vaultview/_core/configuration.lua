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

    vault = {
        path = "/tmp/myVault/", -- full path th the vault
        name = "myVault", -- name of the Vault as seen by Obsidian. Used to build uri path for Obsidian
    },
    user_commands = {
        input_selectors = { -- list of custom input selectors. They keys can be used in board definitions
            empty_list = { -- a comma-separated list of file paths
            },
            empty_func = function(search_path) -- a function that returns a list of file paths from a given search_path
                return {
                }
            end,
            empty_shell_command = [=[ your_shell_command ]=], -- Custom shell command to list files
        },
        entry_content_selectors = { -- custom content selectors can be defined here and chosen in the board configuration
        },
    },
    boards = {
        {
            name = "dailyBoard", -- name of the board as printed in the top of UI
            parser = "daily", -- parser used to retrieve information to display in the view -> currently supported parsers: "daily", "moc"
            viewlayout = "carousel", -- how lists are displayed in the view -> currently supported layouts: "carousel", "columns"
            input_selector = "yyyy-mm-dd_md", -- rule to select files to be included in the board. Can be a built-in selector or a user-defined one
            subfolder = "vault/0-dailynotes", -- optional subfolder inside vault to limit the scope of the parser
            content_selector = "lvl2headings_noexcalidraw_awk", -- rule to select content inside each file to be displayed in the view. Can be a built-in selector or a user-defined one
        },
    },
    -- initial_board_idx = 1, -- index of the board to be displayed when opening the vaultview. Optional.
}

_DEFAULTS = vim.tbl_deep_extend("force", _DEFAULTS, _EXTRA_DEFAULTS)

--- Setup `vaultview` for the first time, if needed.
function M.initialize_data_if_needed()
    if vim.g.loaded_vaultview then
        return
    end

    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.vaultview_configuration or {})

    require("vaultview._ui.highlights").apply()

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
