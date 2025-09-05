--- The main file that implements `hello-world say` outside of COMMAND mode.

local constant = require("vaultview._commands.hello_world.say.constant")
local logging = require("mega.logging")

local _LOGGER = logging.get_logger("vaultview._commands.hello_world.say.runner")

local M = {}

--- Print `phrase` according to the other options.
---
---@param phrase string[]
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_open_board(name)
    _LOGGER:debug("Running open board")



    vim.notify( "opening " .. name, vim.log.levels.INFO)
end

return M
