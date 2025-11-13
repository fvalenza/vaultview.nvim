local M = {}

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")
local Keymaps = require("vaultviewui.keymaps")

function M.create_window(opts)
    local opts = opts
    opts.show = true
    local win = Snacks.win(opts)
    win:hide()
    return win
end

function M.close_window(window)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_close(window.win, true)
    end
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.api.nvim_buf_delete(window.buf, { force = true })
    end
end

function M.setNewContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, lines)
    end
end

function M.appendContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        local line_count = vim.api.nvim_buf_line_count(window.buf)
        vim.api.nvim_buf_set_lines(window.buf, line_count, -1, false, lines)
    end
end

function M.create_header_and_view_windows()
    local header_win = M.create_window({
        width = Constants.header_win.width,
        height = Constants.header_win.height,
        zindex = Constants.header_win.zindex,
        border = "none",
        relative = "editor",
        row = 0,
        col = 0,
        text = "header_win",
        show = true,
        focusable = false,
        -- enter = false,
    })

    local view_win = M.create_window({
        width = Constants.view_win.width,
        height = Constants.view_win.height,
        zindex = Constants.view_win.zindex,
        border = "none",
        relative = "editor",
        row = Constants.view_win.row, -- TODO due to tabline the +1...
        col = 0,
        text = "",
        show = true,
        focusable = false,
        -- enter = false,
    })

    return header_win, view_win
end

local function create_entry_window(entry, layout)
    local class_name = layout.name()
    local cfg = Constants.card_win[class_name]

    local card_win = Snacks.win({
        width = cfg.width,
        height = cfg.height,
        zindex = cfg.zindex,
        -- border = cfg.border,
        border = "rounded",
        relative = "editor",
        row = cfg.row, -- align all lists at top of view_win
        col = cfg.col, -- at creation, put them all at the top left. will be recomputed in render function
        text = entry.content,
        title = entry.title,
        show = true,
        -- enter = false,
        enter = true,
        backdrop = false,
        focusable = true,
        keys = Keymaps.generic,
        bo = { modifiable = true },
        -- bo = { modifiable = true, filetype = filetype },
    })
    card_win:hide()

    return card_win
end

-- Helper: create a list "title" window (container for its items)
local function create_list_window(list, layout)
    local class_name = layout.name()
    local cfg = Constants.list_win[class_name]

    local list_win = Snacks.win({
        width = cfg.width,
        height = cfg.height,
        zindex = cfg.zindex,
        -- border = cfg.border,
        border = "rounded",
        relative = "editor",
        row = cfg.row, -- align all lists at top of view_win
        col = cfg.col, -- at creation, put them all at the top left. will be recomputed in render function
        show = true,
        -- enter = false,
        enter = true,
        backdrop = false,
        focusable = true,
        keys = Keymaps.generic,
        bo = { modifiable = true },
        -- bo = { modifiable = true, filetype = filetype },
    })
    list_win:hide()

    return list_win
end

function M.create_board_view_windows(VaultData, board_idx, layout)
    local board = VaultData.boards[board_idx]
    if not board then
        error("Board index " .. board_idx .. " not found in VaultData")
    end

    local pages_names = {}
    local windows = { pages = {} }

    for p_idx, page in ipairs(board.pages or {}) do
        local page_windows = { lists = {} }
        local page_name = page.title or "page_" .. tostring(p_idx)

        for l_idx, list in ipairs(page.lists or {}) do
            local list_win = create_list_window(list, layout)
            local list_windows = {
                win = list_win,
                items = {},
            }

            for i_idx, item in ipairs(list.items or {}) do
                local item_window = create_entry_window(item, layout)
                table.insert(list_windows.items, item_window)
            end

            table.insert(page_windows.lists, list_windows)
        end

        table.insert(pages_names, page_name)
        table.insert(windows.pages, page_windows)
    end

    return pages_names, windows
end

local function set_keymap(layout, class_name)
    local map = {}

    for k, v in pairs(Keymaps.generic) do
        map[k] = v
    end


    return map
end

-- local function set_keymap(layout, class_name)
--     local map = {}
--
--     for k, v in pairs(Keymaps.generic) do
--         map[k] = v
--     end
--
--     for k, v in pairs(Keymaps[class_name]) do
--         map[k] = { function() v[1](layout) end, mode = v.mode, noremap = v.noremap, nowait = v.nowait }
--     end
--
--     return map
-- end
return M
