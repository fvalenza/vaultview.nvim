local A = {}

local function define(name, fn)
    local plug = "<Plug>(VaultView" .. name .. ")"
    vim.keymap.set("n", plug, fn, { silent = true, noremap = true })
    A[name] = plug
end

-- actions
define( "Hide", function() require("vaultview").hide() end)
define( "PreviousPage", function() require("vaultview").goto_previous_page() end)
define( "NextPage", function() require("vaultview").goto_next_page() end)
define( "PreviousBoard", function() require("vaultview").goto_previous_board() end)
define( "NextBoard", function() require("vaultview").goto_next_board() end)
define( "Board1", function() require("vaultview").goto_board(1) end)
define( "Board2", function() require("vaultview").goto_board(2) end)
define( "Board3", function() require("vaultview").goto_board(3) end)
define( "Board4", function() require("vaultview").goto_board(4) end)
define( "Board5", function() require("vaultview").goto_board(5) end)
define( "Board6", function() require("vaultview").goto_board(6) end)
define( "Board7", function() require("vaultview").goto_board(7) end)
define( "Board8", function() require("vaultview").goto_board(8) end)
define( "Board9", function() require("vaultview").goto_board(9) end)
define( "Help", function() require("vaultview").open_help() end)
define( "RefreshEntry", function() require("vaultview").refresh_focused_entry_content() end)
define( "FastRefresh", function() require("vaultview").fast_refresh() end)
-- define( "PickList", function() require("vaultview._commands.open.runner").run_pick_list() end)
-- define( "PickEntry", function() require("vaultview._commands.open.runner").run_pick_card() end)
-- define( "PickContent", function() require("vaultview._commands.open.runner").run_pick_content() end)
define( "FirstList", function() require("vaultview").focus_first_list() end)
define( "PreviousList", function() require("vaultview").focus_previous_list() end)
define( "CenterList", function() require("vaultview").focus_center_list() end)
define( "NextList", function() require("vaultview").focus_next_list() end)
define( "LastList", function() require("vaultview").focus_last_list() end)
define( "FirstEntry", function() require("vaultview").focus_first_entry() end)
define( "PreviousEntry", function() require("vaultview").focus_previous_entry() end)
define( "NextEntry", function() require("vaultview").focus_next_entry() end)
define( "LastEntry", function() require("vaultview").focus_last_entry() end)
define( "PreviousPageInList", function() require("vaultview").focus_previous_entry_page() end)
define( "NextPageInList", function() require("vaultview").focus_next_entry_page() end)
define( "OpenInNeovim", function() require("vaultview").open_in_neovim() end)
define( "OpenInObsidian", function() require("vaultview").open_in_obsidian() end)

return A
