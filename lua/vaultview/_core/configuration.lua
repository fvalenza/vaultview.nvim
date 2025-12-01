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
    hints = {
        board_navigation = true,
        pages_navigation = false, -- TODO: not yet implemented
        entry_navigation = false, -- TODO: not yet implemented
    },
    selectors = {
        input = require("vaultview._core.parsers.selectors").default_input_selectors,
        entry_content = require("vaultview._core.parsers.selectors").default_entry_content_selectors,
    },
    vaults = {
        ["myVault"] = { -- Just a key used to reference the vault in board config but can be the same as obsidianVaultName
            path = "/tmp/myVault/",
            obsidianVaultName = "myVault", -- Name of the vault as known by Obsidian (used to build uri)
        },
        ["noVault"] = nil,
    },
    ---@class vaultview.BoardConfig
    ---@field vault string Key of the vault to use (must exist in the `vaults` section of the plugin configuration).p
    ---@field name string Display name of the board, shown in the top header UI.
    ---@field parser '"daily"' | '"moc"' Parser used to extract data from the vault.
    --- Supported parsers:
    --- - `"daily"` — daily notes organization
    --- - `"moc"` — Map-Of-Content structure
    ---@field viewlayout '"carousel"' | '"columns"' How lists/pages are visually displayed in the View.
    --- Supported layouts:
    --- - `"carousel"` — one list/page centered, others scroll horizontally
    --- - `"columns"` — multiple lists rendered side by side
    ---@field input_selector string Rule used to select which files to include in the board.
    --- Can refer to:
    --- - a built-in selector
    --- - a user-defined selector
    ---@field subfolder string|nil Optional subfolder inside the selected vault. If set, limits the parser to this directory only.
    ---@field content_selector string Rule to pick which part of each file is displayed.
    --- Can refer to:
    --- - a built-in content selector
    --- - a user-defined selector

    ---@type vaultview.BoardConfig[]
    boards = {
        -- {
        --     vault= "myVault", -- key of the vault as defined in the `Vaults` section
        --     name = "dailyBoard", -- name of the board as printed in the top of UI
        --     parser = "daily", -- parser used to retrieve information to display in the view -> currently supported parsers: "daily", "moc"
        --     viewlayout = "carousel", -- how lists are displayed in the view -> currently supported layouts: "carousel", "columns"
        --     input_selector = "yyyy-mm-dd.md", -- rule to select files to be included in the board. Can be a built-in selector or a user-defined one
        --     subfolder = "vault/0-dailynotes", -- optional subfolder inside vault to limit the scope of the parser
        --     content_selector = "h2_awk_noexcalidraw", -- rule to select content inside each file to be displayed in the view. Can be a built-in selector or a user-defined one
        -- },
        -- {
        --     vault= "obsidian:<workspace_name>", -- special syntax to directly reference an Obsidian vault configured in Obsidian.nvim plugin ( key of the workspace as defined in the `workspaces` section of obsidian.nvim plugin configuration)
        -- ....
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
