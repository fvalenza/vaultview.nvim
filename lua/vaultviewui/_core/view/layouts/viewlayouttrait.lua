--- # ViewLayoutTrait
--- Mixin/trait providing core layout computation and rendering logic for a ViewLayout.
---
--- This trait handles:
--- - Collapsing/expanding lists
--- - Computing width/height for list windows
--- - Computing position of list windows and item windows
--- - Rendering (show/hide) logic per list and entry
--- - Centering lists horizontally in the viewport
---
--- @class ViewLayoutTrait
--- @field __name string                    Layout name (matching keys in Constants)
--- @field viewData table                   Data model for pages/lists/items
--- @field viewState table                  UI navigation state (expanded, pages, etc.)
--- @field viewWindows table                Table of window objects for pages/lists/items
local ViewLayoutTrait = {}

local Constants = require("vaultviewui._ui.constants")


---------------------------------------------------------------------
-- Debugging
---------------------------------------------------------------------

function ViewLayoutTrait:debug()
    dprint("ViewLayoutTrait debug:")
    dprint(self.__name)
    dprint(self.viewWindows)
    dprint(self.viewState)
end


---------------------------------------------------------------------
-- List state manipulation
---------------------------------------------------------------------

--- Set the visible range of lists in a page. (all visible will be drawn expanded, others will be drawn collapsed)
---
--- @param page_idx integer  Page index
--- @param left_idx integer  First visible list index
--- @param right_idx integer Last visible list index
function ViewLayoutTrait:set_lists_visibility_window(page_idx, left_idx, right_idx)
    self.viewState.pages[page_idx].lists_visibility.first = left_idx
    self.viewState.pages[page_idx].lists_visibility.last = right_idx
    self.viewState.pages[page_idx].lists_visibility.length = right_idx - left_idx + 1
end

--- Set the state of a list to Collapse and hide to all items in it.
---
--- @param page_idx integer
--- @param list_idx integer
function ViewLayoutTrait:collapse_list(page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = false

    for _, item in ipairs(self.viewState.pages[page_idx].lists[list_idx].items) do
        item.show = false
    end
end

--- Set the state of a list to Expand and show to all items in it.
---
--- @param page_idx integer
--- @param list_idx integer
function ViewLayoutTrait:expand_list(page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = true

    for _, item in ipairs(self.viewState.pages[page_idx].lists[list_idx].items) do
        item.show = true
    end
end


---------------------------------------------------------------------
-- List window rendering computation
---------------------------------------------------------------------

--- Compute window layout (col, row, width, height, winbar, footer, items)
--- for a single list window and its items and return computed width.
---
--- This handles both **expanded** and **collapsed** cases.
---
--- @param idx_list integer                   List index
--- @param list table                         List model (contains title, items)
--- @param list_state table                   UI state for this list
--- @param list_win table                     Snacks window object for the list
--- @param layout_name string                 Layout identifier (matching Constants)
--- @param col_offset integer                 Horizontal starting column
---
--- @return integer width                     Width computed for this list
function ViewLayoutTrait:compute_list_window_rendering(idx_list, list, list_state, list_win, layout_name, col_offset)
    local Constants = Constants -- local reference for optimizing lookup ?
    local expanded = list_state.expanded
    local list_entry_page = list_state.current_page
    local num_entry_pages = #list_state.list_pages

    ----------------------------------------------------------------
    -- Width
    ----------------------------------------------------------------
    local width
    if expanded then
        width = Constants.list_win[layout_name].width
    else
        width = Constants.list_win_close[layout_name].width
    end

    ----------------------------------------------------------------
    -- Title content + height (if expanded, put title in Winbar else put it in list buffer vertically)
    ----------------------------------------------------------------
    if expanded then
        -- Winbar text
        list_win.opts.wo.winbar = (" %s %%= %d "):format(list.title, #list.items)

        -- Clear list buffer content
        vim.api.nvim_buf_set_lines(list_win.buf, 0, -1, false, {})

        -- Height
        list_win.opts.height = Constants.list_win[layout_name].height

        -- Footer (entries page)
        if num_entry_pages == 0 then
            list_win.opts.footer = {
                { "<A-k> ↑ ", "Comment" },
                { "-", "Normal" },
                { " ↓ <A-j>", "Comment" },
            }
        else
            list_win.opts.footer = {
                { "<A-k> ↑ ", "Comment" },
                { ("%d/%d"):format(list_entry_page, num_entry_pages), "Normal" },
                { " ↓ <A-j>", "Comment" },
            }
        end
    else
        -- Collapsed: winbar shows only item count
        list_win.opts.wo.winbar = (" %d "):format(#list.items)

        -- Show title vertically
        local chars = {}
        for i = 1, #list.title do
            chars[i] = list.title:sub(i, i)
        end
        vim.api.nvim_buf_set_lines(list_win.buf, -1, -1, false, chars)

        local height = #chars + 1 + 1
        list_win.opts.height = height
        list_win.opts.footer = ""
    end

    ----------------------------------------------------------------
    -- Horizontal placement
    ----------------------------------------------------------------
    list_win.opts.col = col_offset
    list_win.opts.width = width

    -- Stop here if collapsed
    if not expanded then
        return width
    end

    ----------------------------------------------------------------
    -- Expanded → compute each entry window position
    ----------------------------------------------------------------
    local list_pages = list_state.list_pages
    local base_row = Constants.list_win[layout_name].row + 1 + 1

    for page_num, page_range in ipairs(list_pages) do
        local row_offset = base_row

        for card_index = page_range.start, page_range.stop do
            local card = list.items[card_index]
            if card then
                local card_win = self.viewWindows.pages[self.viewState.focused.page]
                    .lists[idx_list].items[card_index]

                card_win.opts.width = width
                card_win.opts.col = list_win.opts.col + 1

                local card_expanded = list_state.items[card_index].expanded
                local height = card_expanded and Constants.card_win[layout_name].height
                    or Constants.card_win_close.height

                card_win.opts.row = row_offset
                card_win.opts.height = height

                row_offset = row_offset + height + 1 + 1
            end
        end
    end

    return width
end


---------------------------------------------------------------------
-- Rendering of a list
---------------------------------------------------------------------

--- Rendering a list by page_idx/list_idx (show/hide). 
--- Simplified wrapper on render_list called when switching entries in a list that needs update of list rendering
---
--- @param page_idx integer
--- @param list_idx integer
function ViewLayoutTrait:render_single_list(page_idx, list_idx)
    local list_state = self.viewState.pages[page_idx].lists[list_idx]
    local list_win_obj = self.viewWindows.pages[page_idx].lists[list_idx]

    self:render_list(list_idx, list_state, list_win_obj)
end

--- Rendering for a list and its entries:
---
--- @param idx_list integer
--- @param list_state table
--- @param list_win_obj table
function ViewLayoutTrait:render_list(idx_list, list_state, list_win_obj)
    -- Fully hidden list
    if not list_state.show then
        list_win_obj.win:hide()
        for _, w in ipairs(list_win_obj.items or {}) do w:hide() end
        return
    end

    -- Always show the list window itself
    list_win_obj.win:show()

    -- If collapsed → hide all items
    if not list_state.expanded then
        for _, w in ipairs(list_win_obj.items or {}) do w:hide() end
        return
    end

    -- If expanded → show only current page
    local page_info = list_state.list_pages[list_state.current_page]
    if not page_info then
        -- no items
        for _, w in ipairs(list_win_obj.items or {}) do w:hide() end
        return
    end

    for item_idx, item_win in ipairs(list_win_obj.items or {}) do
        if item_idx >= page_info.start and item_idx <= page_info.stop then
            item_win:show()
        else
            item_win:hide()
        end
    end
end


--------------------------------------------------------------------
-- Compute the position of each window for list/entry depending on the state
-- Update title on list window wheter it's expanded or collapsed
--------------------------------------------------------------------

--- Compute position and dimensions of all list & entry windows.
---
--- @param page_idx string|nil   index of the page for which to compute rendering information
--- @param list_idx string|nil   index of the list for which to compute rendering information
function ViewLayoutTrait:compute_single_list(page_idx, list_idx)
    local layout_name = self.__name
    local page = self.viewData.pages[page_idx]
    local windows = self.viewWindows.pages[page_idx]
    local state = self.viewState.pages[page_idx]

    local list = page.lists[list_idx]
    local list_state = state.lists[list_idx]
    local list_win_obj = windows.lists[list_idx]
    local list_win = list_win_obj.win

    local col_offset = list_win.opts.col

    self:compute_list_window_rendering(
        list_idx, list, list_state, list_win,
        layout_name, col_offset
    )
end

--- Compute dimensions/positionning for all lists in the ViewLayout
---
--- @param layout_name string|nil
function ViewLayoutTrait:compute_windows_rendering(layout_name)
    layout_name = layout_name or self.__name

    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState

    local focused_page = viewState.focused.page
    local col_offset = 1 -- Start by putting them at the leftmost side. Will be corrected later to center everything

    for idx_list, list in ipairs(viewData.pages[focused_page].lists or {}) do
        local list_win = viewWindows.pages[focused_page].lists[idx_list].win
        local list_state = viewState.pages[focused_page].lists[idx_list]

        -- compute each list
        local width = self:compute_list_window_rendering(
            idx_list, list, list_state, list_win,
            layout_name, col_offset
        )

        -- move to the next column
        col_offset = col_offset + width + 1 + 1
    end

    -- Center horizontally inside the editor width
    local remaining_space = vim.o.columns - (col_offset - 1)
    local offset = math.floor(remaining_space / 2)

    col_offset = offset + 1
    for idx_list, _ in ipairs(viewData.pages[focused_page].lists or {}) do
        local list_win_obj = viewWindows.pages[focused_page].lists[idx_list]
        list_win_obj.win.opts.col = col_offset

        col_offset = col_offset + list_win_obj.win.opts.width + 1 + 1

        for _, item_win in ipairs(list_win_obj.items or {}) do
            if not item_win.opts then
                goto continue_item_loop
            end
            item_win.opts.col = list_win_obj.win.opts.col + 1
            ::continue_item_loop::
        end
    end
end


---------------------------------------------------------------------
-- Main Public Render function
---------------------------------------------------------------------

--- Main render call: computes layout, then applies visibility state.
function ViewLayoutTrait:render()
    self:compute_windows_rendering()

    local focused_page = self.viewState.focused.page
    local lists = self.viewWindows.pages[focused_page].lists

    for idx_list, list_win_obj in ipairs(lists) do
        local list_state = self.viewState.pages[focused_page].lists[idx_list]
        self:render_list(idx_list, list_state, list_win_obj)
    end
end


---------------------------------------------------------------------
-- Hide / Close helpers
---------------------------------------------------------------------

--- Hide all windows of the focused page.
---
--- @param viewWindows table
--- @param viewState table
function ViewLayoutTrait:hide(viewWindows, viewState)
    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then entry:hide() end
        end
        list.win:hide()
    end
end

--- Close all windows of the focused page.
---
--- @param viewWindows table
--- @param viewState table
function ViewLayoutTrait:close(viewWindows, viewState)
    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then entry:close() end
        end
        list.win:close()
    end
end

return ViewLayoutTrait
