local ViewLayoutTrait = {}

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")
local Keymaps = require("vaultviewui.keymaps")

function ViewLayoutTrait:debug()
    dprint("ViewLayoutTrait debug:")
    dprint(self.__name)
    dprint(self.vaultWindows)
    dprint(self.viewState)
end


function ViewLayoutTrait:set_lists_visibility_window(page_idx, left_idx, right_idx)
    self.viewState.pages[page_idx].lists_visibility.first = left_idx
    self.viewState.pages[page_idx].lists_visibility.last = right_idx
    self.viewState.pages[page_idx].lists_visibility.length = right_idx - left_idx + 1
end

function ViewLayoutTrait:collapse_list(page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = false

    for _, item in ipairs(self.viewState.pages[page_idx].lists[list_idx].items) do
        item.show = false
    end
end

function ViewLayoutTrait:expand_list(page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = true

    for _, item in ipairs(self.viewState.pages[page_idx].lists[list_idx].items) do
        item.show = true
    end
end

-- Compute the position of each window for list/entry depending on the state
-- Update title on list window wheter it's expanded or collapsed
function ViewLayoutTrait:compute_windows_rendering(layout_name)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState
    layout_name = layout_name or self.__name

    local col_offset = Constants.list_win[layout_name].col
    local focused_page = viewState.focused.page

    for idx_list, list in ipairs(viewData.pages[focused_page].lists or {}) do
        local list_win = viewWindows.pages[focused_page].lists[idx_list].win
        local list_expanded = viewState.pages[focused_page].lists[idx_list].expanded
        local list_entry_page = viewState.pages[focused_page].lists[idx_list].current_page
        local num_entry_pages = #viewState.pages[focused_page].lists[idx_list].list_pages
        local num_entries = #list.items

        --------------------------------------------------------------------
        -- Determine width depending on list expanded/collapsed
        --------------------------------------------------------------------
        local width
        local height
        if list_expanded then
            width = Constants.list_win[layout_name].width
            -- height shall be dynamic depending on cards number

            -- local list_height = math.min(cfg.height, 2 + sum_cards_height) -- WARN: Can't put 1 here because "Not enough room" errors
        else
            width = Constants.list_win_close[layout_name].width
            -- height shall be dynamic depending in title length
        end

        --------------------------------------------------------------------
        -- Winbar depends on expanded/collapsed
        --------------------------------------------------------------------
        if list_expanded then
            local fmt = " %s %%= %d "
            list_win.opts.wo.winbar = fmt:format(list.title, #list.items)

            vim.api.nvim_buf_set_lines(list_win.buf, 0, -1, false, {})
            list_win.opts.height = Constants.list_win[layout_name].height

            if num_entry_pages == 0 then
                list_win.opts.footer = {
                    { "<S-j> ↑ ", "Comment" },
                    { "-", "Normal" },
                    { " ↓ <S-k>", "Comment" },
                }
            else
                list_win.opts.footer = {
                    { "<S-j> ↑ ", "Comment" },
                    { list_entry_page .. "/" .. num_entry_pages, "Normal" },
                    -- { "page " .. focused_page .. "/" .. num_entry_pages, "Normal" },
                    { " ↓ <S-k>", "Comment" },
                }
            end
        else
            local fmt = " %d "
            list_win.opts.wo.winbar = fmt:format(#list.items)

            local function stringToCharList(str)
                local chars = {}
                for idx = 1, #str do
                    table.insert(chars, str:sub(idx, idx))
                end
                return chars
            end

            local char_list_title = stringToCharList(list.title)
            vim.api.nvim_buf_set_lines(list_win.buf, -1, -1, false, char_list_title)

            -- height shall be the char_list length + padding + border
            height = #char_list_title + 1 + 1 -- 1 = padding, 1 = border
            list_win.opts.height = height

            -- Resets footer
            list_win.opts.footer = ""
        end

        list_win.opts.col = col_offset -- put the list_win at the offset
        list_win.opts.width = width -- with the compute width (depending on expanded/collapsed status)
        col_offset = col_offset + width + 1 + 1 -- move to next column 1=padding, 1=border

        --------------------------------------------------------------------
        -- COLLAPSED LIST: entries's window won't be rendered so do nothing
        --------------------------------------------------------------------
        if not list_expanded then
            goto continue_lists
        end

        --------------------------------------------------------------------
        -- EXPANDED LIST: compute entries's window position as they will be rendered
        --------------------------------------------------------------------
        local base_row = Constants.list_win[layout_name].row + 1 + 1 -- starting row for displaying entry windows

        local list_state = viewState.pages[focused_page].lists[idx_list]
        local list_pages = list_state.list_pages -- the ranges of entries per page

        -- For each page, compute row offsets independently
        for page_num, page_range in ipairs(list_pages) do
            local row_offset = base_row

            local first = page_range.start
            local last = page_range.stop

            for card_index = first, last do
                local card = list.items[card_index]
                if card then
                    local card_win = viewWindows.pages[focused_page].lists[idx_list].items[card_index]

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

        ::continue_lists::
    end
end

function ViewLayoutTrait:render(debug)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState

    if debug then
        dprint("viewState:", viewState)
    end

    self:compute_windows_rendering()

    local focused_page = viewState.focused.page

    for list_idx, list_win_obj in ipairs(self.viewWindows.pages[focused_page].lists) do
        local list_state = viewState.pages[focused_page].lists[list_idx]

        --------------------------------------------------------------------
        -- If the entire list is hidden (list_state.show), hide everything
        --------------------------------------------------------------------
        if not list_state.show then
            list_win_obj.win:hide()
            for _, entry_win in ipairs(list_win_obj.items or {}) do
                entry_win:hide()
            end
            goto continue_lists
        end

        --------------------------------------------------------------------
        -- Show the list window itself
        --------------------------------------------------------------------
        list_win_obj.win:show()

        --------------------------------------------------------------------
        -- If the list is COLLAPSED: hide all entry windows
        --------------------------------------------------------------------
        if not list_state.expanded then
            for _, entry_win in ipairs(list_win_obj.items or {}) do
                entry_win:hide()
            end
            goto continue_lists
        end

        --------------------------------------------------------------------
        -- LIST IS EXPANDED → Show only entries of current page
        --------------------------------------------------------------------
        local current_page = list_state.current_page
        local page_info = list_state.list_pages[current_page]
        if not page_info then
            -- no entries to render
            goto continue_lists
        end
        local first_idx = page_info.start
        local last_idx = page_info.stop

        for item_idx, entry_win in ipairs(list_win_obj.items or {}) do
            if entry_win then
                if item_idx >= first_idx and item_idx <= last_idx then
                    entry_win:show()
                else
                    entry_win:hide()
                end
            end
        end

        ::continue_lists::
    end
end

-- these are the same
-- function ViewLayoutTrait:hide()
-- ViewLayoutTrait.hide = function(self)
function ViewLayoutTrait:hide(viewWindows, viewState)
    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:hide()
            end
        end
        list.win:hide()
    end
end

function ViewLayoutTrait:close(viewWindows, viewState)
    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:close()
            end
        end
        list.win:close()
    end
end

return ViewLayoutTrait
