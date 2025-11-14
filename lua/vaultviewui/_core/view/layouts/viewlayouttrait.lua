local ViewLayoutTrait = {}

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")
local Keymaps = require("vaultviewui.keymaps")

function ViewLayoutTrait:debug()
    dprint("ViewLayoutTrait debug:")
    dprint(self.__name)
    dprint(self.vaultWindows)
    dprint(self.viewState)
end

-- function ViewLayoutTrait:compute_layout(viewData, viewWindows, viewState)
--     dprint("Computing layout for ViewLayoutTrait:", self.__name)
--     -- Default implementation does nothing
-- end

function ViewLayoutTrait:render(viewData, viewWindows, viewState)
    dprint("Rendering ViewLayoutTrait:", self.__name)
    dprint("ViewWindows:", viewWindows)
    dprint("ViewState:", viewState)
    local focused_page_idx, focused_list_idx, focused_item_idx =
        viewState.focused.page, viewState.focused.list, viewState.focused.item
    self:compute_layout(viewData, viewWindows, viewState)
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:show()
            end
        end
        list.win:show()
    end
end

-- these are the same
-- function ViewLayoutTrait:hide()
-- ViewLayoutTrait.hide = function(self)
function ViewLayoutTrait:hide(viewWindows, viewState)
    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:hide()
            end
        end
        list.win:hide()
    end
end

function ViewLayoutTrait:close(viewWindows, viewState)
    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:close()
            end
        end
        list.win:close()
    end
end


return ViewLayoutTrait
