local TraitUtils = require("vaultviewui._core.utils.traitutils")

local ViewLayoutTrait = require("vaultviewui._core.viewlayouts.viewlayouttrait")

local layouts = {
    carousel = require("vaultviewui._core.viewlayouts.viewlayoutcarousel"),
    columns  = require("vaultviewui._core.viewlayouts.viewlayoutcolumns"),
}

for _, layout in pairs(layouts) do
    TraitUtils.apply(layout, ViewLayoutTrait)
end


return layouts
