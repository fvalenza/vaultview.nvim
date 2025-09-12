

local Board = {}
Board.__index = Board

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")

-- function Board.new(config)
function Board.new(board_title, board_data, page_selection_win )
	local self = setmetatable({}, Board)
    vim.notify( "creating board", vim.log.levels.INFO)

    self.board_title = board_title
    self.board_data = board_data or {}
    self.page_selection_win = page_selection_win



    return self
end


function Board:render()
    self:render_page_selection()
    self:render_view()

end

-- TODO active page shall be highlighted
function Board:render_page_selection()
	-- local line = "Board: " .. board_title .. " | Page: " .. page_title
	--
	-- vim.api.nvim_buf_set_lines(self.pages_win.buf, 0, 1, false, { line })
    local pages_titles = {}
    for _, page in ipairs(self.board_data) do
      table.insert(pages_titles, page.title)
    end

    local line = table.concat(pages_titles, " ")
    print(line)
    vim.api.nvim_buf_set_lines(self.page_selection_win.buf, 0, 1, false, { line })
end

function Board:render_view()
end


return Board
