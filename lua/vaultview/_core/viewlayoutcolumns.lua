local ViewLayoutColumns = {}
ViewLayoutColumns.__index = ViewLayoutColumns

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local Keymaps = require("vaultview.keymaps")

local function set_list_keymap(layout, context)
    local map = {}

    for k, v in pairs(Keymaps.generic) do
        map[k] = v
    end

    for k, v in pairs(Keymaps.ViewLayoutColumns) do
        map[k] = { function() v[1](layout) end, mode = v.mode, noremap = v.noremap, nowait = v.nowait }
    end

    return map
end

-- function ViewLayoutColumns.new(config)
function ViewLayoutColumns.new(page_data, context)
    local self = setmetatable({}, ViewLayoutColumns)
    self.page_data = page_data
    self.context = context

    self.lists = self:createLayoutWindows(self.page_data)
    self.list_focus_index = 1
    self.card_focus_index = 0
    return self
end


function ViewLayoutColumns:hide()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:hide()
            end
        end
        list.win:hide()
    end
end

function ViewLayoutColumns:close()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:close()
            end
        end
        list.win:close()
    end
end
function ViewLayoutColumns:createLayoutWindows(data)
    local lists = {}

    for listId, list in ipairs(data) do
        local id = listId
        local title = list.title or "Untitled List"
        local items = list.items or {} -- Default to empty table if no items
        local cards = {}

        local expanded = true -- Setting it to true for the moment but should de determined later, in render ?
        -- local win = ViewLayoutColumns.make_list_window(title)
        local win = self:make_list_window(title)
        -- create cards for each item in the list
        for _, item in ipairs(items) do
            local card_title = item.title or "Untitled Card"
            local card_content = item.content or "No content" -- TODO temporary ?  but shall not be item.path
            local card_filepath = item.filepath or nil
            local card_win = self:make_card_window(card_title, card_content)
            local card_expanded = true -- Setting it to true for the moment but should be determined later, in render ?
            -- Add the card window to the list
            table.insert(cards, {
                id = item.date or "no-date",
                title = card_title,
                filepath = card_filepath,
                win = card_win,
                content = card_content,
                expanded = card_expanded,
            })
            -- print("Created card window for item: " .. card_title)
        end

        table.insert(lists, {
            id = id,
            title = title,
            win = win,
            expanded = expanded,
            cards = cards,
        })
    end

    return lists
end

-- card_content is temporary before parsing the real path given
-- function ViewLayoutColumns:make_card_window(title)
function ViewLayoutColumns:make_card_window(title, card_content)
    local lself = self
    local lcontext = self.context
    -- print("context is " .. vim.inspect(lcontext))
    local card_win = Snacks.win({
        width = Constants.card_win.width,
        height = Constants.card_win.height,
        zindex = Constants.card_win.zindex,
        -- border = Constants.card_win.border,
        border = "rounded",
        relative = "editor",
        row = Constants.card_win.row, -- align all lists at top of view_win
        col = Constants.card_win.col, -- at creation, put them all at the top left. will be recomputed in render function
        text = card_content,
        title = title,
        show = true,
        enter = false,
        backdrop = false,
        focusable = true,
        keys = set_list_keymap(lself, lcontext),
        bo = { modifiable = true },
        -- bo = { modifiable = true, filetype = filetype },
    })
    card_win:hide()

    return card_win
end

function ViewLayoutColumns:make_list_window(title)
    local lself = self
    local list_win = Snacks.win({
        width = Constants.list_win.width,
        height = Constants.list_win.height,
        zindex = Constants.list_win.zindex,
        -- border = Constants.list_win.border,
        border = "rounded",
        relative = "editor",
        row = Constants.list_win.row, -- align all lists at top of view_win
        col = Constants.list_win.col, -- at creation, put them all at the top left. will be recomputed in render function
        show = true,
        enter = false,
        backdrop = false,
        focusable = true,
        keys = set_list_keymap(lself),
        bo = { modifiable = true },
        -- bo = { modifiable = true, filetype = filetype },
    })
    list_win:hide()

    return list_win
end

-- function ViewLayoutColumns.update(data)
-- end

local space_taken_expanded = Constants.list_win.width + 2 -- 1 for padding and 1 for borders
local space_taken_collapsed = Constants.list_win_close.width + 2 -- 1 for pqdding qnd 1 for borders

function ViewLayoutColumns:collapse_list(index)
    self.lists[index].expanded = false
    for _, card in ipairs(self.lists[index].cards) do
        card.expanded = false -- Collapse all cards in the list
    end
end

function ViewLayoutColumns:expand_list() end

-- compute at startup which list to expand and collapse
-- TODO and foreachlist expanded, which cards to expand and collapse
function ViewLayoutColumns:compute_layout()
    local available_width = vim.o.columns
    local total_space_taken_all_expanded = #self.lists * space_taken_expanded
    local layout_space_taken = total_space_taken_all_expanded

    local left_idx = 1
    local right_idx = #self.lists
    while layout_space_taken > available_width and left_idx <= right_idx do
        -- Collapse left side first
        if self.lists[left_idx].expanded then
            self:collapse_list(left_idx)
        end
        left_idx = left_idx + 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
        if layout_space_taken <= available_width then
            break
        end

        -- Collapse right side
        if self.lists[right_idx].expanded then
            self:collapse_list(right_idx)
        end
        right_idx = right_idx - 1
        layout_space_taken = layout_space_taken - (space_taken_expanded - space_taken_collapsed)
    end

    return left_idx - 1, right_idx + 1, layout_space_taken
end

function ViewLayoutColumns:render()
    local function hide_all_entry_cards(list)
        for _, card in ipairs(list.cards or {}) do
            local card_win = card.win
            card_win:hide() -- hide the card window
        end
    end

    local render_expanded_list = function(list, col_offset)
        local win = list.win

        local list_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
        win.opts.wo.winbar = list_winbar_title_fmt:format(list.title, #list.cards)

        win.opts.col = col_offset -- put the win at the offset
        -- determine the width based on expanded state
        local width = list.expanded and Constants.list_win.width or Constants.list_win_close.width
        win.opts.width = width
        col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border

        -- Render the cards of the lists
        -- TODO iterate over the items of the list and render them
        -- put everything in function called render_cards(list) that shall also account for card expand/collapse (x for cards, X for lists)
        local row_offset = Constants.list_win.row + 1 + 1 -- start at the row of the list + 1

        for c, card in ipairs(list.cards or {}) do
            -- shall set the position of the card window in the list column:
            -- col shall be the col of the current list window and row shall start at the row of the list +1 and increment for each card
            local card_win = card.win
            card_win.opts.width = width -- set the width of the card window
            card_win.opts.col = list.win.opts.col -- align with the list
            local height = card.expanded and Constants.card_win.height or Constants.card_win_close.height
            card_win.opts.row = row_offset -- put the card below the list title
            card_win.opts.height = height
            row_offset = row_offset + height + 1 + 1 -- increment the row offset for the next card

            -- FIXME: when focusing on previsouly collapsed list/card, errors "not enough room"
            -- local card_winbar_title_fmt = " %s %%= %d " -- title on left, number of cards on right
            -- card_win.opts.wo.winbar = card_winbar_title_fmt:format(card.title, c)

            card_win:show()
        end

        list.win:show()

        return col_offset
    end

    local render_collapsed_list = function(list, col_offset)
        local win = list.win
        local list_winbar_tile_fmt = " %d "
        win.opts.wo.winbar = list_winbar_tile_fmt:format(#list.cards)

        local function stringToCharList(str)
            local chars = {}
            for idx = 1, #str do
                table.insert(chars, str:sub(idx, idx))
            end
            return chars
        end

        local char_list_title = stringToCharList(list.title)
        vim.api.nvim_buf_set_lines(win.buf, -1, -1, false, char_list_title)

        win.opts.col = col_offset -- put the win at the offset
        -- determine the width based on expanded state
        local width = list.expanded and Constants.list_win.width or Constants.list_win_close.width
        win.opts.width = width
        col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border

        list.win:show()

        return col_offset
    end

    local col_offset = Constants.list_win.col -- offset for which column to put the next list window
    for _, list in pairs(self.lists) do

        -- Start by hiding all card windows. We will show them later if necessary (if list is expanded)
        hide_all_entry_cards(list)

        -- Clear the list buffer before setting new lines
        vim.api.nvim_buf_set_lines(list.win.buf, 0, -1, false, {""})

        if list.expanded then
            col_offset = render_expanded_list(list, col_offset)
        else
            col_offset = render_collapsed_list(list, col_offset)

        end

    end

    -- Focus the list or the card of the list
    local current_list = self.lists[self.list_focus_index]
    local current_card_in_list = current_list.cards[self.card_focus_index]
    if self.card_focus_index == 0 then
        -- print("Focusing on list: " .. current_list.title)
        current_list.win:focus()
    else
        -- print("Focusing on card with index: " .. self.card_focus_index)
        -- print("Focusing on card: " .. current_card_in_list.title)
        if current_card_in_list and current_card_in_list.win then
            current_card_in_list.win:focus()
        else
            -- print("No card to focus in the current list.")
        end
    end
    -- We are on a list, toggle the list expand/collapse
end

-- TODO Adding same kind of movement as in neovim when you start to j/k from a last line character
-- When going to shorter lines, it should not move the focus to the next line but stay on the last character of the current line
-- When going to longer lines, it should stay at the index/number of the start
function ViewLayoutColumns:move_focus_horizontal(direction)
    local direction_index = 0
    if direction == "left" then
        direction_index = -1
    elseif direction == "right" then
        direction_index = 1
    else
        -- print("Invalid horizontal direction: " .. tostring(direction))
        return
    end

    -- print("Visibility window: " .. self.visibility_window_left .. " to " .. self.visibility_window_right)

    local old_index = self.list_focus_index or 1
    local old_list = self.lists[old_index]
    local old_card_index = old_list.card_focus_index or 0 -- 0 = header, >0 = card number

    -- print("Moving focus " .. direction .. " from index: " .. old_index)

    local new_index = old_index + direction_index
    new_index = math.max(1, math.min(new_index, #self.lists))

    -- Expand/collapse logic for visibility
    if new_index < self.visibility_window_left then
        -- print("Expanding left list")
        self.lists[new_index].expanded = true
        self:collapse_list(self.visibility_window_right) -- Collapse the righttmost list
        self.visibility_window_left = new_index
        self.visibility_window_right = self.visibility_window_right - 1
        self.last_left_collapsed = new_index
        self.last_right_collapsed = self.last_right_collapsed - 1
        self:render()
    elseif new_index > self.visibility_window_right then
        -- print("Expanding right list")
        self.lists[new_index].expanded = true
        self:collapse_list(self.visibility_window_left) -- Collapse the leftmost list
        self.visibility_window_right = new_index
        self.visibility_window_left = self.visibility_window_left + 1
        self.last_right_collapsed = new_index
        self.last_leftcollapsed = self.last_right_collapsed + 1
        self:render()
    end

    -- Update index
    self.list_focus_index = new_index
    local new_list = self.lists[new_index]

    -- If target list has fewer cards than old_card_index, reset to header
    if #new_list.cards == 0 then
        new_list.card_focus_index = 0
    elseif #new_list.cards < old_card_index then
        new_list.card_focus_index = #new_list.cards
    else
        new_list.card_focus_index = old_card_index
    end

    -- Focus correct window (list header or card)
    if new_list.card_focus_index == 0 then
        new_list.win:focus()
    else
        new_list.cards[new_list.card_focus_index].win:focus()
    end

    -- print(
    --     "Moving focus from " .. old_index .. " to " .. new_index .. " (card index: " .. new_list.card_focus_index .. ")"
    -- )
end

function ViewLayoutColumns:move_focus_idx(list_idx, card_idx)
    -- Determine if current list_focus_index is left or right of the new list_idx
    if list_idx < 1 or list_idx > #self.lists then
        -- print("Invalid list index: " .. tostring(list_idx))
        return
    end
    local direction = list_idx < self.list_focus_index and "left" or "right"
    while self.list_focus_index ~= list_idx do
        self:move_focus_horizontal(direction)
    end

    local direction_updown = card_idx < (self.lists[self.list_focus_index].card_focus_index or 0) and "up" or "down"
    while (self.lists[self.list_focus_index].card_focus_index or 0) ~= card_idx do
        self:move_focus_vertical(direction_updown)
    end

    -- if list_idx < 1 or list_idx > #self.lists then
    --     print("Invalid list index: " .. tostring(list_idx))
    --     return
    -- end
    --
    -- local target_list = self.lists[list_idx]
    -- if card_idx < 0 or card_idx > #target_list.cards then
    --     -- print("Invalid card index: " .. tostring(card_idx))
    --     return
    -- end
    --
    -- self.list_focus_index = list_idx
    -- target_list.card_focus_index = card_idx
    --
    -- -- Adjust visibility window if necessary
    -- if list_idx < self.visibility_window_left then
    --     self.visibility_window_left = list_idx
    --     self.visibility_window_right = math.min(self.visibility_window_right + 1, #self.lists)
    -- elseif list_idx > self.visibility_window_right then
    --     self.visibility_window_right = list_idx
    --     self.visibility_window_left = math.max(self.visibility_window_left - 1, 1)
    -- end
    --
    -- self:render()
end

function ViewLayoutColumns:move_focus_mostleft()
    while self.visibility_window_left > 1 do
        self:move_focus_horizontal("left")
    end
end
function ViewLayoutColumns:move_focus_left()
    self:move_focus_horizontal("left")
end

function ViewLayoutColumns:move_focus_center()
    -- expand all lists and recompute inital layout
    for _, list in ipairs(self.lists) do
        list.expanded = true
    end
    self.last_left_collapsed, self.last_right_collapsed, self.layout_space_taken = self:compute_layout()
    self.visibility_window_left = math.max(1, self.last_left_collapsed + 1) -- Ensure we don't go below 1
    self.visibility_window_right = math.min(#self.lists, self.last_right_collapsed - 1) -- Ensure we don't go above the number of lists
    self.list_focus_index = math.ceil((self.last_left_collapsed + self.last_right_collapsed) / 2) -- Set the focus index to the middle of the collapsed lists
    self:render()
end

function ViewLayoutColumns:move_focus_right()
    self:move_focus_horizontal("right")
end

function ViewLayoutColumns:move_focus_mostright()
    -- call move_right until visibility_window_right == #self.lists
    while self.visibility_window_right < #self.lists do
        self:move_focus_horizontal("right")
    end
end

function ViewLayoutColumns:move_focus_vertical(direction)
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

function ViewLayoutColumns:move_focus_mostup()
    local current_list = self.lists[self.list_focus_index]
    current_list.card_focus_index = 0
    current_list.win:focus()
end

function ViewLayoutColumns:move_focus_up()
    self:move_focus_vertical("up")
end

function ViewLayoutColumns:move_focus_down()
    self:move_focus_vertical("down")
end

function ViewLayoutColumns:move_focus_mostdown()
    local current_list = self.lists[self.list_focus_index]
    current_list.card_focus_index = #current_list.cards
    current_list.cards[current_list.card_focus_index].win:focus()
end

function ViewLayoutColumns:focus()
    local current_list = self.lists[self.list_focus_index]
    local ci = current_list.card_focus_index or 0

    if ci == 0 then
        current_list.win:focus()
    else
        current_list.cards[ci].win:focus()
    end
end



function ViewLayoutColumns:open_focused_in_nvim()
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

function ViewLayoutColumns:open_focused_in_obsidian()
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




return ViewLayoutColumns
