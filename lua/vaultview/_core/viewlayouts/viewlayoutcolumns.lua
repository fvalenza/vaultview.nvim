local ViewLayoutColumns = {}
ViewLayoutColumns.__index = ViewLayoutColumns

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")


function ViewLayoutColumns.name()
    return "ViewLayoutColumns"
end

-- function ViewLayoutColumns.new(config)
function ViewLayoutColumns.new(page_data, context)
    local self = setmetatable({}, ViewLayoutColumns)
    self.__name = "ViewLayoutColumns"
    self.page_data = page_data
    self.context = context

    self.lists = self:createLayoutWindows(self.page_data)

    self.list_focus_index = math.ceil(#self.lists / 2)
    self.list_focus_index_center = math.ceil(#self.lists / 2)
    self.card_focus_index = 0
    return self
end



-- function ViewLayoutColumns.update(data)
-- end

function ViewLayoutColumns:render()

    local render_list = function(list, col_offset)
        local win = list.win

        local list_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
        win.opts.wo.winbar = list_winbar_title_fmt:format(list.title, #list.cards)

        win.opts.col = col_offset -- put the win at the offset
        local width = Constants.list_win.ViewLayoutColumns.width
        win.opts.width = width
        col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border

        -- Render the cards of the lists
        -- TODO iterate over the items of the list and render them
        -- put everything in function called render_cards(list) that shall also account for card expand/collapse (x for cards, X for lists)
        local row_offset = Constants.list_win.ViewLayoutColumns.row + 1 + 1 -- start at the row of the list + 1

        for c, card in ipairs(list.cards or {}) do
            -- shall set the position of the card window in the list column:
            -- col shall be the col of the current list window and row shall start at the row of the list +1 and increment for each card
            local card_win = card.win
            card_win.opts.width = width -- set the width of the card window
            card_win.opts.col = list.win.opts.col -- align with the list

            local height = card.expanded and card.win.viewlayout_height or Constants.card_win_close.height
            card_win.opts.row = row_offset -- put the card below the list title
            card_win.opts.height = height
            row_offset = row_offset + height + 1 + 1 -- increment the row offset for the next card

            -- FIXME: when focusing on previsouly collapsed list/card, errors "not enough room"
            -- local card_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
            -- card_win.opts.wo.winbar = card_winbar_title_fmt:format(card.title, c)

            card_win:show()
        end

        list.win:show()

        return col_offset
    end


    local col_offset = Constants.list_win.ViewLayoutColumns.col -- offset for which column to put the next list window
    for _, list in pairs(self.lists) do
            col_offset = render_list(list, col_offset)
    end

    self:focus()
end

-- TODO Adding same kind of movement as in neovim when you start to j/k from a last line character
-- When going to shorter lines, it should not move the focus to the next line but stay on the last character of the current line
-- When going to longer lines, it should stay at the index/number of the start
function ViewLayoutColumns:move_focus_horizontal(direction)
    local direction_index = 0
    if direction == "left" then
        direction_index = -1
    elseif direction == "right" then
        direction_index = 1
    else
        -- print("Invalid horizontal direction: " .. tostring(direction))
        return
    end


    local old_index = self.list_focus_index or 1
    local old_list = self.lists[old_index]
    local old_card_index = old_list.card_focus_index or 0 -- 0 = header, >0 = card number

    -- print("Moving focus " .. direction .. " from index: " .. old_index)

    local new_index = old_index + direction_index
    new_index = math.max(1, math.min(new_index, #self.lists))

    -- Update index
    self.list_focus_index = new_index
    local new_list = self.lists[new_index]

    -- If target list has fewer cards than old_card_index, reset to header
    if #new_list.cards == 0 then
        new_list.card_focus_index = 0
    elseif #new_list.cards < old_card_index then
        new_list.card_focus_index = #new_list.cards
    else
        new_list.card_focus_index = old_card_index
    end

    -- Focus correct window (list header or card)
    if new_list.card_focus_index == 0 then
        new_list.win:focus()
    else
        new_list.cards[new_list.card_focus_index].win:focus()
    end

end

function ViewLayoutColumns:move_focus_idx(list_idx, card_idx)
    -- Determine if current list_focus_index is left or right of the new list_idx
    if list_idx < 1 or list_idx > #self.lists then
        -- print("Invalid list index: " .. tostring(list_idx))
        return
    end
    local direction = list_idx < self.list_focus_index and "left" or "right"
    while self.list_focus_index ~= list_idx do
        self:move_focus_horizontal(direction)
    end

    local direction_updown = card_idx < (self.lists[self.list_focus_index].card_focus_index or 0) and "up" or "down"
    while (self.lists[self.list_focus_index].card_focus_index or 0) ~= card_idx do
        self:move_focus_vertical(direction_updown)
    end

end



return ViewLayoutColumns
