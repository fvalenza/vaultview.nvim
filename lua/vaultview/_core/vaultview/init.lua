
local VaultView = {}
VaultView.__index = VaultView

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")


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

-- function VaultView.new(config)
function VaultView.new()
	local self = setmetatable({}, VaultView)
    vim.notify( "creating vaultview", vim.log.levels.INFO)

    self:create_vaultview_windows()

    -- create the boards and give them the pages and views windows so they can draw in it  (at least text in page window, but not sure if necesarry to give view window)


    return self
end

function VaultView:render()
    self.board_selection_win:show()
    self.pages_win:show()
    self.views_win:show()
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
end


function VaultView:set_keymap()
	return {
		q = {
			function()
				self:close()
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["p"] = {
			function()
				self:go_to_board(-1)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["n"] = {
			function()
				self:go_to_board(1)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["<S-h>"] = {
			function()
				-- M:go_to_page(-1)
				self:go_to_page(-1)
			end, -- previous page
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["<S-l>"] = {
			function()
				-- M:go_to_page(1)
				self:go_to_page(1)
			end, -- next page
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["1"] = {
			function()
				self:set_active_tab(1)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["2"] = {
			function()
				self:set_active_tab(2)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["3"] = {
			function()
				self:set_active_tab(3)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
	}
end


return VaultView
