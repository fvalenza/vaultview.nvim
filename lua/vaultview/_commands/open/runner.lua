--- The main file that implements `hello-world say` outside of COMMAND mode.

local configuration = require("vaultview._core.configuration")
local logging = require("mega.logging")
local vaultview = require("vaultview._core.vaultview")
local Snacks = require("snacks")

local _LOGGER = logging.get_logger("vaultview._commands.open.runner")

local M = {}
M.context = {}



function M.run_open()

    local plugin_configuration = configuration.resolve_data(vim.g.vaultview_configuration)

    if not M.context.vv then
        local vv = vaultview.new(plugin_configuration)
        M.context.vv = vv
        vv:render()
    else
        if not M.context.vv.isDisplayed then
            M.context.vv:render()
        end
    end

end


function M.run_toggle()
    _LOGGER:debug("Toggling open board")

    if not M.context.vv then
        M.run_open()
    else
        if not M.context.vv.isDisplayed then
            M.context.vv:render()
        else
            M.context.vv:hide()
        end
    end
end


--TODO destroy context
function M.run_close()
    if M.context.vv then
        M.context.vv:hide()
        M.context.vv = nil
    end
end

function M.run_hide()
    if M.context.vv then
        M.context.vv:hide()
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
        M.run_close()
        M.run_open()
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



function M.run_open_help()
    -- Get the absolute path to this Lua file
    local current_file = debug.getinfo(1, "S").source:sub(2)
    local help_path = vim.fn.fnamemodify(current_file, ":h:h:h") .. "/_doc/help_page.md"  -- go up and in _doc
    print("Help path is: " .. help_path)
    vim.notify("Opening help page..." .. help_path , vim.log.levels.INFO)


    -- Open help window with Snacks
    local help_win = Snacks.win({
        file = help_path,
        width = 0.8,
        height = 0.8,
        zindex = 60,
        border = "rounded",
        relative = "editor",
        bo = { modifiable = false, filetype = "markdown" },
        keys = { q = "close" },
        wo = {
            wrap = true,
            linebreak = true,
        },
    })
end

return M
