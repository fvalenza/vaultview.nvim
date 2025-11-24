--- Main/Root class of the plugin
---@class vaultview.VaultView
-- For each board of the configuration, will parse the vault and create data structure necessery for rendering
-- VaultData is in the form:
-- -- VaultData = {
-- --     boards = {
-- --         {
-- --             title = "board name",
-- --             pages = {
-- --                 {
-- --                     title = "page title",
-- --                     lists = {
-- --                         {
-- --                             title = "list title",
-- --                             items = {
-- --                                 {
-- --                                     title = "entry title",
-- --                                     filepath = "path/to/file",
-- --                                     content = { "line1", "line2", ... },
-- --                                 },
-- --                                 ...
-- --                             },
-- --                         },
-- --                         ...
-- --                     },
-- --                 },
-- --                 ...
-- --             },
-- --         },
-- --         ...
-- --     },
-- -- }
-- After VaultData is built, will create one View per board for rendering, according to the layout specified in the configuration
-- The layout is the "strategy" on how to render things on screen (carousel, columns, ...)
-- The View is in charge of holding the data of the board to render, the state of the view (which page/list/entry
-- is focused, if the windows shall be expanded/collapsed, if they shall be shown/hidden, ...),
-- and the windows objects
-- One could consider that the plugin relies on a sort of MVC architecture:
-- - Model: VaultData
-- - View: ViewLayout
-- - Controller: View. Even if some of the logic is delegated to the viewLayout from the View class
-- This class VaultView is the root class that holds everything together
--
---@field _opts vaultview.Configuration The merged plugin configuration (defaults + user config)
---@field header_win snacks.win Header window object
---@field view_win snacks.win Main content window object
---@field boards_names string[] Names of all configured boards
---@field active_board_index integer Index of the currently active board
---@field VaultData table Parsed data structure used for rendering (the Model)
---@field views View[] View instances (one per board)
---@field isDisplayed boolean|nil Whether the complete UI is currently shown

local VaultView = {}
VaultView.__index = VaultView

local Constants = require("vaultview._ui.constants")
local wf = require("vaultview._core.windowfactory")
local parsers = require("vaultview._core.parsers")
local View = require("vaultview._core.view")
local layouts = require("vaultview._core.view.layouts")
local logging = require("mega.logging")
local _LOGGER = logging.get_logger("vaultview._core.vaultview")

--- Create a new VaultView instance. Lazy loads boards data and view until needed.
---
--- Builds:
--- - Windows
--- - VaultData model
--- - A View instance per board (Controller + Layout)
---
--- @return vaultview.VaultView
function VaultView.new()
    local self = setmetatable({}, VaultView)

    self._opts = require("vaultview").opts
    self.header_win, self.view_win = wf.create_header_and_view_windows()

    self.boards_names = {}
    self.active_board_index = 0

    self.VaultData = { boards = {} }
    self.views = {}

    -- Lazy loading trackers
    self.boards_data_loaded = {}
    self.boards_view_loaded = {}

    if not self._opts.boards or #self._opts.boards == 0 then
        table.insert(self.boards_names, "No board configured")
    end
    -- Collect board names only to display them in tabs, do NOT parse or create views
    for _, board_config in ipairs(self._opts.boards) do
        local board_name = board_config.name or "board_" .. tostring(#self.boards_names + 1)
        table.insert(self.boards_names, board_name)

        table.insert(self.VaultData.boards, nil)
        table.insert(self.views or {}, nil)
        table.insert(self.boards_data_loaded, false)
        table.insert(self.boards_view_loaded, false)
    end

    -- Initialize first board immediately
    if self._opts.boards and #self._opts.boards > 0 then
        self.active_board_index = self._opts.initial_board_idx or 1
        if self.active_board_index < 1 or self.active_board_index > #self.boards_names then
            self.active_board_index = 1
        end
        self:ensureBoardLoaded(self.active_board_index)
    end

    return self
end

--- Ensure that both data and view for board index i are loaded.
--- @param i integer Board index
function VaultView:ensureBoardLoaded(i)
    local board_config = self._opts.boards[i]

    ------------------------------------------------------------------
    -- LOAD DATA (call to parser)
    ------------------------------------------------------------------
    if not self.boards_data_loaded[i] then
        local parser = parsers(board_config.parser)
        local boardData = parser(self._opts.vault, board_config)

        self.VaultData.boards[i] = {
            title = self.boards_names[i],
            pages = boardData,
        }

        self.boards_data_loaded[i] = true
    end

    ------------------------------------------------------------------
    -- CREATE VIEW
    ------------------------------------------------------------------
    if not self.boards_view_loaded[i] then
        local layout_spec = board_config.viewlayout
        local viewlayout = type(layout_spec) == "string" and layouts[layout_spec]
            or error("Invalid layout type for " .. self.boards_names[i])

        self.views[i] = View.new(self.VaultData.boards[i], i, viewlayout, self.header_win)

        self.boards_view_loaded[i] = true
    end
end

--- Show the whole VaultView interface.
function VaultView:show()
    self:render()
    self.isDisplayed = true
end

--- Build the 3-lines corresponding of the top of the header_view (each border_name being surrounded by border Internal helper to construct tab UI for the header.
--- For each entry of the list of tabs
--- ┌────────┐
--- │  text  │
--- └────────┘
--- Adds hint if configured to do so
--- @param board_names string[] List of tabs names
--- @param width_available integer Total columns available in the header window
--- @param index_active_board integer Active board index
--- @param display_tabs_hint boolean Whether to display hints for tab navigation
--- @return table lines Three rows of rendered UI text
--- @return table highlights Highlight groups + positions
local build_tabs = function(board_names, width_available, index_active_board, display_tabs_hint)
    local activeBoardName = board_names[index_active_board]

    ---------------------------------------------------------------------
    -- Compute total width
    ---------------------------------------------------------------------
    local total_str_w = -1
    for i, name in ipairs(board_names) do
        if name ~= "_pad_" then
            local is_settings = (name == "Settings")

            local hint = ""
            if display_tabs_hint then
                hint = is_settings and " (?)" or ("(" .. i .. ")")
            end

            total_str_w = total_str_w + vim.api.nvim_strwidth(hint .. name) + 5
        end
    end

    local lines = { {}, {}, {} }
    local highlights = {}
    local datalen = #board_names
    local colpos = { 0, 0, 0 }

    for i, name in ipairs(board_names) do
        if name == "_pad_" then
            -----------------------------------------------------------------
            -- Padding
            -----------------------------------------------------------------
            local emptychar = string.rep(" ", width_available - total_str_w)
            for l = 1, 3 do
                table.insert(lines[l], { emptychar })
                colpos[l] = colpos[l] + #emptychar
            end

        else
            -----------------------------------------------------------------
            -- Build HINT (conditionally)
            -----------------------------------------------------------------
            local is_settings = (name == "Settings")

            local hint = ""
            if display_tabs_hint then
                hint = is_settings and " (?)" or ("(" .. i .. ")")
            end

            local full_label = hint .. name
            local full_width = vim.api.nvim_strwidth(full_label)

            local hchar = string.rep("─", full_width + 2)

            -----------------------------------------------------------------
            -- Build the 3 text rows
            -----------------------------------------------------------------
            local row_text = {
                "┌" .. hchar .. "┐",
                "│ " .. full_label .. " │",
                "└" .. hchar .. "┘",
            }

            local hl_tab = (activeBoardName == name) and "TabActive" or "TabInactive"

            -----------------------------------------------------------------
            -- Capture tab start col (display column)
            -----------------------------------------------------------------
            local tab_start_col = colpos[2]

            -----------------------------------------------------------------
            -- Insert row text + whole-tab highlight
            -----------------------------------------------------------------
            for l = 1, 3 do
                local text = row_text[l]
                local byte_len = #text

                table.insert(lines[l], { text })

                table.insert(highlights, {
                    group = hl_tab,
                    line = l - 1,
                    start_col = colpos[l],
                    end_col = colpos[l] + byte_len,
                })

                colpos[l] = colpos[l] + byte_len
            end

            -----------------------------------------------------------------
            -- Conditionally highlight the hint portion
            -----------------------------------------------------------------
            if display_tabs_hint and hint ~= "" then
                local left_border_visual = vim.api.nvim_strwidth("│ ")
                local hint_visual_len = vim.api.nvim_strwidth(hint)

                local hint_start_col = tab_start_col + left_border_visual + 1
                local hint_end_col = hint_start_col + hint_visual_len + 1

                table.insert(highlights, {
                    group = "TabHint",
                    line = 1,
                    start_col = hint_start_col,
                    end_col = hint_end_col,
                })
            end

            -----------------------------------------------------------------
            -- Space between tabs
            -----------------------------------------------------------------
            if i ~= datalen then
                for l = 1, 3 do
                    table.insert(lines[l], { " " })
                    colpos[l] = colpos[l] + 1
                end
            end
        end
    end

    return lines, highlights
end

--- Render the top board-selection header.
--
-- Constructs and writes:
-- - Board tabs
-- - Settings tab
-- - Highlight groups
--
-- @return integer The number of lines used by the board_selection header (used by views)
function VaultView:render_board_selection()
    local win = self.header_win
    local board_names = vim.deepcopy(self.boards_names)
    local active_board_index = self.active_board_index
    local buf = win.buf

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local dims = win:size()
    local win_width = dims.width

    board_names = vim.list_extend(board_names, { "_pad_", "Settings" })
    local lines, highlights = build_tabs(board_names, win_width, active_board_index, self._opts.hints.board_navigation)

    local flat_lines = {}
    for _, row in ipairs(lines) do
        local str_parts = {}
        for _, cell in ipairs(row) do
            table.insert(str_parts, cell[1]) -- extract the actual text
        end
        table.insert(flat_lines, table.concat(str_parts))
    end

    table.insert(flat_lines, string.rep("─", vim.o.columns))
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, flat_lines)

    -- Apply highlights
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(buf, -1, h.group, h.line, h.start_col, h.end_col)
    end

    vim.api.nvim_buf_add_highlight(buf, -1, "TabSeparator", 3, 0, -1)

    vim.bo[buf].modifiable = false
    return #flat_lines -- number of header lines (so we know where to start the next section)
end

--- Render the entire UI (header + active view).
function VaultView:render()
    local page_selection_line = self:render_board_selection()

    self.header_win:show()
    self.view_win:show()
    if self.active_board_index == 0 then
        return
    end
    self.views[self.active_board_index].page_selection_line = page_selection_line
    self.views[self.active_board_index]:render()

end

--- Hide the entire UI.
function VaultView:hide()
    if self.active_board_index ~= 0 then
        self.views[self.active_board_index]:hide()
    end
    if self.header_win then
        self.header_win:hide()
    end
    if self.view_win then
        self.view_win:hide()
    end
    self.isDisplayed = false
end

-- BOARD NAVIGATION --------------------------------------------------------

--- Switch to a specific board by index.
-- @param index integer
function VaultView:goto_board(index)
    if index == self.active_board_index then
        return
    end
    if index >= 1 and index <= #self.boards_names then
        self:hide()
        self.active_board_index = index

        -- LAZY LOAD if not loaded
        self:ensureBoardLoaded(self.active_board_index)

        self:render()
    end
end

--- Go to the previous board (cyclic).
function VaultView:previous_board()
    if #self.boards_names == 1 then
        return
    end

    self:hide()

    self.active_board_index = self.active_board_index - 1
    if self.active_board_index < 1 then
        self.active_board_index = #self.boards_names
    end

    -- LAZY LOAD if not loaded
    self:ensureBoardLoaded(self.active_board_index)

    self:render()
end

--- Go to the next board (cyclic).
function VaultView:next_board()
    if #self.boards_names == 1 then
        return
    end

    self:hide()
    self.active_board_index = self.active_board_index + 1
    if self.active_board_index > #self.boards_names then
        self.active_board_index = 1
    end

    -- LAZY LOAD if not loaded
    self:ensureBoardLoaded(self.active_board_index)

    self:render()
end

-- PAGE NAVIGATION ---------------------------------------------------------

--- Go to previous page of the active board.
function VaultView:previous_page()
    self.views[self.active_board_index]:previous_page()
end

--- Go to next page of the active board.
function VaultView:next_page()
    self.views[self.active_board_index]:next_page()
end

-- LIST NAVIGATION ---------------------------------------------------------

function VaultView:focus_first_list()
    self.views[self.active_board_index]:focus_first_list()
end
function VaultView:focus_previous_list()
    self.views[self.active_board_index]:focus_previous_list()
end
function VaultView:focus_center_list()
    self.views[self.active_board_index]:focus_center_list()
end
function VaultView:focus_next_list()
    self.views[self.active_board_index]:focus_next_list()
end
function VaultView:focus_last_list()
    self.views[self.active_board_index]:focus_last_list()
end

-- ENTRY NAVIGATION --------------------------------------------------------

function VaultView:focus_first_entry()
    self.views[self.active_board_index]:focus_first_entry()
end
function VaultView:focus_previous_entry()
    self.views[self.active_board_index]:focus_previous_entry()
end
function VaultView:focus_next_entry()
    self.views[self.active_board_index]:focus_next_entry()
end
function VaultView:focus_last_entry()
    self.views[self.active_board_index]:focus_last_entry()
end
function VaultView:focus_previous_entry_page()
    self.views[self.active_board_index]:focus_previous_entry_page()
end
function VaultView:focus_next_entry_page()
    self.views[self.active_board_index]:focus_next_entry_page()
end

--- Focus an entry by its unique ID.
-- @param entry_id string|integer
function VaultView:focus_entry_with_id(entry_id)
    self.views[self.active_board_index]:focus_entry_with_id(entry_id)
end

--- Focus a list by its unique ID.
-- @param entry_id string|integer
function VaultView:focus_list_with_id(entry_id)
    self.views[self.active_board_index]:focus_list_with_id(entry_id)
end

-- ENTRY's FILE OPENING --------------------------------------------------------

--- Open focused entry in a Neovim buffer.
function VaultView:open_in_neovim()
    self.views[self.active_board_index]:open_in_neovim()
end

--- Open focused entry in Obsidian.
function VaultView:open_in_obsidian()
    self.views[self.active_board_index]:open_in_obsidian()
end

-- REFRESH API --------------------------------------------------------

--- Refresh content of the focused entry.
function VaultView:refresh_focused_entry_content()
    self.views[self.active_board_index]:refresh_focused_entry_content()
end

--- Fast refresh applied to all views.
function VaultView:fast_refresh()
    for _, view in ipairs(self.views) do
        view:fast_refresh()
    end
end

return VaultView
