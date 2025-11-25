--- All functions and data to help customize `vaultview` for this user.
---@diagnostic disable: missing-fields

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("vaultview._core.configuration")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_vaultview = false

---@type vaultview.Configuration
M.DATA = {}

---@type vaultview.Configuration
local _DEFAULTS = {
    --- @type mega.logging.SparseLoggerOptions
    logging = {
        level = "info",
        use_console = false,
        use_file = false,
        output_path = "/tmp/vaultview.log",
        raw_debug_console = true,
    },
}

---@type vaultview.Configuration
local _EXTRA_DEFAULTS = {
    --- @type table
    keymaps = {
        open = {},
        close = {},
    },

    vault = {
        path = "/tmp/myVault/", -- full path th the vault
        name = "myVault", -- name of the Vault as seen by Obsidian. Used to build uri path for Obsidian
    },
    hints = {
        board_navigation = true,
        pages_navigation = false, -- TODO: not yet implemented
        entry_navigation = false, -- TODO: not yet implemented
    },
    selectors = {
        input = require("vaultview._core.parsers.selectors").default_input_selectors,
        entry_content = require("vaultview._core.parsers.selectors").default_entry_content_selectors,
    },
    boards = {
        -- {
        --     name = "dailyBoard", -- name of the board as printed in the top of UI
        --     parser = "daily", -- parser used to retrieve information to display in the view -> currently supported parsers: "daily", "moc"
        --     viewlayout = "carousel", -- how lists are displayed in the view -> currently supported layouts: "carousel", "columns"
        --     input_selector = "yyyy-mm-dd.md", -- rule to select files to be included in the board. Can be a built-in selector or a user-defined one
        --     subfolder = "vault/0-dailynotes", -- optional subfolder inside vault to limit the scope of the parser
        --     content_selector = "h2_awk_noexcalidraw", -- rule to select content inside each file to be displayed in the view. Can be a built-in selector or a user-defined one
        -- },
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

    _LOGGER:fmt_info("Initialized vaultview's configuration.")
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
