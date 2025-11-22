--- VaultView public API.
--
-- This module exposes all externally callable functions of the plugin.
-- Any backward-incompatible changes to the signatures of these functions
-- require a **major** version bump of the plugin.
--
-- @module vaultview
-- @alias M

local logging = require("mega.logging")
local configuration = require("vaultview._core.configuration")
local vaultview = require("vaultview._core.vaultview")

local _LOGGER = logging.get_logger("vaultview.init")

local M = {}

--- Runtime context table storing the active VaultView instance.
-- @field vv table|nil The active `vaultview` instance, or `nil` if not loaded.
M.context = {}

--- Open the VaultView UI.
--
-- Equivalent to calling `M.toggle()`.
-- Opens the UI if not already visible.
function M.open()
    M.toggle()
end

--- Toggle the visibility of VaultView.
--
-- - If not yet created, this resolves configuration, creates a new instance,
--   and displays it.
-- - If already created but hidden, it is shown.
-- - If already visible, it is hidden.
function M.toggle()
    _LOGGER:debug("Toggling board")

    if not M.context.vv then
        local plugin_configuration = configuration.resolve_data(vim.g.vaultview_configuration)
        local vv = vaultview.new(plugin_configuration)
        M.context.vv = vv
        M.context.vv:show()
    else
        if not M.context.vv.isDisplayed then
            M.context.vv:show()
        else
            M.context.vv:hide()
        end
    end
end

--- Close and destroy the VaultView UI.
--
-- Hides the UI if present and removes the active context.
function M.close()
    if M.context.vv then
        M.context.vv:hide()
        M.context.vv = nil
    end
end

--- Reload VaultView.
--
-- This closes the current instance (if any) and opens a fresh one with
-- the current configuration.
function M.reload()
    M.close()
    M.open()
end

--- Hide the UI if currently displayed.
function M.hide()
    if M.context.vv then
        M.context.vv:hide()
    end
end

--- Go to the previous board.
function M.goto_previous_board()
    if M.context.vv then
        M.context.vv:previous_board()
    end
end

--- Go to the next board.
function M.goto_next_board()
    if M.context.vv then
        M.context.vv:next_board()
    end
end

--- Go to a specific board by index.
-- @tparam number index The target board index.
function M.goto_board(index)
    if M.context.vv then
        M.context.vv:goto_board(index)
    end
end

--- Go to the previous page of the current board.
function M.goto_previous_page()
    if M.context.vv then
        M.context.vv:previous_page()
    end
end

--- Go to the next page of the current board.
function M.goto_next_page()
    if M.context.vv then
        M.context.vv:next_page()
    end
end

--- Focus the first list of the board.
function M.focus_first_list()
    if M.context.vv then
        M.context.vv:focus_first_list()
    end
end

--- Focus the previous list.
function M.focus_previous_list()
    if M.context.vv then
        M.context.vv:focus_previous_list()
    end
end

--- Focus the center list.
function M.focus_center_list()
    if M.context.vv then
        M.context.vv:focus_center_list()
    end
end

--- Focus the next list.
function M.focus_next_list()
    if M.context.vv then
        M.context.vv:focus_next_list()
    end
end

--- Focus the last list.
function M.focus_last_list()
    if M.context.vv then
        M.context.vv:focus_last_list()
    end
end

--- Focus the first entry of the current list.
function M.focus_first_entry()
    if M.context.vv then
        M.context.vv:focus_first_entry()
    end
end

--- Focus the previous entry of the current list.
function M.focus_previous_entry()
    if M.context.vv then
        M.context.vv:focus_previous_entry()
    end
end

--- Focus the next entry of the current list.
function M.focus_next_entry()
    if M.context.vv then
        M.context.vv:focus_next_entry()
    end
end

--- Focus the last entry of the current list.
function M.focus_last_entry()
    if M.context.vv then
        M.context.vv:focus_last_entry()
    end
end

--- Focus the previous entry page.
function M.focus_previous_entry_page()
    if M.context.vv then
        M.context.vv:focus_previous_entry_page()
    end
end

--- Focus the next entry page.
function M.focus_next_entry_page()
    if M.context.vv then
        M.context.vv:focus_next_entry_page()
    end
end

--- Open the currently focused entry in Neovim.
function M.open_in_neovim()
    if M.context.vv then
        M.context.vv:open_in_neovim()
    end
end

--- Open the currently focused entry in Obsidian.
function M.open_in_obsidian()
    if M.context.vv then
        M.context.vv:open_in_obsidian()
    end
end

--- Refresh the content of the focused entry.
function M.refresh_focused_entry_content()
    if M.context.vv then
        M.context.vv:refresh_focused_entry_content()
    end
end

--- Perform a fast refresh operation.
function M.fast_refresh()
    if M.context.vv then
        M.context.vv:fast_refresh()
    end
end

--- Open the plugin help documentation.
--
-- Opens `_doc/help_page.md` in a floating window using Snacks.
function M.open_help()
    local current_file = debug.getinfo(1, "S").source:sub(2)
    local help_path = vim.fn.fnamemodify(current_file, ":h:h:h") .. "/_doc/help_page.md"

    local help_win = Snacks.win({
        file = help_path,
        width = 0.8,
        height = 0.8,
        zindex = 60,
        border = "rounded",
        relative = "editor",
        bo = { modifiable = false, filetype = "markdown" },
        keys = { q = "close" },
        wo = {
            wrap = true,
            linebreak = true,
        },
    })
end

return M
