local M = {}

local padding = {
    top = 2,
    left = 1,
}

-- Because footer_win.height depends on footer_win itself, we define shared dimensions first
local columns = vim.o.columns
local lines = vim.o.lines

-- Base windows height values (shared across layouts)
local header_height = 6
local footer_height = 2

-- Main content height
local view_height = lines - header_height - footer_height - 1

---------------------------------------------------------
-- Main Windows
---------------------------------------------------------
M.header_win = {
    width = columns,
    height = header_height,
    zindex = 10,
    row = 0,
    col = 0,
}

M.view_win = {
    width = columns,
    height = view_height,
    zindex = 10,
    row = header_height + 1,
    col = 0,
}

M.footer_win = {
    width = columns,
    height = footer_height,
    zindex = 10,
    row = lines - 1,
    col = 0,
}



---------------------------------------------------------
-- List Windows
---------------------------------------------------------
M.list_win = {
    ViewLayoutColumns = {
        width = 70,
        height = view_height - 2 * padding.top,
        -- height = 40,
        zindex = 20,
        border = { "╭", "", "╮", "│", "╯", "─", "╰", "│" },
        row = header_height,
        col = 1,
    },
    ViewLayoutCarousel = {
        width = 35,
        height = view_height - 2 * padding.top,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = header_height,
        col = 1,
    },
}

M.list_win_close = {
    ViewLayoutCarousel = {
        width = 3,
        height = view_height - 2 * padding.top,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = header_height,
        col = 1,
    },
    ViewLayoutColumns = {
        width = 3,
        height = view_height - 2 * padding.top,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = header_height,
        col = 1,
    },
}

---------------------------------------------------------
-- Card Windows
---------------------------------------------------------
M.card_win = {
    ViewLayoutColumns = {
        width = M.list_win.ViewLayoutColumns.width - 3, -- 67,
        height = 6, -- TODO could be user configurable (number of content/line per entry displayed)
        zindex = 30,
        -- border = { "", "", "", "│", "╯", "─", "╰", "│" },
        border = { "", "─", "", "", "", "", "", "" },
        -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
        -- col = 1,
    },

    ViewLayoutCarousel = {
        width = M.list_win.ViewLayoutCarousel.width - 3, -- 32,
        height = 6,
        zindex = 30,
        border = { "", "─", "", "", "", "", "", "" },
        -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
        -- col = 1,
    },
}
M.card_win_close = {
    width = 32,
    height = 1,
    zindex = 30,
    border = { "", "", "", "│", "╯", "─", "╰", "│" },
    -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
    -- col = 1,
}

return M
