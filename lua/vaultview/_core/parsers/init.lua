local TraitUtils = require("vaultview._core.utils.traitutils")
local ParserTrait = require("vaultview._core.parsers.parsertrait")

local parsers = {
    daily = require("vaultview._core.parsers.daily_parser"),
    moc   = require("vaultview._core.parsers.moc_parser"),
}

for _, parser in pairs(parsers) do
    TraitUtils.apply(parser, ParserTrait)
end

local function getParserEntryPoint(parserField)
    if type(parserField) == "string" then
        local parserModule = parsers[parserField]
        if not parserModule then
            error("Unknown parser name: " .. parserField)
        end
        return parserModule.parseBoard
    elseif type(parserField) == "function" then
        return parserField
    else
        error("Invalid parser type: " .. type(parserField))
    end
end

-- Make the module callable like a function
local M = setmetatable({
    list = parsers,
    getEntryPoint = getParserEntryPoint,
}, {
    __call = function(_, parserField)
        return getParserEntryPoint(parserField)
    end
})

return M

