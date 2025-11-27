--- # View
--- View Wrapper for **one Vault Board**.
---
--- A View handles:
--- - board-specific data
--- - UI state (focused page/list/entry)
--- - window objects for every list and entry
--- - rendering, focusing, paging, list navigation
--- - actions such as “open in Neovim”, “open in Obsidian”, “refresh”
---
--- Each View instance is tied to:
--- - One board (`VaultData.boards[board_idx]`)
--- - One layout implementation
--- - A set of windows created by `windowfactory.create_board_view_windows`
---
--- Some actions of the View might be delegated to the layout
---
--- @class View
--- @field _opts table                         Plugin options
--- @field board_idx integer                   Index of the board this view represents
--- @field viewData table                      Data of the selected board
--- @field board_config table                  Per-board plugin configuration
--- @field header_win table                    Snacks window object for the header
--- @field layout table                        Layout instance controlling positioning
--- @field pages_names string[]                List of page names from Vault data
--- @field viewWindows table                   Window objects for all pages/lists/entries
--- @field state table                         UI navigation state
--- @field page_selection_line integer|nil     Line number where the page selection starts (used by views)
local View = {}
View.__index = View

local wf = require("vaultview._core.windowfactory")
local logging = require("mega.logging")
local _LOGGER = logging.get_logger("vaultview.core.view.init")

--- Create a new View instance for a given board index (among the boards configured by user in plugin setup).
---
--- @param viewData table       The vault data for specified board index
--- @param board_idx integer     Index of the board this View handles
--- @param layout table          Layout class/table with .new() constructor
--- @param header_win table      Snacks window instance for page selection header
---
---@return View|nil, string?   -- view, err
function View.new(viewData, board_idx, layout, header_win)
    local self = setmetatable({}, View)

    self._opts = require("vaultview").opts
    self.board_idx = board_idx
    self.viewData = viewData
    self.board_config = self._opts.boards[board_idx]
    self.header_win = header_win
    self.state = {
        focused = { page = 1, list = 1, entry = 0 },
        pages = {},
    }
    if not self.viewData or not self.viewData.pages or #self.viewData.pages == 0 then
        local msg = "Cannot create View: no pages in viewData for board index " .. tostring(board_idx)
        _LOGGER:error(msg)
        -- error(msg) -- TODO decide if error is too harsh or should return nil + error message and test it in calling code
        return nil, msg -- TODO decide if error is too harsh or should return nil + error message and test it in calling code
    end

    -- TODO(roadmap) Do not create all windows at once, only create those needed for the current page, and create others on demand when needed
    -- This can be done with a boolean "loaded" flag in self.state.pages and when switching page, check if loaded, if not create windows for that page
    -- but we will need self.pages_names to be initialized here anyway and create at least the first page windows + state
    self.pages_names, self.viewWindows, self.state.pages = wf.create_board_view_windows(self.viewData, layout)

    self.layout = layout.new(self.viewData, self.viewWindows, self.state)

    -- Initialize focused indexes
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

    self:compute_focused_entry_index_for_current_list()

    return self
end

--- Print debugging information about the current View.
function View:debug()
    _LOGGER:debug("View Debug Info:")
    _LOGGER:debug("Board Index:", self.board_idx)
    _LOGGER:debug("ViewData:", self.viewData)
    self.layout:debug()
end

--- Render the header page selection bar.
function View:render_page_selection()
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
    local prefix = "<S-h>  <--  " -- TODO (roadmap) prefix and suffix shall be the one from keymaps of the Plugs "VaultViewNextPage/VaultViewPreviousPage", taking into account user remaps
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

    vim.api.nvim_buf_set_lines(buf, self.page_selection_line, -1, false, lines)

    -- Apply highlights (offset by padding + prefix)
    local prefix_len = padding + #prefix
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            h.group,
            self.page_selection_line,
            prefix_len + h.start_col,
            prefix_len + h.end_col
        )
    end

    vim.api.nvim_buf_add_highlight(buf, -1, "TabSeparator", 5, 0, -1)
    vim.bo[buf].modifiable = false
end

--- Render the entire View (PArt concerning the page selection in the header + layout).
function View:render()
    self:render_page_selection()
    self.layout:render()
    self:focus()
end

--- Hide all windows associated with this view's layout.
function View:hide()
    self.layout:hide(self.viewWindows, self.state)
end

--- Get the window object currently focused (based on indexes of the viewState).
---
--- @return table|nil window     The Snacks window currently focused
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

--- Put cursor focus on the currently focused window (based on indexes of the viewState).
function View:focus()
    local focused_window = self:getFocusedWindow()

    if focused_window then
        focused_window:focus()
    end
end

--- Compute the valid focused list index after changing page.
---
--- If the current focused_list is greater than num_lists, set it to num_lists
--- else if the focused_list is 0, set it to 1 else keep it as is
---
--- @return integer list_idx
function View:compute_focused_list_index_for_current_page()
    local focused_page_idx = self.state.focused.page
    local focused_page = self.viewWindows.pages[focused_page_idx]
    local num_lists = #focused_page.lists

    if self.state.focused.list > num_lists then
        return num_lists
    end

    if self.state.focused.list ~= 0 then
        return self.state.focused.list
    else
        return 1
    end
end

--- Compute the entry index after jumping from one list to another.
---
--- If there are no entries, focus on 0.
--- else:
--- If the current focused_entry is greater than num_entries, set it to num_entries
--- else if the focused_entry is 0, set it to 1 else keep it as is
--- Takes into account that the lists may be on different list_pages
---
--- @param from_list_idx integer
--- @param to_list_idx integer
--- @return integer entry_idx
function View:compute_entry_index_after_list_jump(from_list_idx, to_list_idx)
    local state = self.state
    local focused_page_idx = state.focused.page
    local focused_list_idx = state.focused.list or to_list_idx

    local old_focused_list_idx = from_list_idx
    local old_focused_entry_idx = state.focused.entry
    local new_list_num_entries = #self.viewWindows.pages[focused_page_idx].lists[focused_list_idx].items
    local old_list_num_entries = #self.viewWindows.pages[focused_page_idx].lists[old_focused_list_idx].items

    if new_list_num_entries == 0 then
        return 0
    end
    local old_pstart, old_list_state, old_list_pages, old_list_cur_page
    if old_list_num_entries == 0 then
        old_pstart = 1
    else
        old_list_state = state.pages[focused_page_idx].lists[old_focused_list_idx]
        old_list_pages = old_list_state.list_pages
        old_list_cur_page = old_list_state.current_page
        old_pstart = old_list_pages[old_list_cur_page].start
    end

    local list_state = state.pages[focused_page_idx].lists[focused_list_idx]
    local pages = list_state.list_pages
    local cur_page = list_state.current_page
    local pstart = pages[cur_page].start

    if old_list_num_entries == 0 then
        return pstart
    end

    local old_relative_entry_idx = old_focused_entry_idx - old_pstart + 1
    local new_focused_entry_idx = pstart + old_relative_entry_idx - 1

    if new_focused_entry_idx > new_list_num_entries then
        return new_list_num_entries
    end

    if new_focused_entry_idx ~= 0 then
        return new_focused_entry_idx
    else
        return 1
    end
end

--- Compute valid entry index in current list after changes.
---
--- If there are no entries, focus on 0.
--- else:
--- If the current focused_entry is greater than num_entries, set it to num_entries
--- else if the focused_entry is 0, set it to 1 else keep it as is
--- @return integer entry_idx
function View:compute_focused_entry_index_for_current_list()
    local focused_page = self.viewWindows.pages[self.state.focused.page]
    local focused_list = focused_page.lists[self.state.focused.list]
    local num_entries = #focused_list.items

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

--- Focus previous page (cyclic).
function View:previous_page()
    self:hide()
    self.state.focused.page = self.state.focused.page - 1
    if self.state.focused.page < 1 then
        self.state.focused.page = #self.viewWindows.pages
    end
    self.state.focused.list = self:compute_focused_list_index_for_current_page()
    self.state.focused.entry = self:compute_focused_entry_index_for_current_list()
    self:render()
    self:focus()
end

--- Focus next page (cyclic).
function View:next_page()
    self:hide()
    self.state.focused.page = self.state.focused.page + 1
    if self.state.focused.page > #self.viewWindows.pages then
        self.state.focused.page = 1
    end
    self.state.focused.list = self:compute_focused_list_index_for_current_page()
    self.state.focused.entry = self:compute_focused_entry_index_for_current_list()
    self:render()
    self:focus()
end

--- Focus the first list in the page.
function View:focus_first_list()
    while self.state.focused.list > 1 do
        self:focus_previous_list()
    end
end

--- Move focus to previous list.
function View:focus_previous_list()
    local start_lists_visibility = self.state.pages[self.state.focused.page].lists_visibility.first
    local end_lists_visibility = self.state.pages[self.state.focused.page].lists_visibility.last

    local old_focused_list = self.state.focused.list

    -- compute new focused list
    self.state.focused.list = math.max(1, self.state.focused.list - 1)
    self.state.focused.entry = self:compute_entry_index_after_list_jump(old_focused_list, self.state.focused.list)

    -- adjust lists visibility if needed
    if self.state.focused.list < start_lists_visibility then
        self.layout:collapse_list(self.state.focused.page, end_lists_visibility)
        self.layout:expand_list(self.state.focused.page, self.state.focused.list)

        self.layout:set_lists_visibility_window(
            self.state.focused.page,
            self.state.focused.list,
            end_lists_visibility - 1
        )
        self:render()
    end

    self:focus()
end

--- Focus center list on the screen.
function View:focus_center_list()
    local current_focused_list = self.state.focused.list
    local focused_list_target = self.state.pages[self.state.focused.page].center_list_index

    if current_focused_list > focused_list_target then
        while current_focused_list > focused_list_target do
            self:focus_previous_list()
            current_focused_list = self.state.focused.list
        end
    else
        while current_focused_list < focused_list_target do
            self:focus_next_list()
            current_focused_list = self.state.focused.list
        end
    end
end

function View:focus_next_list()
    local start_lists_visibility = self.state.pages[self.state.focused.page].lists_visibility.first
    local end_lists_visibility = self.state.pages[self.state.focused.page].lists_visibility.last

    local old_focused_list = self.state.focused.list

    -- compute new focused list
    self.state.focused.list =
        math.min(self.state.focused.list + 1, #self.viewWindows.pages[self.state.focused.page].lists)
    self.state.focused.entry = self:compute_entry_index_after_list_jump(old_focused_list, self.state.focused.list)

    -- adjust lists visibility if needed
    if self.state.focused.list > end_lists_visibility then
        self.layout:collapse_list(self.state.focused.page, start_lists_visibility)
        self.layout:expand_list(self.state.focused.page, self.state.focused.list)

        self.layout:set_lists_visibility_window(
            self.state.focused.page,
            start_lists_visibility + 1,
            self.state.focused.list
        )
        -- render only if visibility changed
        self:render()
    end

    self:focus()
end

--- Focus last list in the page.
function View:focus_last_list()
    while self.state.focused.list < #self.viewWindows.pages[self.state.focused.page].lists do
        self:focus_next_list()
    end
end

--- Focus first entry of current list.
function View:focus_first_entry()
    local num_entries = #self.viewWindows.pages[self.state.focused.page].lists[self.state.focused.list].items
    if num_entries == 0 then
        self.state.focused.entry = 0
        return
    end
    local state = self.state
    local page_idx = state.focused.page
    local list_idx = state.focused.list
    local list_state = state.pages[page_idx].lists[list_idx]
    local cur_entry_page = list_state.current_page

    if cur_entry_page == 1 then
        self.state.focused.entry = 1
        self:focus()
    else
        list_state.current_page = 1
        self.state.focused.entry = 1
        self:render()
    end
end

--- Focus previous entry in current list/page.
function View:focus_previous_entry()
    local state = self.state
    local page_idx = state.focused.page
    local list_idx = state.focused.list
    local entry_idx = state.focused.entry

    local num_entries = #self.viewWindows.pages[page_idx].lists[list_idx].items

    if num_entries == 0 then
        return
    end

    local list_state = state.pages[page_idx].lists[list_idx]
    local entry_pages = list_state.list_pages
    local cur_entry_page = list_state.current_page

    local pstart = entry_pages[cur_entry_page].start

    --------------------------------------------------------------------
    -- Move within current entries page
    --------------------------------------------------------------------
    if entry_idx > pstart then
        state.focused.entry = entry_idx - 1
        return self:focus()
    end

    --------------------------------------------------------------------
    -- Move to previous entries page
    --------------------------------------------------------------------
    if cur_entry_page > 1 then
        list_state.current_page = cur_entry_page - 1

        -- move focus to last entry of previous page
        local prev_range = entry_pages[cur_entry_page - 1]
        state.focused.entry = prev_range.stop

        self.layout:compute_single_list(page_idx, list_idx)
        self.layout:render_single_list(page_idx, list_idx)

        return self:focus()
    end

    --------------------------------------------------------------------
    -- At very beginning → clamp
    --------------------------------------------------------------------
    state.focused.entry = pstart
    return self:focus()
end

--- Focus next entry in current list/page.
function View:focus_next_entry()
    local state = self.state
    local page_idx = state.focused.page
    local list_idx = state.focused.list
    local entry_idx = state.focused.entry

    local num_entries = #self.viewWindows.pages[page_idx].lists[list_idx].items

    if num_entries == 0 then
        return
    end

    local list_state = state.pages[page_idx].lists[list_idx]
    local entry_pages = list_state.list_pages
    local cur_entry_page = list_state.current_page

    local pstart = entry_pages[cur_entry_page].start
    local pend = entry_pages[cur_entry_page].stop

    --------------------------------------------------------------------
    -- Move within current page
    --------------------------------------------------------------------
    if entry_idx < pend then
        state.focused.entry = entry_idx + 1
        return self:focus()
    end

    --------------------------------------------------------------------
    -- Move to next page
    --------------------------------------------------------------------
    if cur_entry_page < #entry_pages then
        list_state.current_page = cur_entry_page + 1

        -- move focus to first entry of next page
        local next_range = entry_pages[cur_entry_page + 1]
        state.focused.entry = next_range.start

        self.layout:compute_single_list(page_idx, list_idx)
        self.layout:render_single_list(page_idx, list_idx)

        return self:focus()
    end

    --------------------------------------------------------------------
    -- At last entry of last page → clamp
    --------------------------------------------------------------------
    state.focused.entry = num_entries
    return self:focus()
end

--- Focus last entry in current list.
function View:focus_last_entry()
    local state = self.state
    local page_idx = state.focused.page
    local list_idx = state.focused.list
    local list_state = state.pages[page_idx].lists[list_idx]
    local entry_pages = list_state.list_pages
    local cur_entry_page = list_state.current_page
    local num_entries = #self.viewWindows.pages[self.state.focused.page].lists[self.state.focused.list].items

    if cur_entry_page == #entry_pages then
        self.state.focused.entry = num_entries
        self:focus()
    else
        list_state.current_page = #entry_pages
        self.state.focused.entry = num_entries
        self:render()
    end
end

--- Move to previous entry page (if paginated).
function View:focus_previous_entry_page()
    local state = self.state
    local page_idx = state.focused.page
    local list_idx = state.focused.list

    local list_state = state.pages[page_idx].lists[list_idx]
    local entry_pages = list_state.list_pages
    local cur_entry_page = list_state.current_page

    if cur_entry_page > 1 then
        list_state.current_page = cur_entry_page - 1

        -- move focus to first entry of previous page
        local prev_range = entry_pages[cur_entry_page - 1]
        state.focused.entry = prev_range.start

        self.layout:compute_single_list(page_idx, list_idx)
        self.layout:render_single_list(page_idx, list_idx)

        return self:focus()
    end
end

--- Move to next entry page (if paginated).
function View:focus_next_entry_page()
    local state = self.state
    local page_idx = state.focused.page
    local list_idx = state.focused.list

    local list_state = state.pages[page_idx].lists[list_idx]
    local entry_pages = list_state.list_pages
    local cur_entry_page = list_state.current_page

    if cur_entry_page < #entry_pages then
        list_state.current_page = cur_entry_page + 1

        -- move focus to first entry of next page
        local next_range = entry_pages[cur_entry_page + 1]
        state.focused.entry = next_range.start

        self.layout:compute_single_list(page_idx, list_idx)
        self.layout:render_single_list(page_idx, list_idx)

        return self:focus()
    end
end

function View:focus_entry_with_id(snacksWinId)
    for p_idx, page in ipairs(self.viewWindows.pages) do
        for l_idx, list in ipairs(page.lists) do
            for e_idx, entry in ipairs(list.items) do
                if entry.win_id == snacksWinId then
                    self.state.focused.page = p_idx
                    self.state.focused.list = l_idx
                    self.state.focused.entry = e_idx
                    self:render()
                    return self:focus()
                end
            end
        end
    end
end

--- Focus a list for which window has the given Snacks window ID.
---
--- @param snacksWinId integer
function View:focus_list_with_id(snacksWinId)
    for p_idx, page in ipairs(self.viewWindows.pages) do
        for l_idx, list in ipairs(page.lists) do
            if list.win.win_id == snacksWinId then
                self.state.focused.page = p_idx
                self.state.focused.list = l_idx
                self.state.focused.entry = 0
                self:render()
                return self:focus()
            end
        end
    end
end

--- Open focused entry in a Neovim floating window.
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

    require("snacks").win({
        file = expanded_path,
        width = 0.9,
        height = 0.95,
        zindex = 50,
        border = "rounded",
        relative = "editor",
        bo = { modifiable = true },
        keys = { q = "close" },
        on_close = function()
            require("vaultview").refresh_focused_entry_content()
        end,
        wo = {
            wrap = true,
            linebreak = true,
        },
    })
end

--- Open focused entry in Obsidian using URI.
---
function View:open_in_obsidian()
    local vaultname = self._opts.vault.name
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

    local cmd = string.format("!xdg-open 'obsidian://open?vault=%s&file=%s'", vaultname, title)
    vim.cmd(cmd)
end

--- Retrieve the entry from the table viewData at given page, list and entry indexes
---
--- @param page_idx integer
--- @param list_idx integer
--- @param entry_idx integer
--- @return table|nil entry
function View:getDataEntry(page_idx, list_idx, entry_idx)
    local entry = self.viewData.pages[page_idx].lists[list_idx].items[entry_idx]
    if not entry then
        return nil
    end
    return entry
end

--- Retrieve the Snacks window object from the table viewWindows at given page, list and entry indexes
---
--- @param page_idx integer
--- @param list_idx integer
--- @param entry_idx integer
--- @return table|nil win
function View:getWindowEntry(page_idx, list_idx, entry_idx)
    local entry_win = self.viewWindows.pages[page_idx].lists[list_idx].items[entry_idx]
    if not entry_win then
        return nil
    end
    return entry_win
end

--- Reparse and refresh the content of a specific entry.
---
--- @param page_idx integer
--- @param list_idx integer
--- @param entry_idx integer
function View:refresh_entry_content(page_idx, list_idx, entry_idx)
    if page_idx == 0 or list_idx == 0 or entry_idx == 0 then
        return
    end
    local entry = self:getDataEntry(page_idx, list_idx, entry_idx)
    if not entry then
        return
    end

    local reparsed_content =
        require("vaultview._core.parsers.parsertrait").findContentInEntryFile(entry.filepath, self.board_config)
    local new_content = {}

    for _, line in ipairs(reparsed_content) do
        table.insert(new_content, "- " .. line)
    end
    entry.content = new_content

    local entry_win = self:getWindowEntry(page_idx, list_idx, entry_idx)

    wf.setNewContent(entry_win, new_content)
end

--- Reparse/refresh the currently focused entry.
---
function View:refresh_focused_entry_content()
    self:refresh_entry_content(self.state.focused.page, self.state.focused.list, self.state.focused.entry)
end

--- Refresh content of all entries in the view (quick, incremental).
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
