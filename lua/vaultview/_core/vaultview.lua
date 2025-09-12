
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
		text = "t",
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
	dailyBoard = {
		-- daily_notes_folder = "vault/0-dailynotes", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
		daily_notes_folder = ".", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
        daily_note_pattern = "%d%d%d%d%-%d%d%-%d%d.md", -- pattern to identify daily notes, currently not used because hardcoded in daily_parser.lua
		-- show_empty_months = false,
	},
	mocBoard = {
		note_folder_mode = true,
		pattern = "vault/1-MOCs/*.md", -- could be "subdir/*" or "yyyy-mm-dd.md" or "moc-*.md"
		file_title = "strip-moc", -- could be "date" or "basename" or "strip-moc"
	},
}


-- function VaultView.new(config)
function VaultView.new()
	local self = setmetatable({}, VaultView)
    vim.notify( "creating vaultview", vim.log.levels.INFO)

    self:create_vaultview_windows()

    local dailyBoardData = DailyParser.parseBoard(config.vault, config.dailyBoard)
    tutils.printTable(dailyBoardData, "dailyBoardData")

	-- print("Items in dailyBoardData: " .. vim.inspect(dailyBoardData))
    -- create the boards and give them the pages and views windows so they can draw in it  (at least text in page window, but not sure if necesarry to give view window)
    local context = {
        vaultview = self,
    }
    local board = Board.new("DailyBoard", dailyBoardData, self.pages_win, context)

    self.board = board


    return self
end

-- TODO, these 3 functions and in new, have table of boards + index of active board. See how pages are done in board.lua
function VaultView:go_to_board(index)
end

function VaultView:go_to_next_board()

end

function VaultView:go_to_previous_board()

end

function VaultView:render()
    self.board_selection_win:show()
    self.pages_win:show()
    self.views_win:show()
    self.board:render()
end

-- Si open() c'est juste des appels a render(), autant ne pas l'avoir et directement appeler render()
function VaultView:open()
    vim.notify( "opening vaultview", vim.log.levels.INFO)
    self:render()
    -- self:set_keymaps()
end


function VaultView:close()
    vim.notify( "closing vaultview", vim.log.levels.INFO)
    self.board_selection_win:close()
    self.pages_win:close()
    self.views_win:close()
    self.board:close()
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
