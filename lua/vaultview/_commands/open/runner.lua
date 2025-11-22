--- The main file that implements `hello-world say` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("vaultview._commands.open.runner")

local M = {}

function M.run_open()
    require("vaultview").open()
end


return M
