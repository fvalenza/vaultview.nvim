local ViewLayoutCarousel = {}
ViewLayoutCarousel.__index = ViewLayoutCarousel

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")


function ViewLayoutCarousel.name()
    return "ViewLayoutCarousel"
end

function ViewLayoutCarousel.new(vaultWindows, viewState)
    local self = setmetatable({}, ViewLayoutCarousel)
    self.__name = "ViewLayoutCarousel"
    self.vaultWindows = vaultWindows
    self.viewState = viewState

    return self
end





return ViewLayoutCarousel
