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

-- compute the initial layout of the view.
-- Shall be called once in constructor.
-- After that, expand/collapse_list and expand/collapse_entry shall be called to update the layout
function ViewLayoutCarousel:compute_layout()
    for p_idx, _ in ipairs(self.viewData.pages) do
        self:compute_lists_in_page_visibility_window(p_idx)
        for l_idx, _ in ipairs(self.viewData.pages[p_idx].lists) do
            self:compute_entries_in_list_visibility_window(p_idx, l_idx)
        end
    end
    self.viewState.focused.list = self.viewState.pages[self.viewState.focused.page].center_list_index
end

local space_taken_expanded = Constants.list_win[ViewLayoutCarousel.name()].width + 2 -- 1 for padding and 1 for borders
local space_taken_collapsed = Constants.list_win_close[ViewLayoutCarousel.name()].width + 2 -- 1 for pqdding qnd 1 for borders


function ViewLayoutCarousel:compute_lists_in_page_visibility_window(page_idx)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState

    local available_width = vim.o.columns
    local total_space_taken_all_expanded = #viewData.pages[page_idx].lists * space_taken_expanded
    local layout_space_taken = total_space_taken_all_expanded

    local visibility_window_length = #viewData.pages[page_idx].lists

    local left_idx = 1
    local right_idx = #viewData.pages[page_idx].lists
    while layout_space_taken > available_width and left_idx <= right_idx do
        -- Collapse left side first to gain room
        if viewState.pages[page_idx].lists[left_idx].expanded then
            visibility_window_length = visibility_window_length - 1
            self:collapse_list(page_idx, left_idx)
        end
        left_idx = left_idx + 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
        if layout_space_taken <= available_width then
            break
        end

        -- Collapse right side
        if viewState.pages[page_idx].lists[right_idx].expanded then
            visibility_window_length = visibility_window_length - 1
            self:collapse_list(page_idx, right_idx)
        end
        right_idx = right_idx - 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
    end


    self.last_left_collapsed = left_idx - 1
    self.last_right_collapsed = right_idx + 1
    self.layout_space_taken = layout_space_taken

    local visibility_window_left = math.max(1, self.last_left_collapsed + 1) -- Ensure we don't go below 1
    local visibility_window_right = math.min(#viewData.pages[page_idx].lists, self.last_right_collapsed - 1) -- Ensure we don't go above the number of lists
    viewState.pages[page_idx].lists_visibility.first = visibility_window_left
    viewState.pages[page_idx].lists_visibility.last = visibility_window_right
    viewState.pages[page_idx].lists_visibility.length = visibility_window_length
    viewState.pages[page_idx].center_list_index = math.ceil((self.last_left_collapsed + self.last_right_collapsed) / 2) -- Set the focus index to the middle of the collapsed lists
end


function ViewLayoutCarousel:compute_entries_in_list_visibility_window(p_idx, l_idx)
    --TODO
end


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



return ViewLayoutCarousel
