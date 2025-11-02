
local parsers = {
    daily = require("vaultview._core.parsers.daily_parser"),
    moc = require("vaultview._core.parsers.moc_parser"),
}

--- Returns the parser entry point (parseBoard function) based on input type.
-- @param parserField (string|function) Name of parser or a custom function.
-- @return function The parseBoard function to use.
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

-- return parsers
return getParserEntryPoint
