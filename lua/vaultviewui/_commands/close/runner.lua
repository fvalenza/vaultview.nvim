--- The main file that implements `hello-world say` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("vaultview._commands.close.runner")

local M = {}

function M.run_close()
    require("vaultviewui").close()
end


return M
