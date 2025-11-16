local View = {}
View.__index = View

local wf = require("vaultviewui._core.windowfactory")

-- WARN VaultData is the data from the global VaultData but for the specific board the layout is associated to...shall be renamed to BoardData ?
function View.new(VaultData, board_idx, board_config, layout, header_win)
    local self = setmetatable({}, View)
    self.VaultData = VaultData
    self.board_idx = board_idx
    self.viewData = VaultData.boards[board_idx]
    self.board_config = board_config
    self.header_win = header_win
    self.state = {
        focused = { page = 1, list = 1, entry = 0 },
        pages = {},
        -- expanded = {},
        -- show = {},
    }
    self.pages_names, self.viewWindows, self.state.pages = wf.create_board_view_windows(VaultData, board_idx, layout)

    dprint("Initial View State:", vim.inspect(self.state))
    dprint("Initial View Windows:", vim.inspect(self.viewWindows))
    self.layout = layout.new(self.viewData, self.viewWindows, self.state)

    -- TODO perhaps put it in layout.new
    if self.viewData.pages and #self.viewData.pages > 0 then
        local first_page = self.viewData.pages[1]
        if first_page.lists and #first_page.lists > 0 then
            local first_list = first_page.lists[1]
            if first_list.entries and #first_list.entries > 0 then
                -- Initialize first entry as focused
                self.state.focused = { page = 1, list = 1, entry = 1 }
            end
        end
    end

    self:recompute_focused_entry_index()

    return self
end

function View:debug()
    dprint("View Debug Info:")
    dprint("Board Index:", self.board_idx)
    self.state.expansion = true
    self.layout:debug()
    dprint("State:", vim.inspect(self.state))
end

-- -- Internal helper to mark expansion state
-- function View:is_expanded(page_idx, entry_idx)
--     return self.state.expanded[page_idx] and self.state.expanded[page_idx][entry_idx]
-- end
--
-- function View:set_expanded(page_idx, entry_idx, value)
--     self.state.expanded[page_idx] = self.state.expanded[page_idx] or {}
--     self.state.expanded[page_idx][entry_idx] = value
-- end
--
-- -- Create or update a single entry
-- function View:render_entry(page_idx, entry_idx, opts)
--     local board_idx = self.board_idx
--     local entry = Data.Boards[board_idx].pages[page_idx].entries[entry_idx]
--     local expanded = self:is_expanded(page_idx, entry_idx)
--
--     local buf = UIState:get_buffer(board_idx, page_idx, entry_idx)
--     local win = UIState:get_window(board_idx, page_idx, entry_idx)
--
--     if not buf or not vim.api.nvim_buf_is_valid(buf) then
--         buf = vim.api.nvim_create_buf(false, true)
--         vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
--         UIState:set(board_idx, page_idx, entry_idx, buf, win)
--     end
--
--     local lines = expanded and entry.content or { entry.content[1] .. " ..." }
--     vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
--
--     if not win or not vim.api.nvim_win_is_valid(win) then
--         win = vim.api.nvim_open_win(buf, false, {
--             relative = "editor",
--             width = opts.width or 40,
--             height = #lines + 1,
--             row = opts.row or 2 + (entry_idx - 1) * 5,
--             col = opts.col or 10,
--             style = "minimal",
--             border = "rounded",
--         })
--         UIState:set(board_idx, page_idx, entry_idx, buf, win)
--     end
--
--     if self.state.focused.page == page_idx and self.state.focused.entry == entry_idx then
--         vim.api.nvim_win_set_option(win, "winhl", "Normal:Visual")
--     else
--         vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal")
--     end
-- end
--
-- function View:focus_next_entry()
--     local f = self.state.focused
--     f.entry = f.entry + 1
--     self:render_board()
-- end
--
-- function View:toggle_entry_expansion()
--     local f = self.state.focused
--     local current = self:is_expanded(f.page, f.entry)
--     self:set_expanded(f.page, f.entry, not current)
--     self:render_board()
-- end
--
-- function View:render_board()
--     local board = Data.Boards[self.board_idx]
--     for page_idx, page in ipairs(board.pages) do
--         for entry_idx, _ in ipairs(page.entries) do
--             self:render_entry(page_idx, entry_idx, { col = 5, width = 40 })
--         end
--     end
-- end

function View:render_page_selection(start_line)
    local win = self.header_win
    local pages = self.pages_names
    local active_page = self.state.focused.page

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
        vim.api.nvim_buf_add_highlight(buf, -1, h.group, start_line, prefix_len + h.start_col, prefix_len + h.end_col)
    end

    vim.api.nvim_buf_add_highlight(buf, -1, "TabSeparator", 5, 0, -1)
    vim.bo[buf].modifiable = false
end

function View:render(page_selection_line)
    if page_selection_line ~= nil then
        self.page_selection_line = page_selection_line
    end
    self:render_page_selection(self.page_selection_line)
    self.layout:render()
    self:focus()
end

function View:hide()
    self.layout:hide(self.viewWindows, self.state)
end

function View:getFocusedWindow()
    local focused_page_idx, focused_list_idx, focused_entry_idx =
        self.state.focused.page, self.state.focused.list, self.state.focused.entry
    local focused_page = self.viewWindows.pages[focused_page_idx]
    local focused_list = focused_page.lists[focused_list_idx]
    if focused_entry_idx == 0 then
        return focused_list.win
    else
        return focused_list.items[focused_entry_idx]
    end
end

function View:focus()
    local focused_window = self:getFocusedWindow()

    if focused_window then
        focused_window:focus()
    end
end

function View:recompute_focused_list_index()
    local focused_page_idx = self.state.focused.page
    local focused_page = self.viewWindows.pages[focused_page_idx]

    local num_lists = #focused_page.lists

    -- If the current focused_list is greater than num_lists, set it to num_lists
    -- else if the focused_list is 0, set it to 1 else keep it as is

    if self.state.focused.list > num_lists then
        return num_lists
    end

    if self.state.focused.list ~= 0 then
        return self.state.focused.list
    else
        return 1
    end
end

function View:recompute_focused_entry_index()
    local focused_page_idx = self.state.focused.page
    local focused_page = self.viewWindows.pages[focused_page_idx]

    local focused_list_idx = self.state.focused.list
    local focused_list = focused_page.lists[focused_list_idx]

    local num_entries = #focused_list.items

    -- If there are no entries, focus on 0.
    -- else:
    -- If the current focused_entry is greater than num_entries, set it to num_entries
    -- else if the focused_entry is 0, set it to 1 else keep it as is

    if num_entries == 0 then
        return 0
    end

    if self.state.focused.entry > num_entries then
        return num_entries
    end

    if self.state.focused.entry ~= 0 then
        return self.state.focused.entry
    else
        return 1
    end
end

function View:previous_page()
    self:hide()
    self.state.focused.page = self.state.focused.page - 1
    if self.state.focused.page < 1 then
        self.state.focused.page = #self.viewWindows.pages
    end
    self.state.focused.list = self:recompute_focused_list_index()
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:render()
end

function View:next_page()
    self:hide()
    self.state.focused.page = self.state.focused.page + 1
    if self.state.focused.page > #self.viewWindows.pages then
        self.state.focused.page = 1
    end
    self.state.focused.list = self:recompute_focused_list_index()
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:render()
end

function View:focus_first_list()
    self.state.focused.list = 1
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:focus()
end

-- TODO perhaps delegate something to layout as it may change the layout windows?
function View:focus_previous_list()
    self.state.focused.list = math.max(1, self.state.focused.list - 1)
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:focus()
end

-- TODO perhaps delegate something to layout as it may change the layout windows?
function View:focus_center_list()
    self.state.focused.list = self.state.center_list_index or math.ceil(#self.viewWindows.pages[self.state.focused.page].lists / 2)
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:focus()
end

function View:focus_next_list()
    self.state.focused.list =
        math.min(self.state.focused.list + 1, #self.viewWindows.pages[self.state.focused.page].lists)
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:focus()
end

function View:focus_last_list()
    self.state.focused.list = #self.viewWindows.pages[self.state.focused.page].lists
    self.state.focused.entry = self:recompute_focused_entry_index()
    self:focus()
end

function View:focus_first_entry()
    if #self.viewWindows.pages[self.state.focused.page].lists[self.state.focused.list].items == 0 then
        self.state.focused.entry = 0
    else
        self.state.focused.entry = 1
    end
    self:focus()
end

function View:focus_previous_entry()
    self.state.focused.entry = math.max(1, self.state.focused.entry - 1)
    self:focus()
end

function View:focus_next_entry()
    local num_entries = #self.viewWindows.pages[self.state.focused.page].lists[self.state.focused.list].items
    self.state.focused.entry = math.min(self.state.focused.entry + 1, num_entries)
    self:focus()
end

function View:focus_last_entry()
    local num_entries = #self.viewWindows.pages[self.state.focused.page].lists[self.state.focused.list].items
    self.state.focused.entry = num_entries
    self:focus()
end

function View:open_in_neovim()
    if self.state.focused.list == 0 or self.state.focused.entry == 0 then
        -- vim.notify("No focused entry to open", vim.log.levels.WARN)
        return
    end

    local entry = self:getDataEntry(self.state.focused.page, self.state.focused.list, self.state.focused.entry)
    if not entry then
        -- vim.notify("No focused entry to open", vim.log.levels.WARN)
        return
    end
    local filepath = entry.filepath

    local expanded_path = vim.fn.expand(filepath)
    if vim.fn.filereadable(expanded_path) == 0 then
        -- vim.notify("File does not exist: " .. expanded_path, vim.log.levels.ERROR)
        return
    end

    local win = require("snacks").win({
        file = expanded_path,
        width = 0.9,
        height = 0.95,
        zindex = 50,
        border = "rounded",
        relative = "editor",
        bo = { modifiable = true },
        keys = { q = "close" },
        on_close = function()
            require("vaultviewui").refresh_focused_entry_content()
        end,
        wo = {
            wrap = true,
            linebreak = true,
        },
    })
end

function View:open_in_obsidian(vaultname)
    if self.state.focused.list == 0 or self.state.focused.entry == 0 then
        -- vim.notify("No focused entry to open", vim.log.levels.WARN)
        return
    end

    local focused_entry = self:getDataEntry(self.state.focused.page, self.state.focused.list, self.state.focused.entry)
    if not focused_entry then
        -- vim.notify("No focused focused_entry to open", vim.log.levels.WARN)
        return
    end
    local filepath = focused_entry.filepath
    local title = focused_entry.title
    if not filepath then
        -- vim.notify("No file path for focused entry", vim.log.levels.WARN)
        return
    end
    local path = vim.fn.fnamemodify(filepath, ":p") -- absolute path
    -- https://help.obsidian.md/Extending+Obsidian/Obsidian+URI
    local uri = "obsidian://open?path=" .. vim.fn.escape(path, " ")
    -- print("Opening Obsidian URI:", uri)

    local cmd = string.format("!xdg-open 'obsidian://open?vault=%s&file=%s'", vaultname, title)
    -- print("Executing command:", cmd)
    vim.cmd(cmd)
end

function View:getDataEntry(page_idx, list_idx, entry_idx)
    local entry = self.viewData.pages[page_idx].lists[list_idx].items[entry_idx]
    if not entry then
        return nil
    end
    return entry
end

function View:getWindowEntry(page_idx, list_idx, entry_idx)
    local entry_win = self.viewWindows.pages[page_idx].lists[list_idx].items[entry_idx]
    if not entry_win then
        return nil
    end
    return entry_win
end

function View:refresh_entry_content(page_idx, list_idx, entry_idx, user_commands)
    if page_idx == 0 or list_idx == 0 or entry_idx == 0 then
        return
    end
    local entry = self:getDataEntry(page_idx, list_idx, entry_idx)
    if not entry then
        return
    end

    local reparsed_content = require("vaultviewui._core.parsers.parsertrait").findContentInEntryFile(
        entry.filepath,
        user_commands,
        self.board_config
    )
    local new_content = {}

    for _, line in ipairs(reparsed_content) do
        table.insert(new_content, "- " .. line)
    end
    entry.content = new_content

    local entry_win = self:getWindowEntry(page_idx, list_idx, entry_idx)

    wf.setNewContent(entry_win, new_content)
end

function View:refresh_focused_entry_content(user_commands)
    self:refresh_entry_content(
        self.state.focused.page,
        self.state.focused.list,
        self.state.focused.entry,
        user_commands
    )
end

function View:fast_refresh()
    for idx_page, page in ipairs(self.viewData.pages) do
        for idx_list, list in ipairs(page.lists) do
            for idx_entry, _ in ipairs(list.items) do
                self:refresh_entry_content(idx_page, idx_list, idx_entry)
            end
        end
    end
end

return View
