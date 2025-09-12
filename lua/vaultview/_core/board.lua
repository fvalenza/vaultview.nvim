local Board = {}
Board.__index = Board

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")

-- function Board.new(config)
function Board.new(board_title, board_data, page_selection_win)
    local self = setmetatable({}, Board)
    vim.notify("creating board", vim.log.levels.INFO)

    self.board_title = board_title
    self.board_data = board_data or {}
    self.page_selection_win = page_selection_win

    return self
end

function Board:render()
    self:render_page_selection()
    self:render_view()
end

-- TODO  Display in the center of the page selection window ?? Not sure it is worth it
function Board:render_page_selection()

    local active_page_index = 2 -- e.g. "page2" is active
    local buf = self.page_selection_win.buf

    -- Collect page titles
    local pages = {}
    for _, page in ipairs(self.board_data) do
        table.insert(pages, page.title)
    end
    local pages_line = table.concat(pages, " | ")

    -- Final line with decorations
    local line = "<C-h>  <--  " .. pages_line .. "   --> <C-l>"

    -- Put the line into the buffer (replace first line, or you can append)
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { line })

    -- First, apply "Comment" highlight to everything except pages
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, 0, 11) -- "<C-h>  <--  "
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, #line - 9, -1) -- "   --> <C-l>"

    -- Now underline the active page
    local col_start = 12 -- starting col of first page (after "<C-h>  <--  ")
    for i, title in ipairs(pages) do
        local col_end = col_start + #title
        if i == active_page_index then
            vim.api.nvim_buf_add_highlight(buf, -1, "Underlined", 0, col_start, col_end)
        end
        col_start = col_end + 3 -- skip " | "
    end
end

function Board:render_view() end

return Board
