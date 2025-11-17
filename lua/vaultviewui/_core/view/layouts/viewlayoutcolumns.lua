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
    self.viewState.center_list_index = math.ceil(#self.viewWindows.pages[self.viewState.focused.page].lists / 2)
    self:compute_layout()

    return self
end

function ViewLayoutColumns:compute_layout()
    for p_idx, _ in ipairs(self.viewData.pages) do
        self:compute_visibility_window(p_idx)
    end
end

function ViewLayoutColumns:compute_visibility_window(page_idx)
    local viewData = self.viewData
    local viewWindows = self.viewWindows
    local viewState = self.viewState

    self:set_lists_visibility_window(page_idx, 1, #viewState.pages[viewState.focused.page].lists)
end

return ViewLayoutColumns
