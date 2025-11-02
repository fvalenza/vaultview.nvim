local ViewLayoutTrait = {}

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local Keymaps = require("vaultview.keymaps")

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


local function set_keymap(layout, class_name)
    local map = {}

    for k, v in pairs(Keymaps.generic) do
        map[k] = v
    end

    print("Class name in set_list_keymap:", class_name)
    print("Keymaps:" .. vim.inspect(Keymaps))

    -- print(vim.inspect(Keymaps[class_name]))

    for k, v in pairs(Keymaps[class_name]) do
        map[k] = { function() v[1](layout) end, mode = v.mode, noremap = v.noremap, nowait = v.nowait }
    end

    return map
end

function ViewLayoutTrait:createLayoutWindows(data)
    local lists = {}

    for listId, list in ipairs(data) do
        local id = listId
        local title = list.title or "Untitled List"
        local items = list.items or {} -- Default to empty table if no items
        local cards = {}

        -- create cards for each item in the list
        local sum_cards_height = 0
        for _, item in ipairs(items) do
            local card_title = item.title or "Untitled Card"
            local card_content = item.content or "No content" -- TODO temporary ?  but shall not be item.path
            local card_filepath = item.filepath or nil
            local card_win = self:make_card_window(card_title, card_content)
            -- print("Creating card window for item: " .. card_title)
            -- print(vim.inspect(card_win))
            local card_expanded = true -- Setting it to true for the moment but should be determined later, in render ?
            -- Add the card window to the list
            table.insert(cards, {
                id = item.date or "no-date",
                title = card_title,
                filepath = card_filepath,
                win = card_win,
                content = card_content,
                expanded = true, -- Setting it to true for the moment but should de determined later
            })
            sum_cards_height = sum_cards_height + card_win.opts.height + 1 + 1 -- 1 = padding, 1 = border. search for "+1 +1" if wanting to factorize into a constant
        end

        local win = self:make_list_window(sum_cards_height)

        table.insert(lists, {
            id = id,
            title = title,
            win = win,
            expanded = true, -- Setting it to true for the moment but should de determined later
            cards = cards,
        })
    end

    return lists
end

function ViewLayoutTrait:make_list_window(sum_cards_height)
    local class_name = self.__name
    local cfg = Constants.list_win[class_name]
    local lself = self
    local list_height = math.min(cfg.height, 2 + sum_cards_height) -- WARN: Can't put 1 here because "Not enough room" errors
    local list_win = Snacks.win({
        width = cfg.width,
        height = list_height,
        zindex = cfg.zindex,
        -- border = cfg.border,
        border = "rounded",
        relative = "editor",
        row = cfg.row, -- align all lists at top of view_win
        col = cfg.col, -- at creation, put them all at the top left. will be recomputed in render function
        show = true,
        enter = false,
        backdrop = false,
        focusable = true,
        keys = set_keymap(lself, class_name),
        bo = { modifiable = true },
        -- bo = { modifiable = true, filetype = filetype },
    })
    list_win:hide()

    return list_win
end

-- card_content is temporary before parsing the real path given
function ViewLayoutTrait:make_card_window(title, card_content)
    local class_name = self.__name
    local cfg = Constants.card_win[class_name]
    local lself = self
    print("Making card window with title:", title)
    print("Card content:", vim.inspect(card_content))
    print("Card content lines:", #card_content)
    local card_height = math.min(cfg.height, math.max(1,#card_content)) -- WARN: Can't put 1 here because "Not enough room" errors
    print("Card height set to:", card_height)
    local card_win = Snacks.win({
        width = cfg.width,
        height = card_height,
        zindex = cfg.zindex,
        -- border = cfg.border,
        border = "rounded",
        relative = "editor",
        row = cfg.row, -- align all lists at top of view_win
        col = cfg.col, -- at creation, put them all at the top left. will be recomputed in render function
        text = card_content,
        title = title,
        show = true,
        enter = false,
        backdrop = false,
        focusable = true,
        keys = set_keymap(lself, class_name),
        bo = { modifiable = true },
        -- bo = { modifiable = true, filetype = filetype },
    })
    card_win:hide()
    card_win.viewlayout_height = card_height -- store the height for later use in render

    return card_win
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

function ViewLayoutTrait:move_focus_vertical(direction)
    local current_list = self.lists[self.list_focus_index]
    local num_cards = #current_list.cards
    local ci = current_list.card_focus_index or 0

    if direction == "down" then
        if ci < num_cards then
            ci = ci + 1
        else
            -- Already at last card, do nothing (or wrap around if desired)
        end
    elseif direction == "up" then
        if ci > 0 then
            ci = ci - 1
        else
            -- Already at list header
        end
    end

    current_list.card_focus_index = ci

    -- Focus the right window
    if ci == 0 then
        current_list.win:focus()
    else
        current_list.cards[ci].win:focus()
    end
end

function ViewLayoutTrait:move_focus_mostup()
    local current_list = self.lists[self.list_focus_index]
    current_list.card_focus_index = 0
    current_list.win:focus()
end

function ViewLayoutTrait:move_focus_up()
    self:move_focus_vertical("up")
end

function ViewLayoutTrait:move_focus_down()
    self:move_focus_vertical("down")
end

function ViewLayoutTrait:move_focus_mostdown()
    local current_list = self.lists[self.list_focus_index]
    current_list.card_focus_index = #current_list.cards
    current_list.cards[current_list.card_focus_index].win:focus()
end

function ViewLayoutTrait:move_focus_mostleft()
    while self.list_focus_index > 1 do
        self:move_focus_horizontal("left")
    end
end
function ViewLayoutTrait:move_focus_left()
    self:move_focus_horizontal("left")
end

function ViewLayoutTrait:move_focus_center()
    self.list_focus_index = self.list_focus_index_center
    self:render()
end

function ViewLayoutTrait:move_focus_right()
    self:move_focus_horizontal("right")
end

function ViewLayoutTrait:move_focus_mostright()
    -- call move_right until visibility_window_right == #self.lists
    while self.list_focus_index < #self.lists do
        self:move_focus_horizontal("right")
    end
end
return ViewLayoutTrait
