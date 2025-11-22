--- # ViewLayoutCarousel
---
--- Carousel-style layout engine used by VaultView to render pages/lists of a board.
---
--- This layout: ensures that:
--- - Tries to display all lists of a page horizontally.
--- - If space is insufficient, collapsed some list (leftmost and rightmost) to display a number of list centrally  (visibility_window is the term for the expanded ones)
--- - The visible window of lists (`lists_visibility`) is computed automatically and move depending on which list the cursor focuses on
---
--- The layout is computed only **once** at construction time.
--- Afterwards, the main View handles expand/collapse interactions through visibility_window
---
---@class ViewLayoutCarousel
---@field __name string               Name of the layout class
---@field viewData table              Data model: pages → lists → items
---@field viewWindows table           Window objects for pages/lists/items
---@field viewState table             UI state: expanded flags, pagination, focus
---
local ViewLayoutCarousel = {}
ViewLayoutCarousel.__index = ViewLayoutCarousel

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")


--- Get layout class name.
---@return string
function ViewLayoutCarousel.name()
    return "ViewLayoutCarousel"
end


---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

--- Create a new Carousel layout instance.
---
--- @param viewData table      Data model: structure of pages, lists, entries. Only for the board associated to this View/ViewLayout
--- @param viewWindows table   Window objects for all pages/lists/items.
--- @param viewState table     UI navigation + expansion/collapse state.
---
--- @return ViewLayoutCarousel The constructed layout instance
function ViewLayoutCarousel.new(viewData, viewWindows, viewState)
    local self = setmetatable({}, ViewLayoutCarousel)
    self.__name = "ViewLayoutCarousel"
    self.viewData = viewData
    self.viewWindows = viewWindows
    self.viewState = viewState

    -- Calculate initial state of lists
    self:compute_layout()

    return self
end


---------------------------------------------------------------------
-- Initial layout computation
---------------------------------------------------------------------

--- Compute the **initial layout** of the carousel.
---
--- This performs:
--- - list visibility computation for the whole page
--- - entry visibility window computation (placeholder for future)
--- - sets focused list to the center of the visible lists
---
--- This is called **once** in the constructor.
function ViewLayoutCarousel:compute_layout()
    for p_idx, _ in ipairs(self.viewData.pages) do
        -- Determine which lists are expanded/collapsed
        self:compute_lists_in_page_visibility_window(p_idx)

        -- Placeholder for future entry visibility logic
        for l_idx, _ in ipairs(self.viewData.pages[p_idx].lists) do
            self:compute_entries_in_list_visibility_window(p_idx, l_idx)
        end
    end

    -- Set focused list to computed center list
    self.viewState.focused.list =
        self.viewState.pages[self.viewState.focused.page].center_list_index
end


---------------------------------------------------------------------
-- Precompute spacing constants for this layout
---------------------------------------------------------------------

-- Expanded list: width + 2 (padding + border)
local space_taken_expanded =
    Constants.list_win[ViewLayoutCarousel.name()].width + 2

-- Collapsed list: width + 2 (padding + border)
local space_taken_collapsed =
    Constants.list_win_close[ViewLayoutCarousel.name()].width + 2


---------------------------------------------------------------------
-- Compute list visibility window
---------------------------------------------------------------------

--- Compute which lists are **visible and expanded** for a given page.
---
--- Algorithm:
--- 1. All lists start as expanded.
--- 2. If total required width exceeds available space:
---      - collapse lists from **left to right**
---      - then from **right to left**
---      - until they fit
--- 3. Compute:
---      - `lists_visibility.first`
---      - `lists_visibility.last`
---      - `lists_visibility.length`
---      - `center_list_index` (middle list)
---
--- @param page_idx integer  Page index
function ViewLayoutCarousel:compute_lists_in_page_visibility_window(page_idx)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState

    local available_width = vim.o.columns
    local num_lists = #viewData.pages[page_idx].lists

    -- Maximum width if all lists are expanded
    local total_space_taken_all_expanded = num_lists * space_taken_expanded
    local layout_space_taken = total_space_taken_all_expanded

    local visibility_window_length = num_lists

    local left_idx = 1
    local right_idx = num_lists

    ----------------------------------------------------------------------
    -- Collapse lists until the layout fits inside the current viewport
    ----------------------------------------------------------------------
    while layout_space_taken > available_width and left_idx <= right_idx do
        -- Collapse leftmost list first
        if viewState.pages[page_idx].lists[left_idx].expanded then
            visibility_window_length = visibility_window_length - 1
            self:collapse_list(page_idx, left_idx)
        end

        left_idx = left_idx + 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)

        if layout_space_taken <= available_width then
            break
        end

        -- Collapse rightmost list
        if viewState.pages[page_idx].lists[right_idx].expanded then
            visibility_window_length = visibility_window_length - 1
            self:collapse_list(page_idx, right_idx)
        end

        right_idx = right_idx - 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
    end

    ----------------------------------------------------------------------
    -- Store collapse boundaries
    ----------------------------------------------------------------------
    self.last_left_collapsed = left_idx - 1
    self.last_right_collapsed = right_idx + 1
    self.layout_space_taken = layout_space_taken

    ----------------------------------------------------------------------
    -- Visibility window
    ----------------------------------------------------------------------
    local visibility_window_left = math.max(1, self.last_left_collapsed + 1) -- Ensure we don't go below 1
    local visibility_window_right = math.min(num_lists, self.last_right_collapsed - 1) -- Ensure we don't go above the number of lists

    viewState.pages[page_idx].lists_visibility.first = visibility_window_left
    viewState.pages[page_idx].lists_visibility.last = visibility_window_right
    viewState.pages[page_idx].lists_visibility.length = visibility_window_length

    -- Focus the center-most visible list
    viewState.pages[page_idx].center_list_index =
        math.ceil((self.last_left_collapsed + self.last_right_collapsed) / 2)
end


---------------------------------------------------------------------
-- Entry pagination / visibility
---------------------------------------------------------------------

--- Compute visible entries in a list (future feature).
---
---
--- @param p_idx integer Page index
--- @param l_idx integer List index
function ViewLayoutCarousel:compute_entries_in_list_visibility_window(p_idx, l_idx)
    -- TODO (roadmap):
    --   When "Display entries in list as stack" is implemented,
    --   this will handle entry pagination + visibility window.
end


return ViewLayoutCarousel
