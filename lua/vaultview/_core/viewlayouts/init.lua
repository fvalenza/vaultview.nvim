local TraitUtils = require("vaultview._core.utils.traitutils")

local ViewLayoutTrait = require("vaultview._core.viewlayouts.viewlayouttrait")

local layouts = {
    carousel = require("vaultview._core.viewlayouts.viewlayoutcarousel"),
    columns  = require("vaultview._core.viewlayouts.viewlayoutcolumns"),
}

for _, layout in pairs(layouts) do
    TraitUtils.apply(layout, ViewLayoutTrait)
end


return layouts
