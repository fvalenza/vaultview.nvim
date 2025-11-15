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

function ViewLayoutTrait:compute_layout_all_expanded(layout_name)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState
    -- Implement column layout computation logic here
    -- For example, arrange lists side by side in columns
    local col_offset = Constants.list_win[layout_name].col -- offset for which column to put the next list window
    local focused_page = viewState.focused.page

    for idx_list, list in ipairs(viewData.pages[focused_page].lists or {}) do
        local list_win = viewWindows.pages[focused_page].lists[idx_list].win

        list_win.opts.col = col_offset -- put the win at the offset
        local width = Constants.list_win[layout_name].width
        list_win.opts.width = width
        col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border

        local list_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
        list_win.opts.wo.winbar = list_winbar_title_fmt:format(list.title, #list.items)

        local row_offset = Constants.list_win[layout_name].row + 1 + 1 -- start at the row of the list + 1

        for card_index, card in ipairs(list.items or {}) do
            -- shall set the position of the card window in the list column:
            -- col shall be the col of the current list window and row shall start at the row of the list +1 and increment for each card
            local card_win = viewWindows.pages[focused_page].lists[idx_list].items[card_index]

            card_win.opts.width = width -- set the width of the card window
            card_win.opts.col = list_win.opts.col -- align with the list

            local height = card.expanded and card.win.viewlayout_height or Constants.card_win_close.height
            card_win.opts.row = row_offset -- put the card below the list title
            card_win.opts.height = height
            row_offset = row_offset + height + 1 + 1 -- increment the row offset for the next card
        end
    end
end

function ViewLayoutTrait:render(viewData, viewWindows, viewState)
    -- dprint("Rendering ViewLayoutTrait:", self.__name)
    self:compute_layout() -- TODO probably that it should be called in new, and in functions (ju;p list for example) that may change it
    for _, list in ipairs(self.viewWindows.pages[self.viewState.focused.page].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:show()
            end
        end
        list.win:show()
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
