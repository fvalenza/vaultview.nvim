--- The main file that implements `hello-world say` outside of COMMAND mode.

local configuration = require("vaultview._core.configuration")
local logging = require("mega.logging")
local vaultview = require("vaultview._core.vaultview")

local _LOGGER = logging.get_logger("vaultview._commands.open.runner")

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
function M.run_open_board()
    _LOGGER:debug("Running open board")


    local data = configuration.resolve_data(vim.g.vaultview_configuration)


	-- print("Items in this list: " .. vim.inspect(data)) -- debug, and to see it everything works

    -- vim.notify( "opening vaultview", vim.log.levels.INFO)

    local vv = vaultview.new(data)

    vv:open()
end

return M
