local M = {}

-- function M.create_window(opts)
--     opts = opts or {}
--     local buf = opts.buf or vim.api.nvim_create_buf(false, true) -- unlisted, scratch
--     local width = opts.width or math.floor(vim.o.columns * 0.8)
--     local height = opts.height or math.floor(vim.o.lines * 0.8)
--     local row = opts.row or math.floor((vim.o.lines - height) / 2)
--     local col = opts.col or math.floor((vim.o.columns - width) / 2)
--
--     local win_opts = {
--         relative = "editor",
--         width = width,
--         height = height,
--         row = row,
--         col = col,
--         style = "minimal",
--         border = opts.border or "rounded",
--     }
--
--     local win = vim.api.nvim_open_win(buf, true, win_opts)
--
--     -- Optional window options
--     if opts.win_opts then
--         for k, v in pairs(opts.win_opts) do
--             vim.api.nvim_win_set_option(win, k, v)
--         end
--     end
--
--     return {
--         win = win,
--         buf = buf,
--     }
-- end
local Snacks = require("snacks")

function M.create_window(opts)
    local opts = opts
    opts.show = true
    local win = Snacks.win(opts)
    win:hide()
    return win
end

function M.close_window(window)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_close(window.win, true)
    end
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.api.nvim_buf_delete(window.buf, { force = true })
    end
end

function M.setNewContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, lines)
    end
end

function M.appendContent(window, lines)
    if window and vim.api.nvim_buf_is_valid(window.buf) then
        local line_count = vim.api.nvim_buf_line_count(window.buf)
        vim.api.nvim_buf_set_lines(window.buf, line_count, -1, false, lines)
    end
end

return M
