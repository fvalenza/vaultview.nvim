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
        vim.bo[window.buf].modifiable = true
        vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, lines)
        vim.bo[window.buf].modifiable = true
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
        row = Constants.view_win.row,
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
        border = cfg.border,
        relative = "editor",
        row = cfg.row, -- align all windows at top of view_win
        col = cfg.col, -- at creation, put them all at the top left. will be recomputed in render function
        text = entry.content,
        title = entry.title,
        show = true,
        enter = true,
        backdrop = false,
        focusable = true,
        keys = Keymaps.generic,
        -- bo = { modifiable = true, filetype = "markdown" }, -- FIXME this causes performance issues ?
        bo = { modifiable = true },
    })
    -- TODO(roadmap) highlight focused/unfocused entry windows either with events here or autocommands ? Or force highlight manually at each focus/unfocus
    -- vim.api.nvim_set_option_value("winhighlight", "Normal:EntryWindowInactive", { win = card_win.win })
    --
    -- card_win:on({ "BufEnter" }, function()
    --     vim.notify("Entry window focused: ")
    --     vim.api.nvim_set_option_value("winhighlight", "Normal:EntryWindowActive", { win = card_win.win })
    -- end, { buf = true })
    --
    -- card_win:on({ "BufLeave" }, function()
    --     vim.notify("Leaving window focused: ")
    --     vim.api.nvim_set_option_value("winhighlight", "Normal:EntryWindowInactive", { win = card_win.win })
    -- end, { buf = true })

    -- card_win:on("WinEnter", function()
    --     local winid = card_win.id
    --     vim.notify("Entry window focused: " .. tostring(winid))
    --     require("vaultviewui").focus_entry_with_id(winid)
    -- end)
    -- TODO(roadmap) end of my tries

    card_win:hide()

    return card_win
end

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
        enter = false,
        backdrop = false,
        focusable = true,
        keys = Keymaps.generic,
        -- bo = { modifiable = true, filetype = "markdown" }, -- FIXME this causes performance issues ?
        bo = { modifiable = true },
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
    local pages_state = {}

    for p_idx, page in ipairs(board.pages or {}) do
        --------------------------------------------------------
        -- Create state table for this page
        --------------------------------------------------------
        pages_state[p_idx] = {
            lists_visibility = { first = 0, last = 0, length = 0 },
            lists = {},
        }
        --------------------------------------------------------
        -- Create windows table
        --------------------------------------------------------
        local page_windows = { lists = {} }
        local page_name = page.title or ("page_" .. tostring(p_idx))

        for l_idx, list in ipairs(page.lists or {}) do
            --------------------------------------------------------------------
            -- Build list pagination
            --------------------------------------------------------------------
            local class_name = layout.name()
            local list_win_cfg = Constants.list_win[class_name]
            local card_win_cfg = Constants.card_win[class_name]
            local num_entries_in_list = #list.items or 0
            local max_entries_per_list_page = math.floor(list_win_cfg.height / (card_win_cfg.height + 1 + 1)) -- +1 = top border of card_win, + 1 = space between cards
            local num_pages_needed = math.ceil(num_entries_in_list / max_entries_per_list_page)

            local list_pages = {}

            for page_start = 1, num_entries_in_list, max_entries_per_list_page do
                local page_end = math.min(page_start + max_entries_per_list_page - 1, num_entries_in_list)
                table.insert(list_pages, {
                    start = page_start,
                    stop = page_end,
                })
            end

            --------------------------------------------------------------------
            -- Build list-level state object
            --------------------------------------------------------------------
            pages_state[p_idx].lists[l_idx] = {
                expanded = true,
                show = true,
                entries_visibility = { first = 0, last = 0, length = 0 },
                items = {},
                list_pages = list_pages,
                current_page = 1,
            }

            --------------------------------------------------------------------
            -- Create list window
            --------------------------------------------------------------------
            local list_win = create_list_window(list, layout)
            local list_windows = {
                win = list_win,
                items = {},
            }

            --------------------------------------------------------------------
            -- Iterate items
            --------------------------------------------------------------------
            for i_idx, item in ipairs(list.items or {}) do
                -- Add item-level state
                pages_state[p_idx].lists[l_idx].items[i_idx] = {
                    expanded = true,
                    show = true,
                }

                -- Create window for the item
                local item_window = create_entry_window(item, layout)
                table.insert(list_windows.items, item_window)
            end

            table.insert(page_windows.lists, list_windows)
        end

        --------------------------------------------------------
        -- Add page
        --------------------------------------------------------
        table.insert(pages_names, page_name)
        table.insert(windows.pages, page_windows)
    end

    return pages_names, windows, pages_state
end

return M
