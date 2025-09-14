local VaultView = {}
VaultView.__index = VaultView

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local Board = require("vaultview._core.board")
local DailyParser = require("vaultview._parser.daily_parser")
local tutils = require("vaultview.utils.table_utils")

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
        keys = self:set_keymap(),
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

local config = {
    -- markdown_dir = "~/mboard/daily",
    markdown_dir = "~/mboard",
    vault = {
        -- path = "/home/fvalenza/root-filetree/devel/myVault",
        path = "/home/fvalenza/mboard/daily/",
        name = "myVault",
    },
    boards = {
        dailyBoard = {
            -- daily_notes_folder = "vault/0-dailynotes", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
            daily_notes_folder = ".", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
            daily_note_pattern = "%d%d%d%d%-%d%d%-%d%d.md", -- pattern to identify daily notes, currently not used because hardcoded in daily_parser.lua
            -- show_empty_months = false,
        },
        dailyBoard2 = {
            -- daily_notes_folder = "vault/0-dailynotes", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
            daily_notes_folder = ".", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
            daily_note_pattern = "%d%d%d%d%-%d%d%-%d%d.md", -- pattern to identify daily notes, currently not used because hardcoded in daily_parser.lua
            -- show_empty_months = false,
        },
        -- mocBoard = {
        --     note_folder_mode = true,
        --     pattern = "vault/1-MOCs/*.md", -- could be "subdir/*" or "yyyy-mm-dd.md" or "moc-*.md"
        --     file_title = "strip-moc", -- could be "date" or "basename" or "strip-moc"
        -- }
    },
}

-- function VaultView.new(config)
function VaultView.new()
    local self = setmetatable({}, VaultView)
    -- vim.notify("creating vaultview", vim.log.levels.INFO)

    self:create_vaultview_windows()

    -- TODO Create all boards
    self.boards_title = {}
    self.boards = {}

    -- iterate through boards in config and create them
    for board_name, board_config in pairs(config.boards) do
        table.insert(self.boards_title, board_name)

        local BoardData = DailyParser.parseBoard(config.vault, board_config)
        local context = {
            vaultview = self,
        }
        local board = Board.new("DailyBoard", BoardData, self.pages_win, context)
        table.insert(self.boards, board)
    end

    self.active_board_index = 1 -- TODO only if at leat oneboard created

    -- local dailyBoardData = DailyParser.parseBoard(config.vault, config.dailyBoard)
    -- tutils.printTable(dailyBoardData, "dailyBoardData")

    -- create the boards and give them the pages and views windows so they can draw in it  (at least text in page window, but not sure if necesarry to give view window)
    -- local context = {
    --     vaultview = self,
    -- }
    -- local board = Board.new("DailyBoard", dailyBoardData, self.pages_win, context)
    --
    -- self.board = board

    return self
end

-- TODO, these 3 functions and in new, have table of boards + index of active board. See how pages are done in board.lua
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

    local boards_line = table.concat(self.boards_title, "   ")

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { boards_line })

    -- Underilne the active board
    local col_start = 0
    for i, title in ipairs(self.boards_title) do
        local col_end = col_start + #title
        if i == self.active_board_index then
            vim.api.nvim_buf_add_highlight(buf, -1, "Underlined", 0, col_start, col_end)
        end
        col_start = col_end + 3 -- skip "   "
    end
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
end

-- Si open() c'est juste des appels a render(), autant ne pas l'avoir et directement appeler render()
function VaultView:open()
    -- vim.notify("opening vaultview", vim.log.levels.INFO)
    self:render()
    -- self:set_keymaps()
end

function VaultView:close()
    -- vim.notify("closing vaultview", vim.log.levels.INFO)
    self.board_selection_win:close()
    self.pages_win:close()
    self.views_win:close()

    for _,board in ipairs(self.boards) do
        board:close()
    end
end

function VaultView:go_to_page(direction)
    local active_board = self.boards[self.active_board_index]
    if active_board then
        active_board:go_to_page(direction)
    else
        -- vim.notify("No active board for index " .. tostring(self.active_board_index), vim.log.levels.WARN)
    end
end

function VaultView:set_keymap()
    return {
        q = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_close_board()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["p"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_previous_board()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["n"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_next_board()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["<S-h>"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_previous_page()
            end, -- previous page
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["<S-l>"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_next_page()
            end, -- next page
            mode = "n",
            noremap = true,
            nowait = true,
        },
        -- TODO "automatize it" from 1 to 9 ? or just straight copy it 9 times ? perhaps no need to do it the hard way for only 9 mappings...
        ["1"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_board(1)
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["2"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_board(2)
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["3"] = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_board(3)
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
    }
end

return VaultView
