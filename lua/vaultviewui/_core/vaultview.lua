local VaultView = {}
VaultView.__index = VaultView

local Constants = require("vaultviewui._ui.constants")
local wf = require("vaultviewui._core.windowfactory")

function VaultView.new(config)
    -- function VaultView.new()
    local self = setmetatable({}, VaultView)


    self.header_win = wf.create_window({
        width = Constants.header_win.width,
        height = Constants.header_win.height,
        zindex = Constants.header_win.zindex,
        border = "none",
        relative = "editor",
        row = 0,
        col = 0,
        text = "header_win",
        show = true,
        focusable = true,
    })

    self.view_win = wf.create_window({
        width = Constants.view_win.width,
        height = Constants.view_win.height,
        zindex = Constants.view_win.zindex,
        border = "none",
        relative = "editor",
        row = Constants.view_win.row, -- TODO due to tabline the +1...
        col = 0,
        text = "view_win",
        show = true,
        focusable = true,
    })

    return self
end

function VaultView:show()
    self:render()
    self.isDisplayed = true
end

local build_tabs = function(board_names, width_available, index_active_board)

    local activeBoardName= board_names[index_active_board]

    local total_str_w = -1
    for _, v in ipairs(board_names) do
        if v ~= "_pad_" then
            total_str_w = total_str_w + vim.api.nvim_strwidth(v) + 5
        end
    end

    local lines = { {}, {}, {} }
    local highlights = {}

    local datalen = #board_names
    local colpos = { 0, 0, 0 } -- track byte columns per line

    for i, v in ipairs(board_names) do
        if v == "_pad_" then
            local emptychar = string.rep(" ", width_available - total_str_w)
            for l = 1, 3 do
                table.insert(lines[l], { emptychar })
                colpos[l] = colpos[l] + #emptychar
            end
        else
            local hchar = string.rep("─", vim.api.nvim_strwidth(v) + 2)
            local row_text = {
                "┌" .. hchar .. "┐",
                "│ " .. v .. " │",
                "└" .. hchar .. "┘",
            }
            local hl = (activeBoardName == v and "TabActive") or "TabInactive"

            for l = 1, 3 do
                table.insert(lines[l], { row_text[l] })
                local byte_len = #row_text[l]

                table.insert(highlights, {
                    group = hl,
                    line = l - 1, -- 0-based for nvim_buf_add_highlight
                    start_col = colpos[l],
                    end_col = colpos[l] + byte_len,
                })

                colpos[l] = colpos[l] + byte_len
            end

            if i ~= datalen then
                for l = 1, 3 do
                    table.insert(lines[l], { " " })
                    colpos[l] = colpos[l] + 1
                end
            end
        end
    end

    return lines, highlights
end

--- Render the header buffer
local function render_header(win, board_names, active_board_index)
    local buf = win.buf
    vim.bo[buf].modifiable = true

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local dims = win:size()
    local win_width = dims.width

    local lines, highlights = build_tabs(board_names, win_width, active_board_index)

    local flat_lines = {}

    for _, row in ipairs(lines) do
        local str_parts = {}
        for _, cell in ipairs(row) do
            table.insert(str_parts, cell[1]) -- extract the actual text
        end
        table.insert(flat_lines, table.concat(str_parts))
    end

    table.insert(flat_lines, string.rep("─", vim.o.columns))

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, flat_lines)

    -- Apply highlights
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            h.group,
            h.line, -- now line-specific
            h.start_col,
            h.end_col
        )
    end

    vim.api.nvim_buf_add_highlight(buf, -1, "TabSeparator", 3, 0, -1)

    vim.bo[buf].modifiable = false
    return #flat_lines -- number of header lines (so we know where to start the next section)
end

local function render_page(win, pages, active_page, start_line)
    local buf = win.buf
    vim.bo[buf].modifiable = true

    local dims = win:size()
    local win_width = dims.width

    -- Build the text with separators
    local page_texts = {}
    local highlights = {}
    local col = 0

    for i, name in ipairs(pages) do
        local label = name
        if i < #pages then
            label = label .. " | "
        end

        table.insert(page_texts, label)

        local len = #label
        local hl_group = (i == active_page) and "PageActive" or "PageInactive"
        table.insert(highlights, {
            group = hl_group,
            start_col = col,
            end_col = col + #name, -- highlight just the page name
        })

        col = col + len
    end

    local pages_line = table.concat(page_texts)
    local prefix = "<S-h>  <--  "
    local suffix = "  -->  <S-l>"
    local full_text = prefix .. pages_line .. suffix

    -- Center the text
    local padding = math.floor((win_width - #full_text) / 2)
    if padding < 0 then
        padding = 0
    end
    local padded_line = string.rep(" ", padding) .. full_text

    local lines = {
        padded_line,
        string.rep("─", win_width),
    }

    vim.api.nvim_buf_set_lines(buf, start_line, -1, false, lines)

    -- Apply highlights (offset by padding + prefix)
    local prefix_len = padding + #prefix
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            h.group,
            start_line,
            prefix_len + h.start_col,
            prefix_len + h.end_col
        )
    end

    vim.api.nvim_buf_add_highlight(buf, -1, "TabSeparator", 5, 0, -1)
    vim.bo[buf].modifiable = false
end

function VaultView:header_win_render()
    local highlights = require("vaultviewui._ui.highlights")
    highlights.apply(userhl)

    local board_names = { "Overview", "Details", "Logs", "_pad_", "Settings" }
    local pages = { "Page 1", "Page 2", "Page 3" }

    local current_board_index = 1
    local current_page = 1

    -- Draw header and remember where the page section begins
    local header_line_count = render_header(self.header_win, board_names, current_board_index)

    -- Draw initial page section
    render_page(self.header_win, pages, current_page, header_line_count)
end

function VaultView:render()
    self:header_win_render()

    self.header_win:show()
    self.view_win:show()
end

function VaultView:hide()

    if self.header_win then
        self.header_win:hide()
    end
    if self.view_win then
        self.view_win:hide()
    end

    self.isDisplayed = false
end

function VaultView:destroy()

    -- Close the windows first
    if self.header_win then
        self.header_win:close()
        self.header_win = nil
    end
    if self.view_win then
        self.view_win:close()
        self.view_win = nil
    end

    self.isDisplayed = false
end

return VaultView
