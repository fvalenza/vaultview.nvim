--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local configuration = require("vaultviewui._core.configuration")

local M = {}

configuration.initialize_data_if_needed()

local build_tabs = function(tabs, width_available, activeTab)
    dprint("Available width: " .. width_available)
    local win_width = vim.api.nvim_win_get_width(0)
    dprint("Window width: " .. win_width)

    local total_str_w = -1
    for _, v in ipairs(tabs) do
        if v ~= "_pad_" then
            total_str_w = total_str_w + vim.api.nvim_strwidth(v) + 5
        end
    end
    dprint("Total string width: " .. total_str_w)

    local lines = { {}, {}, {} }
    local highlights = {}

    local datalen = #tabs
    local colpos = { 0, 0, 0 } -- track byte columns per line

    for i, v in ipairs(tabs) do
        if v == "_pad_" then
            local emptychar = string.rep(" ", width_available - total_str_w)
            for l = 1, 3 do
                table.insert(lines[l], { emptychar })
                colpos[l] = colpos[l] + #emptychar
            end
            dprint("Inserted padding of length " .. #emptychar)
        else
            local hchar = string.rep("─", vim.api.nvim_strwidth(v) + 2)
            local row_text = {
                "┌" .. hchar .. "┐",
                "│ " .. v .. " │",
                "└" .. hchar .. "┘",
            }
            local hl = (activeTab == v and "TabActive") or "TabInactive"

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
local function render_header(header_buf, tabs, current_tab)
    vim.bo[header_buf].modifiable = true
    vim.api.nvim_buf_set_lines(header_buf, 0, -1, false, {})

    local lines, highlights = build_tabs(tabs, vim.o.columns, tabs[current_tab])

    local flat_lines = {}

    for _, row in ipairs(lines) do
        local str_parts = {}
        for _, cell in ipairs(row) do
            table.insert(str_parts, cell[1]) -- extract the actual text
        end
        table.insert(flat_lines, table.concat(str_parts))
    end

    table.insert(flat_lines, string.rep("─", vim.o.columns))

    vim.api.nvim_buf_set_lines(header_buf, 0, -1, false, flat_lines)

    -- Apply highlights
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(
            header_buf,
            -1,
            h.group,
            h.line, -- now line-specific
            h.start_col,
            h.end_col
        )
    end

    vim.api.nvim_buf_add_highlight(header_buf, -1, "TabSeparator", 3, 0, -1)
    vim.bo[header_buf].modifiable = false
    return #flat_lines -- number of header lines (so we know where to start the next section)
end

local function render_page(header_buf, pages, active_page, start_line)
    vim.bo[header_buf].modifiable = true

    local win_width = vim.api.nvim_win_get_width(0)

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

    vim.api.nvim_buf_set_lines(header_buf, start_line, -1, false, lines)

    -- Apply highlights (offset by padding + prefix)
    local prefix_len = padding + #prefix
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(
            header_buf,
            -1,
            h.group,
            start_line,
            prefix_len + h.start_col,
            prefix_len + h.end_col
        )
    end

    vim.api.nvim_buf_add_highlight(header_buf, -1, "TabSeparator", 5, 0, -1)
    vim.bo[header_buf].modifiable = false
end
local highlights = require("vaultviewui._ui.highlights")

local userhl = {
    TabActive = "String",
}

local function open_ui_with_tabs()
    vim.cmd("tabnew")

    highlights.apply(userhl)

    -- Header buffer
    local header_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, header_buf)

    -- Window-local options for a clean header
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.foldcolumn = "0"
    vim.wo.cursorline = false
    vim.wo.wrap = false

    -- Create highlight groups
    -- vim.api.nvim_set_hl(0, "TabActive", { fg = "#ffffff", bg = "NONE", bold = true })
    -- vim.api.nvim_set_hl(0, "TabInactive", { fg = "#aaaaaa", bg = "NONE" })
    -- vim.api.nvim_set_hl(0, "TabSeparator", { fg = "#5f5f5f" })
    --
    -- vim.api.nvim_set_hl(0, "PageActive", { fg = "#ffffff", bold = true })
    -- vim.api.nvim_set_hl(0, "PageInactive", { fg = "#808080" })

    -- Our “tabs”
    local tabs = { "Overview", "Details", "Logs", "_pad_", "Settings" }
    local pages = {
        "Page 1",
        "Page 2",
        "Page 3",
        "Page 4",
        "Page 5",
        "Page 6",
        "Page 7",
        "Page 8",
        "Page 9",
        "Page 10",
        "Page 11",
        "Page 12",
        "Page 13",
        "Page 14",
        "Page 15",
        "Page 16",
        "Page 17",
        "Page 18",
        "Page 19",
        "Page 20",
        "Page 21",
        "Page 22",
        "Page 23",
        "Page 24",
        "Page 25",
        "Page 26",
        "Page 27",
        "Page 28",
        "Page 29",
        "Page 30",
    }

    local current_tab = 1
    local current_page = 1

    -- Draw header and remember where the page section begins
    local header_line_count = render_header(header_buf, tabs, current_tab)

    -- Draw initial page section
    render_page(header_buf, pages, current_page, header_line_count)

    -- Navigation keys to switch pages
    vim.keymap.set("n", "<S-h>", function()
        dprint("Previous page")
        current_page = (current_page - 2) % #pages + 1
        render_page(header_buf, pages, current_page, header_line_count)
    end, { buffer = header_buf, nowait = true })

    vim.keymap.set("n", "<S-l>", function()
        dprint("Next page")
        current_page = (current_page % #pages) + 1
        render_page(header_buf, pages, current_page, header_line_count)
    end, { buffer = header_buf, nowait = true })

    -- Map `q` to close the tab
    vim.keymap.set("n", "q", function()
        vim.cmd("tabclose")
    end, { buffer = header_buf, nowait = true })
end

function M.run_toggle_vaultview()
    dprint("TOTOMONGARS")

    open_ui_with_tabs()
end

return M
