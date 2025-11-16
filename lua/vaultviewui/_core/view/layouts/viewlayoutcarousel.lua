local ViewLayoutCarousel = {}
ViewLayoutCarousel.__index = ViewLayoutCarousel

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")


function ViewLayoutCarousel.name()
    return "ViewLayoutCarousel"
end

function ViewLayoutCarousel.new(viewData, viewWindows, viewState)
    local self = setmetatable({}, ViewLayoutCarousel)
    self.__name = "ViewLayoutCarousel"
    self.viewData = viewData
    self.viewWindows = viewWindows
    self.viewState = viewState
    self:compute_layout()

    return self
end

function ViewLayoutCarousel:compute_layout()
    self:compute_visibility_window()
end

local space_taken_expanded = Constants.list_win[ViewLayoutCarousel.name()].width + 2 -- 1 for padding and 1 for borders
local space_taken_collapsed = Constants.list_win_close[ViewLayoutCarousel.name()].width + 2 -- 1 for pqdding qnd 1 for borders

function ViewLayoutCarousel:collapse_list( page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = false

end

function ViewLayoutCarousel:expand_list(page_idx, list_idx)
    self.viewState.pages[page_idx].lists[list_idx].expanded = true
end

function ViewLayoutCarousel:compute_visibility_window()
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState

    local available_width = vim.o.columns
    local total_space_taken_all_expanded = #viewData.pages[viewState.focused.page].lists * space_taken_expanded
    local layout_space_taken = total_space_taken_all_expanded

    local left_idx = 1
    local right_idx = #viewData.pages[viewState.focused.page].lists
    while layout_space_taken > available_width and left_idx <= right_idx do
        -- Collapse left side first to gain room
        if viewState.pages[viewState.focused.page].lists[left_idx].expanded then
            self:collapse_list(viewState.focused.page, left_idx)
        end
        left_idx = left_idx + 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
        if layout_space_taken <= available_width then
            break
        end

        -- Collapse right side
        if viewState.pages[viewState.focused.page].lists[right_idx].expanded then
            self:collapse_list(viewState.focused.page, right_idx)
        end
        right_idx = right_idx - 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
    end


    self.last_left_collapsed = left_idx - 1
    self.last_right_collapsed = right_idx + 1
    self.layout_space_taken = layout_space_taken

    self.visibility_window_left = math.max(1, self.last_left_collapsed + 1) -- Ensure we don't go below 1
    self.visibility_window_right = math.min(#viewData.pages[viewState.focused.page].lists, self.last_right_collapsed - 1) -- Ensure we don't go above the number of lists
    viewState.center_list_index = math.ceil((self.last_left_collapsed + self.last_right_collapsed) / 2) -- Set the focus index to the middle of the collapsed lists
    viewState.focused.list = viewState.center_list_index
end


-- function ViewLayoutCarousel:render()
--     local function hide_all_entry_cards(list)
--         for _, card in ipairs(list.cards or {}) do
--             local card_win = card.win
--             card_win:hide() -- hide the card window
--         end
--     end
--
--     local render_expanded_list = function(list, col_offset)
--         local win = list.win
--
--         local list_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
--         win.opts.wo.winbar = list_winbar_title_fmt:format(list.title, #list.cards)
--
--         win.opts.col = col_offset -- put the win at the offset
--         -- determine the width based on expanded state
--         local width = list.expanded and Constants.list_win.width or Constants.list_win_close.width
--         win.opts.width = width
--         col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border
--
--         -- Render the cards of the lists
--         -- TODO iterate over the items of the list and render them
--         -- put everything in function called render_cards(list) that shall also account for card expand/collapse (x for cards, X for lists)
--         local row_offset = Constants.list_win.row + 1 + 1 -- start at the row of the list + 1
--
--         for c, card in ipairs(list.cards or {}) do
--             -- shall set the position of the card window in the list column:
--             -- col shall be the col of the current list window and row shall start at the row of the list +1 and increment for each card
--             local card_win = card.win
--             card_win.opts.width = width -- set the width of the card window
--             card_win.opts.col = list.win.opts.col -- align with the list
--             local height = card.expanded and card.win.viewlayout_height or Constants.card_win_close.height
--             card_win.opts.row = row_offset -- put the card below the list title
--             card_win.opts.height = height
--             row_offset = row_offset + height + 1 + 1 -- increment the row offset for the next card
--
--             -- FIXME: when focusing on previsouly collapsed list/card, errors "not enough room"
--             -- local card_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
--             -- card_win.opts.wo.winbar = card_winbar_title_fmt:format(card.title, c)
--
--             card_win:show()
--         end
--
--         list.win:show()
--
--         return col_offset
--     end
--
--     local render_collapsed_list = function(list, col_offset)
--         local win = list.win
--         local list_winbar_tile_fmt = " %d "
--         win.opts.wo.winbar = list_winbar_tile_fmt:format(#list.cards)
--
--         local function stringToCharList(str)
--             local chars = {}
--             for idx = 1, #str do
--                 table.insert(chars, str:sub(idx, idx))
--             end
--             return chars
--         end
--
--         local char_list_title = stringToCharList(list.title)
--         vim.api.nvim_buf_set_lines(win.buf, -1, -1, false, char_list_title)
--
--         win.opts.col = col_offset -- put the win at the offset
--         -- determine the width based on expanded state
--         local width = list.expanded and Constants.list_win.width or Constants.list_win_close.width
--         win.opts.width = width
--         col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border
--
--         -- height shall be the char_list length + padding + border
--         local height = #char_list_title + 1 + 1 -- 1 = padding, 1 = border
--         win.opts.height = height
--
--         list.win:show()
--
--         return col_offset
--     end
--
--     local col_offset = Constants.list_win.col -- offset for which column to put the next list window
--     for _, list in pairs(self.lists) do
--
--         -- Start by hiding all card windows. We will show them later if necessary (if list is expanded)
--         hide_all_entry_cards(list)
--
--         -- Clear the list buffer before setting new lines
--         vim.api.nvim_buf_set_lines(list.win.buf, 0, -1, false, {""})
--
--         if list.expanded then
--             col_offset = render_expanded_list(list, col_offset)
--         else
--             col_offset = render_collapsed_list(list, col_offset)
--
--         end
--
--     end
--
--     self:focus()
--     -- We are on a list, toggle the list expand/collapse
-- end

-- TODO Adding same kind of movement as in neovim when you start to j/k from a last line character
-- When going to shorter lines, it should not move the focus to the next line but stay on the last character of the current line
-- When going to longer lines, it should stay at the index/number of the start
-- function ViewLayoutCarousel:move_focus_horizontal(direction)
--     local direction_index = 0
--     if direction == "left" then
--         direction_index = -1
--     elseif direction == "right" then
--         direction_index = 1
--     else
--         -- print("Invalid horizontal direction: " .. tostring(direction))
--         return
--     end
--
--     -- print("Visibility window: " .. self.visibility_window_left .. " to " .. self.visibility_window_right)
--
--     local old_index = self.list_focus_index or 1
--     local old_list = self.lists[old_index]
--     local old_card_index = old_list.card_focus_index or 0 -- 0 = header, >0 = card number
--
--     -- print("Moving focus " .. direction .. " from index: " .. old_index)
--
--     local new_index = old_index + direction_index
--     new_index = math.max(1, math.min(new_index, #self.lists))
--
--     -- Expand/collapse logic for visibility
--     if new_index < self.visibility_window_left then
--         -- print("Expanding left list")
--         self.lists[new_index].expanded = true
--         self:collapse_list(self.visibility_window_right) -- Collapse the righttmost list
--         self.visibility_window_left = new_index
--         self.visibility_window_right = self.visibility_window_right - 1
--         self.last_left_collapsed = new_index
--         self.last_right_collapsed = self.last_right_collapsed - 1
--         self:render()
--     elseif new_index > self.visibility_window_right then
--         -- print("Expanding right list")
--         self.lists[new_index].expanded = true
--         self:collapse_list(self.visibility_window_left) -- Collapse the leftmost list
--         self.visibility_window_right = new_index
--         self.visibility_window_left = self.visibility_window_left + 1
--         self.last_right_collapsed = new_index
--         self.last_leftcollapsed = self.last_right_collapsed + 1
--         self:render()
--     end
--
--     -- Update index
--     self.list_focus_index = new_index
--     local new_list = self.lists[new_index]
--
--     -- If target list has fewer cards than old_card_index, reset to header
--     if #new_list.cards == 0 then
--         new_list.card_focus_index = 0
--     elseif #new_list.cards < old_card_index then
--         new_list.card_focus_index = #new_list.cards
--     else
--         new_list.card_focus_index = old_card_index
--     end
--
--     -- Focus correct window (list header or card)
--     if new_list.card_focus_index == 0 then
--         new_list.win:focus()
--     else
--         new_list.cards[new_list.card_focus_index].win:focus()
--     end
--
--     -- print(
--     --     "Moving focus from " .. old_index .. " to " .. new_index .. " (card index: " .. new_list.card_focus_index .. ")"
--     -- )
-- end

function ViewLayoutCarousel:move_focus_idx(list_idx, card_idx)
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

    -- if list_idx < 1 or list_idx > #self.lists then
    --     print("Invalid list index: " .. tostring(list_idx))
    --     return
    -- end
    --
    -- local target_list = self.lists[list_idx]
    -- if card_idx < 0 or card_idx > #target_list.cards then
    --     -- print("Invalid card index: " .. tostring(card_idx))
    --     return
    -- end
    --
    -- self.list_focus_index = list_idx
    -- target_list.card_focus_index = card_idx
    --
    -- -- Adjust visibility window if necessary
    -- if list_idx < self.visibility_window_left then
    --     self.visibility_window_left = list_idx
    --     self.visibility_window_right = math.min(self.visibility_window_right + 1, #self.lists)
    -- elseif list_idx > self.visibility_window_right then
    --     self.visibility_window_right = list_idx
    --     self.visibility_window_left = math.max(self.visibility_window_left - 1, 1)
    -- end
    --
    -- self:render()
end


-- FIXME: broken lately
-- function ViewLayoutCarousel:move_focus_center()
--     -- expand all lists and recompute inital layout
--     for _, list in ipairs(self.lists) do
--         list.expanded = true
--     end
--     self.last_left_collapsed, self.last_right_collapsed, self.layout_space_taken = self:compute_visibility_window()
--     self.visibility_window_left = math.max(1, self.last_left_collapsed + 1) -- Ensure we don't go below 1
--     self.visibility_window_right = math.min(#self.lists, self.last_right_collapsed - 1) -- Ensure we don't go above the number of lists
--     self.list_focus_index = math.ceil((self.last_left_collapsed + self.last_right_collapsed) / 2) -- Set the focus index to the middle of the collapsed lists
--     self:render()
-- end



return ViewLayoutCarousel
