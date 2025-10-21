local M = {}

M.generic = {
    ["q"] = { function() require("vaultview._commands.open.runner").run_close_board() end, mode = "n", noremap = true, nowait = true, },
    ["p"] = { function() require("vaultview._commands.open.runner").run_go_to_previous_board() end, mode = "n", noremap = true, nowait = true, },
    ["n"] = { function() require("vaultview._commands.open.runner").run_go_to_next_board() end, mode = "n", noremap = true, nowait = true, },
    ["<S-h>"] = { function() require("vaultview._commands.open.runner").run_go_to_previous_page() end, mode = "n", noremap = true, nowait = true, },
    ["<S-l>"] ={ function() require("vaultview._commands.open.runner").run_go_to_next_page() end, mode = "n", noremap = true, nowait = true, },
    ["1"] = { function() require("vaultview._commands.open.runner").run_go_to_board(1) end, mode = "n", noremap = true, nowait = true, },
    ["2"] = { function() require("vaultview._commands.open.runner").run_go_to_board(2) end, mode = "n", noremap = true, nowait = true, },
    ["3"] = { function() require("vaultview._commands.open.runner").run_go_to_board(3) end, mode = "n", noremap = true, nowait = true, },
    ["4"] = { function() require("vaultview._commands.open.runner").run_go_to_board(4) end, mode = "n", noremap = true, nowait = true, },
    ["5"] = { function() require("vaultview._commands.open.runner").run_go_to_board(5) end, mode = "n", noremap = true, nowait = true, },
    ["6"] = { function() require("vaultview._commands.open.runner").run_go_to_board(6) end, mode = "n", noremap = true, nowait = true, },
    ["7"] = { function() require("vaultview._commands.open.runner").run_go_to_board(7) end, mode = "n", noremap = true, nowait = true, },
    ["8"] = { function() require("vaultview._commands.open.runner").run_go_to_board(8) end, mode = "n", noremap = true, nowait = true, },
    ["9"] = { function() require("vaultview._commands.open.runner").run_go_to_board(9) end, mode = "n", noremap = true, nowait = true, },
    ["r"] = { function() require("vaultview._commands.open.runner").refresh() end, mode = "n", noremap = true, nowait = true, },
    ["<C-f>"] = { function() require("vaultview._commands.open.runner").run_pick_list() end, mode = "n", noremap = true, nowait = true, },
    ["f"] = { function() require("vaultview._commands.open.runner").run_pick_card() end, mode = "n", noremap = true, nowait = true, },
    ["F"] = { function() require("vaultview._commands.open.runner").run_pick_content() end, mode = "n", noremap = true, nowait = true, },
    ["<C-h>"] = { function() require("vaultview._commands.open.runner").run_open_help() end, mode = "n", noremap = true, nowait = true, },
}


M.ViewLayoutCarousel = {
    ["<M-h>"] = { function(layout) layout:move_focus_mostleft() end, mode = "n", noremap = true, nowait = true, },
    ["h"] = { function(layout) layout:move_focus_left() end, mode = "n", noremap = true, nowait = true, },
    ["c"] = { function(layout) layout:move_focus_center() end, mode = "n", noremap = true, nowait = true, },
    ["l"] = { function(layout) layout:move_focus_right() end, mode = "n", noremap = true, nowait = true, },
    ["<M-l>"] = { function(layout) layout:move_focus_mostright() end, mode = "n", noremap = true, nowait = true, },
    ["gg"] = { function(layout) layout:move_focus_mostup() end, mode = "n", noremap = true, nowait = true, },
    ["k"] = { function(layout) layout:move_focus_up() end, mode = "n", noremap = true, nowait = true, },
    ["j"] = { function(layout) layout:move_focus_down() end, mode = "n", noremap = true, nowait = true, },
    ["G"] = { function(layout) layout:move_focus_mostdown() end, mode = "n", noremap = true, nowait = true, },
    X = { function(layout) layout:toggle_expand_list() end, mode = "n", noremap = true, nowait = true, },
    x = { function(layout) layout:toggle_expand() end, mode = "n", noremap = true, nowait = true, },
    ["<CR>"] = { function(layout) layout:open_focused_in_nvim() end, mode = "n", noremap = true, nowait = true, },
    ["o"] = { function(layout) layout:open_focused_in_obsidian() end, mode = "n", noremap = true, nowait = true, },

}

return M
