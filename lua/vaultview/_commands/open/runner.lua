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

    vv:render()
end

function M.run_close_board()
    _LOGGER:debug("Closing open board")

    -- vim.notify( "closing vaultview", vim.log.levels.INFO)

    if M.context.vv then
        M.context.vv:close()
    end
end


function M.render()
    _LOGGER:debug("Redrawing open board")

    if M.context.vv then
        M.context.vv:render()
    end
end

function M.refresh()
    -- DISGUSTING HACK -> close and open again to force refresh of data
    _LOGGER:debug("Refresh board")

    if M.context.vv then
        M.run_close_board()
        M.run_open_board()
        M:render()
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
        M.context.vv:go_to_page(-1)
    end
end

function M.run_go_to_next_page()
    _LOGGER:debug("Go to next page")

    if M.context.vv then
        M.context.vv:go_to_page(1)
    end
end


-- Focus the card with the given title.
-- TODO: rename function
function M.run_focus(title)
    _LOGGER:debug("Get focus back on viewlayout")

    if M.context.vv then
        M.context.vv:focus(title)
    end
end


-- Focus back to viewlayout (at the position it is pointing to)
function M.run_focus_back()
    _LOGGER:debug("Get focus back on viewlayout")

    if M.context.vv then
        M.context.vv:focus_back()
    end
end

function M.run_pick_list()
    _LOGGER:debug("Picker")

    if M.context.vv then
        M.context.vv:pick_list()
    end
end

function M.run_pick_card()
    _LOGGER:debug("Picker")

    if M.context.vv then
        M.context.vv:pick_card()
    end
end

function M.run_pick_content()
    _LOGGER:debug("Picker")

    if M.context.vv then
        M.context.vv:pick_content()
    end
end




return M
