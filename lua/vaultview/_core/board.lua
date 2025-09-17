local Board = {}
Board.__index = Board

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local ViewLayoutCarousel = require("vaultview._core.viewlayout")

-- function Board.new(config)
function Board.new(board_title, board_data, page_selection_win, context)
    local self = setmetatable({}, Board)

    self.context = context
    self.page_selection_win = page_selection_win -- The Snacks window where we will display the pages titles

    -- Create ViewLayoutCarousel instance for each page TODO
    self.board_title = board_title
    self.board_data = board_data or {}

    self.pages_title = {}
    self.pages_content = {}
    self.pages_viewlayout = {}
    for _, page in ipairs(self.board_data) do
        table.insert(self.pages_title, page.title)
        table.insert(self.pages_content, page.lists)
        local page_viewlayout = ViewLayoutCarousel.new(page.lists, self.context)

        local vl = page_viewlayout
        -- Determine what to render based on the available space and the number of lists
        vl.last_left_collapsed, vl.last_right_collapsed, vl.layout_space_taken = vl:compute_layout()
        vl.visibility_window_left = math.max(1, vl.last_left_collapsed + 1) -- Ensure we don't go below 1
        vl.visibility_window_right = math.min(#vl.lists, vl.last_right_collapsed - 1) -- Ensure we don't go above the number of lists
        vl.list_focus_index = math.ceil((vl.last_left_collapsed + vl.last_right_collapsed) / 2) -- Set the focus index to the middle of the collapsed lists
        vl.card_focus_index = 1
        -- if list focused has no items, move focus to the next list with items
    local current_list = vl.lists[vl.list_focus_index]
        if #current_list.cards == 0 then
            vl.list_focus_index = vl.list_focus_index + 1
        end
        current_list.cards[vl.card_focus_index].win:focus()

        table.insert(self.pages_viewlayout, page_viewlayout)
    end


    self.active_page_index = 1


    return self
end

function Board:go_to_page(direction)
	local new_index = self.active_page_index + direction
	if new_index < 1 then
		new_index = #self.pages_title -- wrap left
	elseif new_index > #self.pages_title then
		new_index = 1 -- wrap right
	end

	-- hide current page layout
	-- if self.view_layout then
	-- 	self.view_layout:close()
	-- end
    self:hide()

	-- update active page
	self.active_page_index = new_index

    self:render()

end


function Board:render()
    self:render_page_selection()
    self:render_view()
end


function Board:close()
    for _, vl in ipairs(self.pages_viewlayout) do
        vl:close()
    end
end

function Board:hide()
    local active_page_viewlayout = self.pages_viewlayout[self.active_page_index]
    if active_page_viewlayout then
        active_page_viewlayout:hide()
    else
        -- vim.notify("No viewlayout for active page index " .. tostring(self.active_page_index), vim.log.levels.WARN)
    end
end

-- TODO  Display in the center of the page selection window ?? Not sure it is worth it
function Board:render_page_selection()

    local buf = self.page_selection_win.buf

    local pages_line = table.concat(self.pages_title, " | ")

    -- Final line with decorations
    local line = "<S-h>  <--  " .. pages_line .. "   --> <S-l>"

    -- Put the line into the buffer (replace first line, or you can append)
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { line })

    -- First, apply "Comment" highlight to everything except pages
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, 0, 11) -- "<S-h>  <--  "
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, #line - 9, -1) -- "   --> <S-l>"

    -- Now underline the active page
    local col_start = 12 -- starting col of first page (after "<S-h>  <--  ")
    for i, title in ipairs(self.pages_title) do
        local col_end = col_start + #title
        if i == self.active_page_index then
            vim.api.nvim_buf_add_highlight(buf, -1, "Underlined", 0, col_start, col_end)
        end
        col_start = col_end + 3 -- skip " | "
    end
end

function Board:render_view()
    local active_page_viewlayout = self.pages_viewlayout[self.active_page_index]
    if active_page_viewlayout then
        active_page_viewlayout:render()
    else
        -- vim.notify("No viewlayout for active page index " .. tostring(self.active_page_index), vim.log.levels.WARN)
    end

end

return Board
