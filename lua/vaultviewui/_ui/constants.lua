local M = {}

local padding = {
    top = 2,
    left = 1,
}

M.floating_window = {
    width = vim.o.columns,
    height = vim.o.lines,
    -- width = 0,
    -- height =0,
    zindex = 5,
    backdrop = false,
}

M.header_win = {
    width = vim.o.columns,
    height = 6,
    zindex = 10,
    -- backdrop = false,
    row = 0,
    col = 0,
}

M.view_win = {
    width = vim.o.columns,
    height = vim.o.lines - M.header_win.height,
    zindex = 10,
    -- backdrop = false,
    row = M.header_win.height + 1,
    col = 0,
}


M.boards_win = {
    -- width = vim.o.columns,
    width = 0,
    height = 1,
    zindex = 10,
    -- backdrop = false,
    row = 0,
    col = 0,
}

M.pages_win = {
    -- width = vim.o.columns,
    width = 0,
    height = 1,
    zindex = 10,
    -- backdrop = false,
    row = M.boards_win.height + padding.top,
    col = 0,
}

M.views_win = {
    -- width = vim.o.columns,
    width = 0,
    height = M.floating_window.height - M.boards_win.height - M.pages_win.height - 3 * 2,
    zindex = 10,
    -- backdrop = false,
    row = M.boards_win.height + M.pages_win.height + 2 * padding.top,
    col = 0,
}

M.list_win = {
    width = 35,
    height = 40,
    zindex = 20,
    border = { "", "", "", "│", "╯", "─", "╰", "│" },
    row = M.boards_win.height + M.pages_win.height + 3 * padding.top, -- Could be 2 * padding if no border
    col = 1,
    ViewLayoutColumns = {
        width = 70,
        height = 40,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = M.boards_win.height + M.pages_win.height + 3 * padding.top, -- Could be 2 * padding if no border
        col = 1,
    },
    ViewLayoutCarousel = {
        width = 35,
        height = 40,
        zindex = 20,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        row = M.boards_win.height + M.pages_win.height + 3 * padding.top, -- Could be 2 * padding if no border
        col = 1,
    },
}

M.list_win_close = {
    width = 3,
    height = 40,
    zindex = 20,
    border = { "", "", "", "│", "╯", "─", "╰", "│" },
    row = M.boards_win.height + M.pages_win.height + 3 * padding.top, -- Could be 2 * padding if no border
    col = 1,
}

M.card_win = {
    width = 32,
    height = 6,
    zindex = 30,
    border = { "", "", "", "│", "╯", "─", "╰", "│" },
    -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
    -- col = 1,
    ViewLayoutColumns = {
        width = 67,
        height = 6,
        zindex = 30,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
        -- row = M.boards_win.height + M.pages_win.height +  3 * padding.top, -- Could be 2 * padding if no border
        -- col = 1,
    },

    ViewLayoutCarousel = {
        width = 32,
        height = 6,
        zindex = 30,
        border = { "", "", "", "│", "╯", "─", "╰", "│" },
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

-- board = {
--   -- Width of the board window (0 = full width)
--   width = 0,
--   -- Height of the board window
--   height = vim.o.lines - 2,
--   -- Z-index layering of the board
--   zindex = 5,
--   -- Board border characters (empty or filled)
--   border = { '', ' ', '', '', '', '', '', '' }, -- Only add empty space on top border
--   -- Additional window-local options for the board
--   win_options = {},
--   -- Padding around board content (top, left)
--   padding = { top = 1, left = 8 },
-- },

-- card = {
--   -- Card window width (0 = auto)
--   width = 32,
--   -- Card window height in lines
--   height = 6,
--   -- Z-index layering of the card window
--   zindex = 7,
--   -- Card border characters (table of 8 sides)
--   border = { '', '', '', '', '', '▁', '', '' }, -- Only add border at bottom
--   -- Additional window-local options for the card
--   win_options = {
--     wrap = true,
--     -- spell = true, -- Uncomment this to enable spell checking
--   },
-- },
-- list = {
--   -- Width of the list window (columns)
--   width = 32,
--   -- Height of the list window (0–1 = % of screen height)
--   height = 0.9,
--   -- Z-index layering of the list window
--   zindex = 6,
--   -- List window border characters
--   -- border = { '', '', '', '│', '┘', '─', '└', '│' }, -- bottom single
--   border = { '', '', '', '│', '╯', '─', '╰', '│' }, -- bottom rounded
--   -- border = "rounded",
--   -- Additional window-local options for the list
--   win_options = {},
-- },
return M
