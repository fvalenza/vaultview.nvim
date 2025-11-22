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
---@field config vaultview.Configuration The merged plugin configuration (defaults + user config)
---@field header_win vaultview.Window Header window object
---@field view_win vaultview.Window Main content window object
---@field boards_names string[] Names of all configured boards
---@field active_board_index integer Index of the currently active board
---@field VaultData table Parsed data structure used for rendering (the Model)
---@field views vaultview.View[] View instances (one per board)
---@field isDisplayed boolean|nil Whether the complete UI is currently shown

local VaultView = {}
VaultView.__index = VaultView

local Constants = require("vaultview._ui.constants")
local wf = require("vaultview._core.windowfactory")
local parsers = require("vaultview._core.parsers")
local View = require("vaultview._core.view")
local layouts = require("vaultview._core.view.layouts")

--- Create a new VaultView instance.
--
-- Builds:
-- - Windows
-- - VaultData model
-- - A View instance per board (Controller + Layout)
--
-- @param config vaultview.Configuration
-- @return vaultview.VaultView
function VaultView.new(config)
    local self = setmetatable({}, VaultView)

    self.config = config

    self.header_win, self.view_win = wf.create_header_and_view_windows()

    self.boards_names = {}
    self.active_board_index = 0
    self.VaultData = {
        boards = {},
    }

    -- Build VaultData for each board (MODEL)
    for _, board_config in ipairs(config.boards) do
        self.VaultData.boards.pages = {}

        local board_name = board_config.name or "board_" .. tostring(#self.boards_names + 1)
        table.insert(self.boards_names, board_name)

        -- Call parser to generate actual board data (entries, pages, lists)
        local boardData = parsers(board_config.parser)(config.vault, config.user_commands, board_config)

        local dataBoard = {
            title = board_name,
            pages = boardData,
        }

        table.insert(self.VaultData.boards, dataBoard)
    end

    -- Build VIEWS (one per board)
    self.views = {}
    for i, board_config in ipairs(config.boards) do
        local board_layout_config = board_config.viewlayout
        local viewlayout = type(board_layout_config) == "string" and layouts[board_layout_config]
            or error("Invalid layout type for " .. self.boards_names[i])

        -- TODO(roadmap)  create views lazily (when switching to a board that is not "loaded" (either array of bool "boards_loaded" or table boards_names to become boards = { {name="string", loaded=true/false}, {}, .. }
        self.views[i] = View.new(self.VaultData, i, board_config, viewlayout, self.header_win)
    end

    if config.boards and #config.boards > 0 then
        self.active_board_index = config.initial_board_idx or 1
    end

    return self
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
--- @param board_names string[] List of tabs names
--- @param width_available integer Total columns available in the header window
--- @param index_active_board integer Active board index
--- @return table lines Three rows of rendered UI text
--- @return table highlights Highlight groups + positions
local build_tabs = function(board_names, width_available, index_active_board)
    local activeBoardName = board_names[index_active_board]

    local total_str_w = -1
    for _, v in ipairs(board_names) do
        if v ~= "_pad_" then
            total_str_w = total_str_w + vim.api.nvim_strwidth(v) + 5
        end
    end

    local lines = { {}, {}, {} }
    local highlights = {}

    local datalen = #board_names
    local colpos = { 0, 0, 0 } -- track byte columns per line

    for i, v in ipairs(board_names) do
        if v == "_pad_" then
            local emptychar = string.rep(" ", width_available - total_str_w)
            for l = 1, 3 do
                table.insert(lines[l], { emptychar })
                colpos[l] = colpos[l] + #emptychar
            end
        else
            local hchar = string.rep("─", vim.api.nvim_strwidth(v) + 2)
            local row_text = {
                "┌" .. hchar .. "┐",
                "│ " .. v .. " │",
                "└" .. hchar .. "┘",
            }

            local hl = (activeBoardName == v and "TabActive") or "TabInactive"

            for l = 1, 3 do
                table.insert(lines[l], { row_text[l] })
                local byte_len = #row_text[l]

                table.insert(highlights, {
                    group = hl,
                    line = l - 1, -- 0-based for nvim_buf_add_highlight
                    start_col = colpos[l],
                    end_col = colpos[l] + byte_len,
                })

                colpos[l] = colpos[l] + byte_len
            end

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
    local lines, highlights = build_tabs(board_names, win_width, active_board_index)

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

    self.views[self.active_board_index].page_selection_line = page_selection_line
    self.views[self.active_board_index]:render()

    self.header_win:show()
    self.view_win:show()
end

--- Hide the entire UI.
function VaultView:hide()
    self.views[self.active_board_index]:hide()
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
    self.views[self.active_board_index]:open_in_obsidian(self.config.vault.name) -- TODO if here i dont give self.config.vault but self.config.vault.name, why in parsers i give vault and not vault.path ?
end

-- REFRESH API --------------------------------------------------------

--- Refresh content of the focused entry.
function VaultView:refresh_focused_entry_content()
    self.views[self.active_board_index]:refresh_focused_entry_content(self.config.user_commands) -- TODO: I should not have to give config.user_commands each time. find better way to have this config once (initialize_Data_if_needed...)
end

--- Fast refresh applied to all views.
function VaultView:fast_refresh()
    for _, view in ipairs(self.views) do
        view:fast_refresh()
    end
end

return VaultView
