--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local logging = require("mega.logging")
local configuration = require("vaultviewui._core.configuration")
local vaultview = require("vaultviewui._core.vaultview")

local _LOGGER = logging.get_logger("vaultviewui.init")

local M = {}
M.context = {}

function M.open()
    M.toggle()
end

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

function M.close()
    if M.context.vv then
        M.context.vv:hide()
        M.context.vv = nil
    end
end

function M.hide()
    if M.context.vv then
        M.context.vv:hide()
    end
end

function M.goto_previous_board()
    if M.context.vv then
        M.context.vv:previous_board()
    end
end

function M.goto_next_board()
    if M.context.vv then
        M.context.vv:next_board()
    end
end

function M.goto_board(index)
    if M.context.vv then
        M.context.vv:goto_board(index)
    end
end

function M.goto_previous_page()
    if M.context.vv then
        M.context.vv:previous_page()
    end
end

function M.goto_next_page()
    if M.context.vv then
        M.context.vv:next_page()
    end
end

function M.focus_first_list()
    if M.context.vv then
        M.context.vv:focus_first_list()
    end
end

function M.focus_previous_list()
    if M.context.vv then
        M.context.vv:focus_previous_list()
    end
end

function M.focus_center_list()
    if M.context.vv then
        M.context.vv:focus_center_list()
    end
end

function M.focus_next_list()
    if M.context.vv then
        M.context.vv:focus_next_list()
    end
end

function M.focus_last_list()
    if M.context.vv then
        M.context.vv:focus_last_list()
    end
end

function M.focus_first_entry()
    if M.context.vv then
        M.context.vv:focus_first_entry()
    end
end

function M.focus_previous_entry()
    if M.context.vv then
        M.context.vv:focus_previous_entry()
    end
end

function M.focus_next_entry()
    if M.context.vv then
        M.context.vv:focus_next_entry()
    end
end

function M.focus_last_entry()
    if M.context.vv then
        M.context.vv:focus_last_entry()
    end
end

function M.open_in_neovim()
    if M.context.vv then
        M.context.vv:open_in_neovim()
    end
end

function M.open_in_obsidian()
    if M.context.vv then
        M.context.vv:open_in_obsidian()
    end
end

function M.refresh_focused_entry_content()
    if M.context.vv then
        M.context.vv:refresh_focused_entry_content()
    end
end

function M.fast_refresh()
    if M.context.vv then
        M.context.vv:fast_refresh()
    end
end

function M.open_help()
    -- Get the absolute path to this Lua file
    local current_file = debug.getinfo(1, "S").source:sub(2)
    local help_path = vim.fn.fnamemodify(current_file, ":h:h:h") .. "/_doc/help_page.md" -- go up and in _doc
    -- print("Help path is: " .. help_path)
    vim.notify("Opening help page..." .. help_path, vim.log.levels.INFO)

    -- Open help window with Snacks
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
