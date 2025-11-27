--- Helper class to wrap functionalities over Windows creation
-- Here in case i want to change the window manager lib later (removing snacks or using another one)
local M = {}

--- HACK: Taken from snacks.nvim types to avoid LSP errors...

---@class snacks.win.Config: vim.api.keyset.win_config
---@field style? string merges with config from `Snacks.config.styles[style]`
---@field show? boolean Show the window immediately (default: true)
---@field footer_keys? boolean|string[] Show keys footer. When string[], only show those keys with lhs (default: false)
---@field height? number|fun(self:snacks.win):number Height of the window. Use <1 for relative height. 0 means full height. (default: 0.9)
---@field width? number|fun(self:snacks.win):number Width of the window. Use <1 for relative width. 0 means full width. (default: 0.9)
---@field min_height? number Minimum height of the window
---@field max_height? number Maximum height of the window
---@field min_width? number Minimum width of the window
---@field max_width? number Maximum width of the window
---@field col? number|fun(self:snacks.win):number Column of the window. Use <1 for relative column. (default: center)
---@field row? number|fun(self:snacks.win):number Row of the window. Use <1 for relative row. (default: center)
---@field minimal? boolean Disable a bunch of options to make the window minimal (default: true)
---@field position? "float"|"bottom"|"top"|"left"|"right"|"current"
---@field border? "none"|"top"|"right"|"bottom"|"left"|"top_bottom"|"hpad"|"vpad"|"rounded"|"single"|"double"|"solid"|"shadow"|"bold"|string[]|false|true
---@field buf? number If set, use this buffer instead of creating a new one
---@field file? string If set, use this file instead of creating a new buffer
---@field enter? boolean Enter the window after opening (default: false)
---@field backdrop? number|false|snacks.win.Backdrop Opacity of the backdrop (default: 60)
---@field wo? vim.wo|{} window options
---@field bo? vim.bo|{} buffer options
---@field b? table<string, any> buffer local variables
---@field w? table<string, any> window local variables
---@field ft? string filetype to use for treesitter/syntax highlighting. Won't override existing filetype
---@field scratch_ft? string filetype to use for scratch buffers
---@field keys? table<string, false|string|fun(self: snacks.win)|snacks.win.Keys> Key mappings
---@field on_buf? fun(self: snacks.win) Callback after opening the buffer
---@field on_win? fun(self: snacks.win) Callback after opening the window
---@field on_close? fun(self: snacks.win) Callback after closing the window
---@field fixbuf? boolean don't allow other buffers to be opened in this window
---@field text? string|string[]|fun():(string[]|string) Initial lines to set in the buffer
---@field actions? table<string, snacks.win.Action.spec> Actions that can be used in key mappings
---@field resize? boolean Automatically resize the window when the editor is resized
---@field stack? boolean When enabled, multiple split windows with the same position will be stacked together (useful for terminals)

---@class snacks.win
---@field id number
---@field buf? number
---@field scratch_buf? number
---@field win? number
---@field opts snacks.win.Config
---@field augroup? number
---@field backdrop? snacks.win
---@field keys snacks.win.Keys[]
---@field events (snacks.win.Event|{event:string|string[]})[]
---@field meta table<string, any>
---@field closed? boolean
---@overload fun(opts? :snacks.win.Config|{}): snacks.win

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local logging = require("mega.logging")
local _LOGGER = logging.get_logger("vaultview._core.windowfactory")

--- Wrapper to create a snacks window with default options for vaultview.nvim
---@param opts snacks.win.Config The snacks window options
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
---@param window snacks.win The snacks window object
---@param lines table Array of lines to set in the buffer
function M.setNewContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.bo[window.buf].modifiable = true
        vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, lines)
        vim.bo[window.buf].modifiable = true
    end
end

--- Erase all content from the window buffer (sets it to a single empty line).
---@param window snacks.win The snacks window object
function M.eraseContent(window)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.bo[window.buf].modifiable = true
        vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, { "" })
        vim.bo[window.buf].modifiable = false
    end
end

--- Append content in the window buffer
---@param window snacks.win The snacks window object
---@param lines table Array of lines to set in the buffer
function M.appendContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        local line_count = vim.api.nvim_buf_line_count(window.buf)
        vim.api.nvim_buf_set_lines(window.buf, line_count, -1, false, lines)
    end
end


--- Create windows for main background of vaultview.nvim plugin : header (to display available boards on pages in board)
--- and view (to display lists and entries)
---@return snacks.win header_win The created Snacks window object for the header area
---@return snacks.win view_win The created Snacks window object for the view area
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
        keys = { q = false},
        -- enter = false,
    })
    vim.bo[header_win.buf].filetype = "vaultview"

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
        keys = { q = false},
        -- enter = false,
    })
    vim.bo[view_win.buf].filetype = "vaultview"

    return header_win, view_win
end

--- Create a snacks window for an entry of a list
---@param entry table The entry data  from parsed VaultData
---@param layout ViewLayoutColumns|ViewLayoutCarousel The layout in which this entry window will be displayed
---@return snacks.win card_win The created Snacks window object
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
        keys = { q = false},
        -- bo = { modifiable = true, filetype = "markdown" }, -- FIXME this causes performance issues ?
        bo = { modifiable = true },
    })
    vim.bo[card_win.buf].filetype = "vaultview"

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
---@param list table The list data from parsed VaultData
---@param layout ViewLayoutColumns|ViewLayoutCarousel The layout in which this list window will be displayed
---@return snacks.win list_win The created Snacks window object
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
        keys = { q = false},
        -- bo = { modifiable = true, filetype = "markdown" }, -- FIXME this causes performance issues ?
        bo = { modifiable = true },
    })
    vim.bo[list_win.buf].filetype = "vaultview"
    list_win:hide()

    return list_win
end

--- Create all window for a board view (lists and entries for all pages of a board)
--- @param viewData table The data for the board view (pages → lists → items)
--- @param layout ViewLayoutCarousel|ViewLayoutColumns The layout in which this board will be displayed
--- @return table pages_names The names of the pages in the board
--- @return table windows The created windows structure for the board
--- @return table pages_state The initial state structure for the board
function M.create_board_view_windows(viewData, layout)
    if not viewData then
        _LOGGER:error("Cannot create viewData view windows: viewData data not available")
        return {}, {}, {}
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
