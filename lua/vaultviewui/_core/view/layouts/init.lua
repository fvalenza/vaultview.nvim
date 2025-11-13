local TraitUtils = require("vaultviewui._core.utils.traitutils")

local ViewLayoutTrait = require("vaultviewui._core.view.layouts.viewlayouttrait")

local layouts = {
    carousel = require("vaultviewui._core.view.layouts.viewlayoutcarousel"),
    columns  = require("vaultviewui._core.view.layouts.viewlayoutcolumns"),
}

for _, layout in pairs(layouts) do
    TraitUtils.apply(layout, ViewLayoutTrait)
end


return layouts
