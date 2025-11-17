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
        self:compute_visibility_window(p_idx)
    end
    self.viewState.focused.list = self.viewState.pages[self.viewState.focused.page].center_list_index
end

function ViewLayoutColumns:compute_visibility_window(page_idx)
    local viewState = self.viewState

    self:set_lists_visibility_window(page_idx, 1, #viewState.pages[viewState.focused.page].lists)
    self.viewState.pages[page_idx].center_list_index = math.ceil(#self.viewWindows.pages[page_idx].lists / 2)
    -- self.viewState[page_idx].center_list_index = math.ceil(#self.viewWindows.pages[page_idx].lists / 2)
    print( math.ceil(#self.viewWindows.pages[page_idx].lists / 2))
end

return ViewLayoutColumns
