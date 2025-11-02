--- All `vaultview` command definitions.

_G.dprint = require("vaultview._core.utils.debug")

local cmdparse = require("mega.cmdparse")

local _PREFIX = "Vaultview"

---@type mega.cmdparse.ParserCreator
local _SUBCOMMANDS = function()
    local open = require("vaultview._commands.open.parser")
    local close = require("vaultview._commands.close.parser")

    local parser = cmdparse.ParameterParser.new({ name = _PREFIX, help = "The root of all commands." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(open.make_parser())
    subparsers:add_parser(close.make_parser())

    return parser
end

cmdparse.create_user_command(_SUBCOMMANDS, _PREFIX)

vim.keymap.set("n", "<Plug>(Vaultview)", function()
    local configuration = require("vaultview._core.configuration")
    local vaultview = require("vaultview")

    configuration.initialize_data_if_needed()

    vaultview.run_toggle_vaultview()
end, { desc = "Open your vaultview" })
