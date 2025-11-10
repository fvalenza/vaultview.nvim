--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local configuration = require("vaultviewui._core.configuration")

local M = {}

configuration.initialize_data_if_needed()

local build_tabs = function(tabs, width_available, activeTab)
    local total_str_w = -1
    for _, v in ipairs(tabs) do
        if v ~= "_pad_" then
            total_str_w = total_str_w + vim.api.nvim_strwidth(v) + 5
        end
    end

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

local function open_ui_with_tabs()
    vim.cmd("tabnew")

    -- Header buffer
    local header_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, header_buf)
    vim.bo[header_buf].buftype = "nofile"
    vim.bo[header_buf].bufhidden = "wipe"
    vim.bo[header_buf].modifiable = false
    vim.wo.winfixheight = true
    -- vim.cmd("resize 2") -- one line for tabs, one for separator

    -- Create highlight groups
    vim.api.nvim_set_hl(0, "TabActive", { fg = "#ffffff", bg = "#005f87", bold = true })
    vim.api.nvim_set_hl(0, "TabInactive", { fg = "#aaaaaa", bg = "#303030" })
    vim.api.nvim_set_hl(0, "TabSeparator", { fg = "#5f5f5f" })

    -- Our “tabs”
    local tabs = { "Overview", "Details", "Logs" }
    local current_tab = 1

    --- Render the header buffer
    local function render_header()
        vim.bo[header_buf].modifiable = true
        vim.api.nvim_buf_set_lines(header_buf, 0, -1, false, {})

        local lines, highlights = build_tabs(tabs, vim.o.columns, tabs[current_tab])
        dprint("HIGHLIGHTS:")
        dprint(highlights)
        dprint("LINES RAW:")
        dprint(lines)

        local flat_lines = {}

        for _, row in ipairs(lines) do
            local str_parts = {}
            for _, cell in ipairs(row) do
                table.insert(str_parts, cell[1]) -- extract the actual text
            end
            table.insert(flat_lines, table.concat(str_parts))
        end

        table.insert(flat_lines, string.rep("─", vim.o.columns))
        dprint("LINES:")
        dprint(flat_lines)

        vim.api.nvim_buf_set_lines(header_buf, 0, -1, false, flat_lines)

        -- Apply highlights
	for _, h in ipairs(highlights) do
	    vim.api.nvim_buf_add_highlight(
	        header_buf,
	        -1,
	        h.group,
	        h.line,        -- now line-specific
	        h.start_col,
	        h.end_col
	    )
	end


        vim.api.nvim_buf_add_highlight(header_buf, -1, "TabSeparator", 3, 0, -1)
        vim.bo[header_buf].modifiable = false
    end

    render_header()

    -- Map `q` to close the tab
    vim.keymap.set("n", "q", function()
        vim.cmd("tabclose")
    end, { buffer = header_buf, nowait = true })
end

local function open_complex_ui()
    -- Create a new tab (fullscreen)
    vim.cmd("tabnew")

    local win = require("snacks").win({
        file = expanded_path,
        width = 0,
        height = 1,
        zindex = 50,
        border = "none",
        relative = "editor",
        bo = { modifiable = false },
        keys = { q = "close" },
        wo = {
            wrap = true,
            linebreak = true,
        },
    })

    --   -- ────────────────────────────────────────────────
    --   -- 1. HEADER BUFFER (single line at top)
    --   -- ────────────────────────────────────────────────
    --   local header_buf = vim.api.nvim_create_buf(false, true)
    --   vim.api.nvim_win_set_buf(0, header_buf)
    --   vim.bo[header_buf].buftype = "nofile"
    --   vim.bo[header_buf].bufhidden = "wipe"
    --   vim.bo[header_buf].modifiable = true
    --   vim.wo.winfixheight = true
    --   vim.cmd("resize 1") -- only one line tall
    --
    --   vim.api.nvim_buf_set_lines(header_buf, 0, -1, false, { "🧭  My Plugin — Header" })
    --
    --   -- Optional highlight
    --   vim.api.nvim_set_hl(0, "MyHeader", { fg = "#ffffff", bg = "#005f87", bold = true })
    --   vim.api.nvim_buf_add_highlight(header_buf, -1, "MyHeader", 0, 0, -1)
    --
    --   -- ────────────────────────────────────────────────
    --   -- 2. CONTENT AREA (split into columns)
    --   -- ────────────────────────────────────────────────
    --   -- Split horizontally (below header)
    --   vim.cmd("belowright split")
    --   local content_win = vim.api.nvim_get_current_win()
    --   vim.cmd("resize " .. (vim.o.lines - 3)) -- leave room for header and cmdline
    --
    --   -- Left buffer
    --   local left_buf = vim.api.nvim_create_buf(false, true)
    --   vim.api.nvim_win_set_buf(content_win, left_buf)
    --   vim.bo[left_buf].buftype = "nofile"
    --   vim.bo[left_buf].bufhidden = "wipe"
    --   vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, {
    --     "╔════════════════╗",
    --     "║   Left Zone    ║",
    --     "╚════════════════╝",
    --   })
    --
    --   -- Create vertical split for the right zone
    --   vim.cmd("vsplit")
    --   local right_win = vim.api.nvim_get_current_win()
    --   local right_buf = vim.api.nvim_create_buf(false, true)
    --   vim.api.nvim_win_set_buf(right_win, right_buf)
    --   vim.bo[right_buf].buftype = "nofile"
    --   vim.bo[right_buf].bufhidden = "wipe"
    --   vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, {
    --     "╔════════════════╗",
    --     "║   Right Zone   ║",
    --     "╚════════════════╝",
    --   })
    --
    --   vim.cmd("wincmd =") -- balance columns
    --
    --   -- ────────────────────────────────────────────────
    --   -- 3. Keymaps and behavior
    --   -- ────────────────────────────────────────────────
    --   local close_all = function()
    --     vim.cmd("tabclose")
    --   end
    --   for _, buf in ipairs({ header_buf, left_buf, right_buf }) do
    --     vim.keymap.set("n", "q", close_all, { buffer = buf, nowait = true })
    --   end
    --
    --   -- Prevent accidental resizing of header
    --   vim.api.nvim_create_autocmd("WinResized", {
    --     callback = function()
    --       -- ensure header stays 1 line tall
    --       vim.cmd("wincmd t")
    --       vim.cmd("resize 1")
    --     end
    --   })
end

-- Open a full-screen plugin window (uses a tab)
local function open_fullscreen()
    -- Create a new tab
    vim.cmd("tabnew")

    -- Create a new buffer for your plugin
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)

    -- Set some buffer options
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true

    -- Example content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "╔════════════════════════════════════════╗",
        "║      Welcome to My Plugin Window       ║",
        "╚════════════════════════════════════════╝",
        "",
        "Press q to close.",
    })

    -- Map `q` to close the tab
    vim.keymap.set("n", "q", function()
        vim.cmd("tabclose")
    end, { buffer = buf, nowait = true })
end

function M.run_toggle_vaultview()
    dprint("TOTOMONGARS")

    -- open_complex_ui()
    open_ui_with_tabs()
    -- local list_win = Snacks.win({
    --     width = cfg.width,
    --     height = list_height,
    --     zindex = cfg.zindex,
    --     -- border = cfg.border,
    --     border = "rounded",
    --     relative = "editor",
    --     row = cfg.row, -- align all lists at top of view_win
    --     col = cfg.col, -- at creation, put them all at the top left. will be recomputed in render function
    --     show = true,
    --     enter = false,
    --     backdrop = false,
    --     focusable = true,
    --     keys = set_keymap(lself, class_name),
    --     bo = { modifiable = true },
    --     -- bo = { modifiable = true, filetype = filetype },
    -- })
    -- list_win:hide()

    -- local runner = require("vaultview._commands.open.runner")
    --
    -- runner.run_toggle()
end

return M
