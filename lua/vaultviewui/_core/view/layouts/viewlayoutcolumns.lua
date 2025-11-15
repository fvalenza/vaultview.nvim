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
    -- self:compute_layout()

    return self
end

function ViewLayoutColumns:compute_layout()
    self:compute_layout_all_expanded(self.__name)
end

return ViewLayoutColumns
