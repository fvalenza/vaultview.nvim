local TraitUtils = require("vaultview._core.utils.traitutils")

local ViewLayoutTrait = require("vaultview._core.view.layouts.viewlayouttrait")

local layouts = {
    carousel = require("vaultview._core.view.layouts.viewlayoutcarousel"),
    columns  = require("vaultview._core.view.layouts.viewlayoutcolumns"),
}

for _, layout in pairs(layouts) do
    TraitUtils.apply(layout, ViewLayoutTrait)
end


return layouts
