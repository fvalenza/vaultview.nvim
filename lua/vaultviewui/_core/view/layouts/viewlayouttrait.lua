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

-- TODO vim.notify this to force implementation in subclasses
-- function ViewLayoutTrait:compute_layout(viewData, viewWindows, viewState)
--     dprint("Computing layout for ViewLayoutTrait:", self.__name)
--     -- Default implementation does nothing
-- end

function ViewLayoutTrait:set_lists_visibility_window(page_idx, left_idx, right_idx)
    self.viewState.pages[page_idx].lists_visibility.first = left_idx
    self.viewState.pages[page_idx].lists_visibility.last = right_idx
    self.viewState.pages[page_idx].lists_visibility.length = right_idx - left_idx + 1
end

function ViewLayoutTrait:collapse_list( page_idx, list_idx)
    dprint("Collapsing list:", list_idx, "on page:", page_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = false

    -- put to false all the .show of the items
    for _, item in ipairs(self.viewState.pages[page_idx].lists[list_idx].items ) do
        item.show = false
    end

end

-- TODO1 as i modified expand_list and collapse_list to set the .show of the items, i may need to be just stupid as fuck in render()
-- + this function should then be in layouttrait i think !!!
-- TODO3 Update things if needed in layoutcolumns and be sure to factorize correctly
function ViewLayoutTrait:expand_list(page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = true

    -- put to false all the .show of the items
    for _, item in ipairs(self.viewState.pages[page_idx].lists[list_idx].items ) do
        item.show = true
    end
end

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
        end

        list_win.opts.col = col_offset -- put the list_win at the offset
        list_win.opts.width = width -- with the compute width (depending on expanded/collapsed status)
        col_offset = col_offset + width + 1 + 1 -- move to next column 1=padding, 1=border

        --------------------------------------------------------------------
        -- COLLAPSED LIST: hide all cards and continue to next list
        -- EXPANDED LIST: show all cards, we will compute their position later
        --------------------------------------------------------------------
        if not list_expanded then
            -- for card_index, _ in ipairs(list.items or {}) do
            --     viewState.pages[focused_page].lists[idx_list].items[card_index].show = false
            -- end
            goto continue_lists
        end
        --TODO if list is expanded, show all cards, but we will also compute their visibilitywindow/position

        --------------------------------------------------------------------
        -- EXPANDED LIST: compute card positions as usual
        --------------------------------------------------------------------
        local row_offset = Constants.list_win[layout_name].row + 1 + 1

        for card_index, card in ipairs(list.items or {}) do
            local card_win = viewWindows.pages[focused_page].lists[idx_list].items[card_index]

            card_win.opts.width = width
            card_win.opts.col = list_win.opts.col

            local height = card.expanded and card.win.viewlayout_height or Constants.card_win_close.height

            card_win.opts.row = row_offset
            card_win.opts.height = height

            row_offset = row_offset + height + 1 + 1
        end

        ::continue_lists::
    end
end

function ViewLayoutTrait:render(debug)
    -- dprint("Rendering ViewLayoutTrait:", self.__name)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState
    if debug then
        dprint("viewState:", viewState)
    end
    self:compute_windows_rendering() -- TODO probably that it should be called in new, and in functions (ju;p list for example) that may change it
    for list_idx, list in ipairs(self.viewWindows.pages[self.viewState.focused.page].lists) do
        if viewState.pages[viewState.focused.page].lists[list_idx].show then
            for item_idx, entry in ipairs(list.items or {}) do
                if entry then
                    if viewState.pages[viewState.focused.page].lists[list_idx].items[item_idx].show then
                        entry:show()
                    else
                        entry:hide()
                    end
                end
            end
            list.win:show()
        else
            for _, entry in ipairs(list.items or {}) do
                if entry then
                    entry:hide()
                end
            end
            list.win:hide()
        end
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
