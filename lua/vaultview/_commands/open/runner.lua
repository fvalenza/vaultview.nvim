--- The main file that implements `hello-world say` outside of COMMAND mode.

local configuration = require("vaultview._core.configuration")
local logging = require("mega.logging")
local vaultview = require("vaultview._core.vaultview")

local _LOGGER = logging.get_logger("vaultview._commands.open.runner")

local M = {}
M.context = {}

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
    M.context.vv = vv

    vv:open()
end

function M.run_close_board()
    _LOGGER:debug("Closing open board")

    -- vim.notify( "closing vaultview", vim.log.levels.INFO)

    if M.context.vv then
        M.context.vv:close()
    end
end

function M.run_go_to_board(index)
    _LOGGER:debug("Go to board: " .. tostring(index))

    if M.context.vv then
        M.context.vv:go_to_board(index)
    end
end

function M.run_go_to_next_board()
    _LOGGER:debug("Go to next board")

    if M.context.vv then
        M.context.vv:go_to_next_board()
    end
end

function M.run_go_to_previous_board()
    _LOGGER:debug("Go to previous board")

    if M.context.vv then
        M.context.vv:go_to_previous_board()
    end
end

function M.run_go_to_previous_page()
    _LOGGER:debug("Go to previous page")

    if M.context.vv then
        M.context.vv.board:go_to_page(-1)
    end
end

function M.run_go_to_next_page()
    _LOGGER:debug("Go to next page")

    if M.context.vv then
        M.context.vv.board:go_to_page(1)
    end
end




return M
