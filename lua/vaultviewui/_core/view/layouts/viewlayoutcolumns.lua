local ViewLayoutColumns = {}
ViewLayoutColumns.__index = ViewLayoutColumns

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")


function ViewLayoutColumns.name()
    return "ViewLayoutColumns"
end

function ViewLayoutColumns.new(vaultWindows, viewState)
    local self = setmetatable({}, ViewLayoutColumns)
    self.__name = "ViewLayoutColumns"
    self.vaultWindows = vaultWindows
    self.viewState = viewState

    return self
end

function ViewLayoutColumns:compute_layout(viewData, viewWindows, viewState)
    -- Implement column layout computation logic here
    -- For example, arrange lists side by side in columns
    local col_offset = Constants.list_win.ViewLayoutColumns.col -- offset for which column to put the next list window
    local focused_page = viewState.focused.page

    for idx_list, list in ipairs(viewData.pages[focused_page].lists or {}) do
        local list_win = viewWindows.pages[focused_page].lists[idx_list].win

        list_win.opts.col = col_offset -- put the win at the offset
        local width = Constants.list_win.ViewLayoutColumns.width
        list_win.opts.width = width
        col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border

        local list_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
        list_win.opts.wo.winbar = list_winbar_title_fmt:format(list.title, #list.items)

        local row_offset = Constants.list_win.ViewLayoutColumns.row + 1 + 1 -- start at the row of the list + 1

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


return ViewLayoutColumns
