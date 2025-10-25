local ViewLayoutTrait = {}

-- these are the same
-- function ViewLayoutTrait:hide()
-- ViewLayoutTrait.hide = function(self)
function ViewLayoutTrait:hide()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:hide()
            end
        end
        list.win:hide()
    end
end

function ViewLayoutTrait:close()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:close()
            end
        end
        list.win:close()
    end
end

function ViewLayoutTrait:collapse_list(index)
    self.lists[index].expanded = false
    for _, card in ipairs(self.lists[index].cards) do
        card.expanded = false -- Collapse all cards in the list
    end
end

function ViewLayoutTrait:expand_list() end

function ViewLayoutTrait:focus()
    local current_list = self.lists[self.list_focus_index]
    local ci = current_list.card_focus_index or 0

    if ci == 0 then
        current_list.win:focus()
    else
        current_list.cards[ci].win:focus()
    end
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
            require("vaultview._commands.open.runner").refresh() -- HACK to refresh whole board (and data parsing) instead of just the updated card
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
    print("Opening Obsidian URI:", uri)

    local vaultname = "myVault"
    local cmd = string.format("!xdg-open 'obsidian://open?vault=%s&file=%s'", vaultname, card.title)
    print("Executing command:", cmd)
    vim.cmd(cmd)
end
return ViewLayoutTrait
