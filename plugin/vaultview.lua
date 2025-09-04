--- All `vaultview` command definitions.

local cmdparse = require("mega.cmdparse")

local _PREFIX = "Vaultview"

---@type mega.cmdparse.ParserCreator
local _SUBCOMMANDS = function()
    local arbitrary_thing = require("vaultview._commands.arbitrary_thing.parser")
    local copy_logs = require("vaultview._commands.copy_logs.parser")
    local goodnight_moon = require("vaultview._commands.goodnight_moon.parser")
    local hello_world = require("vaultview._commands.hello_world.parser")

    local parser = cmdparse.ParameterParser.new({ name = _PREFIX, help = "The root of all commands." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(arbitrary_thing.make_parser())
    subparsers:add_parser(copy_logs.make_parser())
    subparsers:add_parser(goodnight_moon.make_parser())
    subparsers:add_parser(hello_world.make_parser())

    return parser
end

cmdparse.create_user_command(_SUBCOMMANDS, _PREFIX)

vim.keymap.set("n", "<Plug>(VaultviewSayHi)", function()
    local configuration = require("vaultview._core.configuration")
    local vaultview = require("plugin_template")

    configuration.initialize_data_if_needed()

    vaultview.run_hello_world_say_word("Hi!")
end, { desc = "Say hi to the user." })
