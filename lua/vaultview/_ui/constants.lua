local M = {}

local padding = {
    top = 2,
    left = 1,
}

M.header_win = {
    width = vim.o.columns,
    height = 6,
    zindex = 10,
    -- backdrop = false,
    row = 0,
    col = 0,
}

M.footer_win = {
    width = vim.o.columns,
    height = 2,
    zindex = 10,
    -- backdrop = false,
    row = vim.o.lines - 1,
    col = 0,
}

M.view_win = {
    width = vim.o.columns,
    height = vim.o.lines - M.header_win.height - M.footer_win.height - 1,
    zindex = 10,
    -- backdrop = false,
    row = M.header_win.height + 1,
    col = 0,
}


M.list_win = {
    ViewLayoutColumns = {
        width = 70,
        height = M.view_win.height - 2 * padding.top,
        -- height = 40,
        zindex = 20,
        border = { "╭", "", "╮", "│", "╯", "─", "╰", "│" },
        row = M.header_win.height,
        col = 1,
    },
    ViewLayoutCarousel = {
        width = 35,
        height = M.view_win.height - 2 * padding.top,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = M.header_win.height,
        col = 1,
    },
}

M.list_win_close = {
    ViewLayoutCarousel = {
        width = 3,
        height = M.view_win.height - 2 * padding.top,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = M.header_win.height,
        col = 1,
    },
    ViewLayoutColumns = {
        width = 3,
        height = M.view_win.height - 2 * padding.top,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = M.header_win.height,
        col = 1,
    },
}

M.card_win = {
    ViewLayoutColumns = {
        width = 67,
        height = 6, -- TODO could be user configurable (number of content/line per entry displayed)
        zindex = 30,
        -- border = { "", "", "", "│", "╯", "─", "╰", "│" },
        border = { "", "─", "", "", "", "", "", "" },
        -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
        -- col = 1,
    },

    ViewLayoutCarousel = {
        width = 32,
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


M.card_closing_list = {
    width = 32,
    height = 0,
    zindex = 30,
    border = { "", "▁", "", "", "", "", "", "" },
    -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
    -- col = 1,
}
return M
