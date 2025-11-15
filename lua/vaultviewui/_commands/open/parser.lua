--- The main parser for the `:Vaultview hello-world` command.

local cmdparse = require("mega.cmdparse")

local M = {}


--- Add the `--style` parameter onto `parser`.
---
---@param parser mega.cmdparse.ParameterParser The parent parser to add the parameter onto.
---
local function _add_style_parameter(parser)
    parser:add_parameter({
        names = { "--style", "-s" },
        choices = {
            constant.Keyword.style.lowercase,
            constant.Keyword.style.uppercase,
        },
        help = "lowercase makes WORD into word. uppercase does the reverse.",
    })
end

---@return mega.cmdparse.ParameterParser # The main parser for the `:Vaultview hello-world` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "open", help = "open" })


    parser:set_execute(function()
        local runner = require("vaultviewui._commands.open.runner")

        runner.run_open()
    end)


    return parser
end

return M
