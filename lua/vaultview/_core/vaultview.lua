local VaultView = {}
VaultView.__index = VaultView

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local Board = require("vaultview._core.board")
local tutils = require("vaultview._core.utils.table_utils")
local logging = require("mega.logging")
local _LOGGER = logging.get_logger("vaultview._core.vaultview")
local layouts = require("vaultview._core.viewlayouts")
local parsers = require("vaultview._core.parsers")



function VaultView:create_vaultview_windows()
    self.board_selection_win = Snacks.win({
        width = Constants.boards_win.width,
        height = Constants.boards_win.height,
        zindex = Constants.boards_win.zindex,
        border = "rounded",
        relative = "editor",
        row = 0,
        col = 0,
        text = "",
        show = true,
        focusable = false,
        on_buf = function() end,
    })

    self.board_selection_win:hide()

    self.pages_win = Snacks.win({
        width = Constants.pages_win.width,
        height = Constants.pages_win.height,
        zindex = Constants.pages_win.zindex,
        border = "rounded",
        relative = "editor",
        row = Constants.pages_win.row,
        col = Constants.pages_win.col,
        text = "",
        show = true,
        focusable = false,
    })
    self.pages_win:hide()

    self.views_win = Snacks.win({
        width = Constants.views_win.width,
        height = Constants.views_win.height,
        zindex = Constants.views_win.zindex,
        border = "rounded",
        relative = "editor",
        row = Constants.views_win.row,
        col = Constants.views_win.col,
        text = "",
        show = false,
        focusable = false,
    })
end

-- local config = {
--     -- markdown_dir = "~/mboard/daily",
--     markdown_dir = "~/mboard",
--     vault = {
--         path = "/home/fvalenza/root-filetree/devel/myVault",
--         -- path = "/home/fvalenza/mboard/daily/",
--         name = "myVault",
--     },
--     boards = {
--         {
--             name = "dailyBoard",
--             parser = "daily",
--             viewlayout = "carousel",
--             daily_notes_folder = "vault/0-dailynotes", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
--             daily_note_pattern = "%d%d%d%d%-%d%d%-%d%d.md", -- pattern to identify daily notes, currently not used because hardcoded in daily_parser.lua
--             -- show_empty_months = false,
--         },
--         {
--             name = "dailyBoard2",
--             parser = "daily",
--             viewlayout = "carousel",
--             daily_notes_folder = "vault/0-dailynotes", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
--             daily_note_pattern = "%d%d%d%d%-%d%d%-%d%d.md", -- pattern to identify daily notes, currently not used because hardcoded in daily_parser.lua
--             -- show_empty_months = false,
--         },
--         {
--             name = "mocBoard",
--             parser = "moc",
--             viewlayout = "columns",
--             note_folder_mode = true,
--             pattern = "vault/1-MOCs/*.md", -- could be "subdir/*" or "yyyy-mm-dd.md" or "moc-*.md"
--             file_title = "strip-moc", -- TODO: could be "date" or "basename" or "strip-moc". Currently the moc parser always strips because for MY needs it's prettier
--         },
--     },
-- }

function VaultView.new(config)
-- function VaultView.new()
    local self = setmetatable({}, VaultView)
    print("Creating VaultView")
    _LOGGER:debug("Creating VaultView")

    self:create_vaultview_windows()

    self.boards_title = {}
    self.boards = {}
    self.active_board_index = 0

    for _, board_config in ipairs(config.boards) do
        local board_name = board_config.name or "board_" .. tostring(#self.boards + 1)
        table.insert(self.boards_title, board_name)

        local parserEntryPoint = parsers(board_config.parser)
        local boardData = parserEntryPoint(config.vault, board_config)
        local context = {
            vaultview = self,
        }

        local layoutField = board_config.viewlayout
        local board_viewlayout = type(layoutField) == "string" and layouts[layoutField]
            or error("Invalid layout type for " .. board_name)

        local board = Board.new(board_name, boardData, board_viewlayout, self.pages_win, context)

        table.insert(self.boards, board)

        self.active_board_index = 1
    end


    return self
end

-- TODO these 3 functions and in new, have table of boards + index of active board. See how pages are done in board.lua
function VaultView:go_to_board(index)
    if index < 1 or index > #self.boards then
        -- vim.notify("Invalid board index: " .. tostring(index), vim.log.levels.WARN)
        return
    end

    if index == self.active_board_index then
        return -- already on this board
    end

    -- hide current board
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:hide()
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end

    -- update active board index
    self.active_board_index = index

    self:render()
end

function VaultView:go_to_next_board()
    local new_index = self.active_board_index + 1
    if new_index < 1 then
        new_index = #self.boards -- wrap leftover
    elseif new_index > #self.boards then
        new_index = 1 -- wrap rightover
    end
    self:go_to_board(new_index)
end

function VaultView:go_to_previous_board()
    local new_index = self.active_board_index - 1
    if new_index < 1 then
        new_index = #self.boards -- wrap leftover
    elseif new_index > #self.boards then
        new_index = 1 -- wrap rightover
    end
    self:go_to_board(new_index)
end

function VaultView:render_board_selection()
    local buf = self.board_selection_win.buf
    local win = self.board_selection_win.win

    -- Build the line with indices in parentheses
    local parts = {}
    for i, title in ipairs(self.boards_title) do
        table.insert(parts, string.format("(%d)%s", i, title))
    end
    local boards_line = table.concat(parts, "   ")

    -- Compute how many spaces to pad before "(h)elp"
    local win_width = vim.api.nvim_win_get_width(win)
    local help_text = "<C-h> help"
    local total_len = #boards_line + #help_text

    local padding = ""
    if total_len < win_width then
        padding = string.rep(" ", win_width - (total_len + 1))
    else
        -- If it overflows, just add a single space
        padding = " "
    end

    local full_line = boards_line .. padding .. help_text

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { full_line })

    -- Apply highlights
    local col_start = 0
    for i, title in ipairs(self.boards_title) do
        local index_str = string.format("(%d)", i)
        local index_len = #index_str
        local title_start = col_start + index_len
        local title_end = title_start + #title

        -- Highlight "(i)" as Comment
        vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, col_start, col_start + index_len)

        -- Underline active board
        if i == self.active_board_index then
            vim.api.nvim_buf_add_highlight(buf, -1, "Underlined", 0, title_start, title_end)
        end

        col_start = title_end + 3 -- skip "   "
    end

    -- Highlight "<C-h> help" as Comment at the right edge
    local help_start = win_width - (#help_text + 1)
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, help_start, win_width)
end

function VaultView:render()
    self.board_selection_win:show()
    self:render_board_selection()
    self.pages_win:show()
    self.views_win:show()

    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:render()
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
    self.isDisplayed = true
end

function VaultView:hide()
    -- vim.notify("closing vaultview", vim.log.levels.INFO)
    self.board_selection_win:close()
    self.pages_win:close()
    self.views_win:close()

    for _, board in ipairs(self.boards) do
        board:close()
    end
    self.isDisplayed = false
end

function VaultView:go_to_page(direction)
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:go_to_page(direction)
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

function VaultView:focus(entry_idx)
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:focus(entry_idx)
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

function VaultView:focus_back()
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:focus_back()
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

function VaultView:pick_list()
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:pick_list()
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

function VaultView:pick_card()
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:pick_card()
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

function VaultView:pick_content()
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:pick_content()
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

local Keymaps = require("vaultview.keymaps")

return VaultView
