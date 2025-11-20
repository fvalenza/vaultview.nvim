--- All `vaultviewui` command definitions.

_G.dprint = require("vaultviewui._core.utils.debug")

local cmdparse = require("mega.cmdparse")

local _PREFIX = "Vaultviewui"

---@type mega.cmdparse.ParserCreator
local _SUBCOMMANDS = function()
    local open = require("vaultviewui._commands.open.parser")
    local close = require("vaultviewui._commands.close.parser")
    local reload = require("vaultviewui._commands.reload.parser")

    local parser = cmdparse.ParameterParser.new({ name = _PREFIX, help = "The root of all commands." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(open.make_parser())
    subparsers:add_parser(close.make_parser())
    subparsers:add_parser(reload.make_parser())

    return parser
end

cmdparse.create_user_command(_SUBCOMMANDS, _PREFIX)

vim.keymap.set("n", "<Plug>(Vaultviewui)", function()

    require("vaultviewui").toggle()


end, { desc = "Open your vaultviewui" })
