--- ViewLayoutColumns
---
--- A layout strategy that displays all lists of a page as *full columns*.
--- Unlike the carousel layout, no collapsing is performed: all lists remain visible.
--- This layout is simpler and primarily determines visibility windows (all lists) and 
--- establishes initial focus.
---
--- @class ViewLayoutColumns
---@field __name string               Name of the layout class
---@field viewData table              Data model: pages → lists → items
---@field viewWindows table           Window objects for pages/lists/items
---@field viewState table             UI state: expanded flags, pagination, focus
local ViewLayoutColumns = {}
ViewLayoutColumns.__index = ViewLayoutColumns


--- Get layout class name
--- @return string name The layout name ("ViewLayoutColumns")
function ViewLayoutColumns.name()
    return "ViewLayoutColumns"
end

--- Create a new ViewLayoutColumns instance.
---
--- @param viewData table      Data model: structure of pages, lists, entries. Only for the board associated to this View/ViewLayout
--- @param viewWindows table   Window objects for all pages/lists/items.
--- @param viewState table     UI navigation + expansion/collapse state.
---
--- @return ViewLayoutColumns  The constructed layout instance
function ViewLayoutColumns.new(viewData, viewWindows, viewState)
    local self = setmetatable({}, ViewLayoutColumns)
    self.__name = "ViewLayoutColumns"
    self.viewData = viewData
    self.viewWindows = viewWindows
    self.viewState = viewState
    self:compute_layout()
    return self
end

---------------------------------------------------------------------
-- Initial layout computation
---------------------------------------------------------------------

--- Compute the **initial layout** of the carousel.
---
--- This performs:
--- - list visibility computation for the whole page (all lists visible in this layout)
--- - entry visibility window computation (placeholder for future)
--- - sets focused list to the center of the visible lists
---
--- This is called **once** in the constructor.
function ViewLayoutColumns:compute_layout()
    for p_idx, _ in ipairs(self.viewData.pages) do
        self:compute_lists_in_page_visibility_window(p_idx)
        for l_idx, _ in ipairs(self.viewData.pages[p_idx].lists) do
            self:compute_entries_in_list_visibility_window(p_idx, l_idx)
        end
    end

    -- Initial focused list is the center of the focused page.
    self.viewState.focused.list =
        self.viewState.pages[self.viewState.focused.page].center_list_index
end

---------------------------------------------------------------------
-- Compute list visibility window
---------------------------------------------------------------------

--- Compute which lists are **visible and expanded** for a given page.
---
--- Algorithm:
--- 1. All lists are visible
--- 2. The centered list is the middle column
---
--- @param page_idx integer The page index
function ViewLayoutColumns:compute_lists_in_page_visibility_window(page_idx)
    local viewState = self.viewState

    -- All lists are visible: 1 → total # of lists.
    self:set_lists_visibility_window(
        page_idx,
        1,
        #viewState.pages[viewState.focused.page].lists
    )

    -- Do not recompute expanded/collapsed state because already set at windows creation
    -- of the view and all lists remain unchanged in this layout

    -- The centered list is simply the middle column.
    self.viewState.pages[page_idx].center_list_index =
        math.ceil(#self.viewWindows.pages[page_idx].lists / 2)
end

---------------------------------------------------------------------
-- Entry pagination / visibility
---------------------------------------------------------------------

--- Compute visible entries in a list (future feature).
---
---
--- @param p_idx integer Page index
--- @param l_idx integer List index
function ViewLayoutColumns:compute_entries_in_list_visibility_window(page_idx, list_idx)
    -- TODO (roadmap):
    --   When "Display entries in list as stack" is implemented,
    --   this will handle entry pagination + visibility window.
end

return ViewLayoutColumns
