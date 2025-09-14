local ViewLayoutCarousel = {}
ViewLayoutCarousel.__index = ViewLayoutCarousel

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")

-- TODO
-- 1  2  3 ... 9  -> goToBoard(index)
-- shift h/l  -> goToPage(index) with index = current_page + 1 or -1
-- or shift h/l to go to next/previous page
local function set_list_keymap(layout, context)
    return {
        ["<M-h>"] = {
            function()
                layout:move_focus_mostleft()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["h"] = {
            function()
                layout:move_focus_left()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["c"] = {
            function()
                layout:move_focus_center()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["l"] = {
            function()
                layout:move_focus_right()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["<M-l>"] = {
            function()
                layout:move_focus_mostright()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["gg"] = {
            function()
                layout:move_focus_mostup()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["k"] = {
            function()
                layout:move_focus_up()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["j"] = {
            function()
                layout:move_focus_down()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["G"] = {
            function()
                layout:move_focus_mostdown()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        q = {
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_close_board()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
		["p"] = {
			function()
			    local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_previous_board()
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["n"] = {
			function()
				local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_next_board()
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
        ["<S-h>"] = {-- Like for quit, use runner "commands" to "pass" it to context.vaultview or to context.vaultview.board
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_previous_page()
            end, -- previous page
            mode = "n",
            noremap = true,
            nowait = true,
        },
        ["<S-l>"] = {-- Like for quit, use runner "commands" to "pass" it to context.vaultview or to context.vaultview.board
            function()
                local runner = require("vaultview._commands.open.runner")
                runner.run_go_to_next_page()
            end, -- next page
            mode = "n",
            noremap = true,
            nowait = true,
        },
        X = {
            function()
                layout:toggle_expand_list()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
        x = {
            function()
                layout:toggle_expand()
            end,
            mode = "n",
            noremap = true,
            nowait = true,
        },
		["1"] = {
			function()
			    local runner = require("vaultview._commands.open.runner")
			    runner.run_go_to_board(1)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["2"] = {
			function()
				local runner = require("vaultview._commands.open.runner")
				runner.run_go_to_board(2)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
		["3"] = {
			function()
				local runner = require("vaultview._commands.open.runner")
				runner.run_go_to_board(3)
			end,
			mode = "n",
			noremap = true,
			nowait = true,
		},
    }
end

-- function ViewLayoutCarousel.new(config)
function ViewLayoutCarousel.new(page_data, context)
    local self = setmetatable({}, ViewLayoutCarousel)
    self.page_data = page_data
    self.context = context

    self.lists = self:createLayoutWindows(self.page_data)
    self.list_focus_index = 1
    self.card_focus_index = 0
    return self
end

function ViewLayoutCarousel:show()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:show()
            end
        end
        list.win:show()
    end
end

function ViewLayoutCarousel:hide()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:hide()
            end
        end
        list.win:hide()
    end
end

function ViewLayoutCarousel:close()
    for _, list in ipairs(self.lists) do
        for _, card in ipairs(list.cards or {}) do
            if card.win then
                card.win:close()
            end
        end
        list.win:close()
    end
end
function ViewLayoutCarousel:createLayoutWindows(data)
    local lists = {}

    for listId, list in ipairs(data) do
        local id = listId
        local title = list.title or "Untitled List"
        local items = list.items or {} -- Default to empty table if no items
        local cards = {}

        local expanded = true -- Setting it to true for the moment but should de determined later, in render ?
        -- local win = ViewLayoutCarousel.make_list_window(title)
        local win = self:make_list_window(title)
        -- create cards for each item in the list
        for _, item in ipairs(items) do
            local card_title = item.title or "Untitled Card"
            local card_content = item.content or "No content" -- TODO temporary ?  but shall not be item.path
            local card_win = self:make_card_window(card_title, card_content)
            local card_expanded = true -- Setting it to true for the moment but should be determined later, in render ?
            -- Add the card window to the list
            table.insert(cards, {
                id = item.date or "no-date",
                title = card_title,
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
-- function ViewLayoutCarousel:make_card_window(title)
function ViewLayoutCarousel:make_card_window(title, card_content)
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
        show = true,
        enter = false,
        backdrop = false,
        focusable = true,
        keys = set_list_keymap(lself, lcontext),
        bo = { modifiable = false },
        -- bo = { modifiable = true, filetype = filetype },
    })
    card_win:hide()

    return card_win
end

function ViewLayoutCarousel:make_list_window(title)
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
        text = title,
        show = true,
        enter = false,
        backdrop = false,
        focusable = true,
        keys = set_list_keymap(lself),
        bo = { modifiable = false },
        -- bo = { modifiable = true, filetype = filetype },
    })
    list_win:hide()

    return list_win
end

-- function ViewLayoutCarousel.update(data)
-- end

local space_taken_expanded = Constants.list_win.width + 2 -- 1 for padding and 1 for borders
local space_taken_collapsed = Constants.list_win_close.width + 2 -- 1 for pqdding qnd 1 for borders

function ViewLayoutCarousel:collapse_list(index)
    self.lists[index].expanded = false
    for _, card in ipairs(self.lists[index].cards) do
        card.expanded = false -- Collapse all cards in the list
    end
end

function ViewLayoutCarousel:expand_list() end

-- compute at startup which list to expand and collapse
-- TODO and foreachlist expanded, which cards to expand and collapse
function ViewLayoutCarousel:compute_layout()
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

function ViewLayoutCarousel:render()
    -- update positioning of the lists depending on the layout
    local col_offset = Constants.list_win.col -- offset for the next list
    for i, list in pairs(self.lists) do
        local win = list.win
        win.opts.col = col_offset -- put the win at the offset
        -- determine the width based on expanded state
        local width = list.expanded and Constants.list_win.width or Constants.list_win_close.width
        win.opts.width = width
        col_offset = col_offset + width + 1 + 1 -- 1 = padding, 1 = border

        -- title shall be title string if expaneded, or result of stringToCharList if not expanded
        if list.expanded then
            win.opts.text = list.title
        else
            local function stringToCharList(str)
                local chars = {}
                for idx = 1, #str do
                    table.insert(chars, str:sub(idx, idx))
                end
                return chars
            end
            local char_list_title = stringToCharList(list.title)
            -- print(vim.inspect(char_list_title))
            -- win.opts.text = char_list_title -- FIX: this is not working as expected, need to convert to a list of chars
            win.opts.text = "toto" -- A tester pour voir si j'arrive bien a update le texte
        end

        -- Render the cards of the lists
        -- TODO iterate over the items of the list and render them
        -- put everything in function called render_cards(list) that shall also account for card expand/collapse (x for cards, X for lists)
        local row_offset = Constants.list_win.row + 1 + 1 -- start at the row of the list + 1
        -- local row_offset = list.win.opts.row + 1 + 1
        -- print("Rendering cards for list: " .. list.title)
        -- print("Number of cards: " .. #list.cards)
        -- print("Cards: " .. vim.inspect(list.cards))
        for _, card in ipairs(list.cards or {}) do
            -- print("Rendering card: " .. card.title)
            -- shall set the position of the card window in the list column:
            -- col shall be the col of the current list window and row shall start at the row of the list +1 and increment for each card
            local card_win = card.win
            card_win.opts.width = width -- set the height of the card window
            card_win.opts.col = list.win.opts.col -- align with the list
            local height = card.expanded and Constants.card_win.height or Constants.card_win_close.height
            card_win.opts.row = row_offset -- put the card below the list title
            card_win.opts.height = height
            row_offset = row_offset + height + 1 + 1 -- increment the row offset for the next card

            card_win.opts.text = card.content -- set the content of the card
            if list.expanded == true then
                card_win:show() -- show the card window
            else
                -- If the list is collapsed, hide all its cards
                for _, card in ipairs(list.cards or {}) do
                    local card_win = card.win
                    card_win:hide() -- hide the card window
                end
            end
        end
    end

    -- Actual rendering of the lists windows
    self:show()
    -- Focus the list or the card of the list

    -- print("list index: " .. self.list_focus_index)
    -- print("card index: " .. self.card_focus_index)
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
function ViewLayoutCarousel:move_focus_horizontal(direction)
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

function ViewLayoutCarousel:move_focus_mostleft()
    while self.visibility_window_left > 1 do
        self:move_focus_horizontal("left")
    end
end
function ViewLayoutCarousel:move_focus_left()
    self:move_focus_horizontal("left")
end

function ViewLayoutCarousel:move_focus_center()
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

function ViewLayoutCarousel:move_focus_right()
    self:move_focus_horizontal("right")
end

function ViewLayoutCarousel:move_focus_mostright()
    -- call move_right until visibility_window_right == #self.lists
    while self.visibility_window_right < #self.lists do
        self:move_focus_horizontal("right")
    end
end

function ViewLayoutCarousel:move_focus_vertical(direction)
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

function ViewLayoutCarousel:move_focus_mostup()
    local current_list = self.lists[self.list_focus_index]
    current_list.card_focus_index = 0
    current_list.win:focus()
end

function ViewLayoutCarousel:move_focus_up()
    self:move_focus_vertical("up")
end

function ViewLayoutCarousel:move_focus_down()
    self:move_focus_vertical("down")
end

function ViewLayoutCarousel:move_focus_mostdown()
    local current_list = self.lists[self.list_focus_index]
    current_list.card_focus_index = #current_list.cards
    current_list.cards[current_list.card_focus_index].win:focus()
end
return ViewLayoutCarousel
