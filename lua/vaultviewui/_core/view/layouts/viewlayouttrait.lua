local ViewLayoutTrait = {}

local Snacks = require("snacks")
local Constants = require("vaultviewui._ui.constants")
local Keymaps = require("vaultviewui.keymaps")

function ViewLayoutTrait:debug()
    dprint("ViewLayoutTrait debug:")
    dprint(self.__name)
    dprint(self.vaultWindows)
    dprint(self.viewState)

end

-- function ViewLayoutTrait:compute_layout(viewData, viewWindows, viewState)
--     dprint("Computing layout for ViewLayoutTrait:", self.__name)
--     -- Default implementation does nothing
-- end


function ViewLayoutTrait:render(viewData, viewWindows, viewState)
    dprint("Rendering ViewLayoutTrait:", self.__name)
    dprint("ViewWindows:", viewWindows)
    dprint("ViewState:", viewState)
    local focused_page_idx, focused_list_idx, focused_item_idx = viewState.focused.page, viewState.focused.list, viewState.focused.item
    self:compute_layout(viewData, viewWindows, viewState)
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:show()
            end
        end
        list.win:show()
    end

end

-- these are the same
-- function ViewLayoutTrait:hide()
-- ViewLayoutTrait.hide = function(self)
function ViewLayoutTrait:hide(viewWindows, viewState)

    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:hide()
            end
        end
        list.win:hide()
    end
end

function ViewLayoutTrait:close(viewWindows, viewState)

    local focused_page_idx = viewState.focused.page
    for _, list in ipairs(viewWindows.pages[focused_page_idx].lists) do
        for _, entry in ipairs(list.items or {}) do
            if entry then
                entry:close()
            end
        end
        list.win:close()
    end
end


local function set_keymap(layout, class_name)
    local map = {}

    for k, v in pairs(Keymaps.generic) do
        map[k] = v
    end

    -- print("Class name in set_list_keymap:", class_name)
    -- print("Keymaps:" .. vim.inspect(Keymaps))

    -- print(vim.inspect(Keymaps[class_name]))

    for k, v in pairs(Keymaps[class_name]) do
        map[k] = { function() v[1](layout) end, mode = v.mode, noremap = v.noremap, nowait = v.nowait }
    end

    return map
end






function ViewLayoutTrait:open_focused_in_nvim()
    local current_list = self.lists[self.list_focus_index]
    local ci = current_list.card_focus_index or 0

    if ci == 0 then
        -- vim.notify("Focused on list header: " .. current_list.title, vim.log.levels.INFO)
        return
    end

    local card = current_list.cards[ci]
    if not card or not card.filepath then
        -- vim.notify("No file path for card: " .. (card and card.title or "unknown"), vim.log.levels.WARN)
        return
    end

    local filepath = card.filepath
    local expanded_path = vim.fn.expand(filepath)
    if vim.fn.filereadable(expanded_path) == 0 then
        -- vim.notify("File does not exist: " .. expanded_path, vim.log.levels.ERROR)
        return
    end

    local win = require("snacks").win({
        file = expanded_path,
        width = 0.9,
        height = 0.95,
        zindex = 50,
        border = "rounded",
        relative = "editor",
        bo = { modifiable = true,  },
        keys = { q = "close" },
        on_close = function ()
            require("vaultviewui._commands.open.runner").refresh() -- HACK to refresh whole board (and data parsing) instead of just the updated card
            -- TODO implement a way to just refresh the card that was edited
        end,
        wo = {
            wrap = true,
            linebreak = true,
        },
    })
end

function ViewLayoutTrait:open_focused_in_obsidian()
    local current_list = self.lists[self.list_focus_index]
    local ci = current_list.card_focus_index or 0

    if ci == 0 then
        -- vim.notify("Focused on list header: " .. current_list.title, vim.log.levels.INFO)
        return
    end

    local card = current_list.cards[ci]
    if not card or not card.filepath then
        -- vim.notify("No file path for card: " .. (card and card.title or "unknown"), vim.log.levels.WARN)
        return
    end

    local path = vim.fn.fnamemodify(card.filepath, ":p") -- absolute path
    -- https://help.obsidian.md/Extending+Obsidian/Obsidian+URI
    local uri = "obsidian://open?path=" .. vim.fn.escape(path, " ")
    -- print("Opening Obsidian URI:", uri)

    local vaultname = "myVault"
    local cmd = string.format("!xdg-open 'obsidian://open?vault=%s&file=%s'", vaultname, card.title)
    -- print("Executing command:", cmd)
    vim.cmd(cmd)
end

return ViewLayoutTrait
