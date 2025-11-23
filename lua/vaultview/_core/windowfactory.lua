--- Helper class to wrap functionalities over Windows creation
-- Here in case i want to change the window manager lib later (removing snacks or using another one)
local M = {}

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local Keymaps = require("vaultview.keymaps")


--- Wrapper to create a snacks window with default options for vaultview.nvim
---@param opts snacks.win.opts The snacks window options
---@return snacks.win win The created Snacks window object
function M.create_window(opts)
    local opts = opts
    opts.show = true
    local win = Snacks.win(opts)
    win:hide()
    return win
end

-- function M.close_window(window)
--     if window and vim.api.nvim_win_is_valid(window.win) then
--         vim.api.nvim_win_close(window.win, true)
--     end
--     if window and vim.api.nvim_buf_is_valid(window.buf) then
--         vim.api.nvim_buf_delete(window.buf, { force = true })
--     end
-- end

--- Set new content in the window buffer. Erases previous content.
---@param window The snacks window object
---@param lines Array of lines to set in the buffer
function M.setNewContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.bo[window.buf].modifiable = true
        vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, lines)
        vim.bo[window.buf].modifiable = true
    end
end

--- Append content in the window buffer
---@param window The snacks window object
---@param lines Array of lines to append in the buffer
function M.appendContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        local line_count = vim.api.nvim_buf_line_count(window.buf)
        vim.api.nvim_buf_set_lines(window.buf, line_count, -1, false, lines)
    end
end

--- Create windows for main background of vaultview.nvim plugin : header (to display available boards on pages in board)
--- and view (to display lists and entries)
---@return header_win snacks.win The created Snacks window object for the header area
---@return view_win snacks.win The created Snacks window object for the view area
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

--- Create a snacks window for an entry of a list
---@param entry [TABLE] The entry data  from parsed VaultData
---@param layout [CLASS] The layout in which this entry window will be displayed
---@return card_win The created Snacks window object
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
    --     require("vaultview").focus_entry_with_id(winid)
    -- end)
    -- TODO(roadmap) end of my tries

    card_win:hide()

    return card_win
end

--- create a snacks window for a list in a board page
---@param list [TABLE] The list data from parsed VaultData
---@param layout [CLASS] The layout in which this list window will be displayed
---@return list_win The created Snacks window object
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

--- Create all window for a board view (lists and entries for all pages of a board)
--- @param viewData [TABLE] The data for the board view (pages → lists → items)
--- @param layout [CLASS] The layout in which this board will be displayed
--- @return [TABLE] pages_names The names of the pages in the board
--- @return [TABLE] windows The created windows structure for the board
--- @return [TABLE] pages_state The initial state structure for the board

function M.create_board_view_windows(viewData, layout)
    if not viewData then
        error("Cannot create viewData view windows: viewData data not available")
    end

    local pages_names = {}
    local windows = { pages = {} }
    local pages_state = {}

    for p_idx, page in ipairs(viewData.pages or {}) do
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
