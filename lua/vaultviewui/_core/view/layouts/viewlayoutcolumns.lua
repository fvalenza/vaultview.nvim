local ViewLayoutColumns = {}
ViewLayoutColumns.__index = ViewLayoutColumns

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")

function ViewLayoutColumns.name()
    return "ViewLayoutColumns"
end

function ViewLayoutColumns.new(viewData, viewWindows, viewState)
    local self = setmetatable({}, ViewLayoutColumns)
    self.__name = "ViewLayoutColumns"
    self.viewData = viewData
    self.viewWindows = viewWindows
    self.viewState = viewState
    self:compute_layout()

    return self
end

function ViewLayoutColumns:compute_layout()
    for p_idx, _ in ipairs(self.viewData.pages) do
        self:compute_lists_in_page_visibility_window(p_idx)
        for l_idx, _ in ipairs(self.viewData.pages[p_idx].lists) do
            self:compute_entries_in_list_visibility_window(p_idx, l_idx)
        end
    end
    self.viewState.focused.list = self.viewState.pages[self.viewState.focused.page].center_list_index
end

function ViewLayoutColumns:compute_lists_in_page_visibility_window(page_idx)
    local viewState = self.viewState

    self:set_lists_visibility_window(page_idx, 1, #viewState.pages[viewState.focused.page].lists)
    self.viewState.pages[page_idx].center_list_index = math.ceil(#self.viewWindows.pages[page_idx].lists / 2)
end

function ViewLayoutColumns:compute_entries_in_list_visibility_window(page_idx, list_idx)
    --TODO(roadmap) This function will be necessary when "Display entries in list as stack" will be available.
    --For ViewLayoutColumns, the visibility of entries in list will be "all" (start = 1, end = num_entries, length = num_entries ; perhaps do not forget to take into account pagination of entries)
end

return ViewLayoutColumns
