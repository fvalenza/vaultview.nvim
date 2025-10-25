local Board = {}
Board.__index = Board

local Snacks = require("snacks")
local Constants = require("vaultview._ui.constants")
local ViewLayoutCarousel = require("vaultview._core.viewlayoutcarousel")
local ViewLayoutColumns = require("vaultview._core.viewlayoutcolumns")
local utils = require("vaultview.utils.utils")

-- function Board.new(config)
function Board.new(board_title, board_data, page_selection_win, context)
    local self = setmetatable({}, Board)

    self.context = context
    self.page_selection_win = page_selection_win -- The Snacks window where we will display the pages titles

    -- Create ViewLayoutCarousel instance for each page TODO
    self.board_title = board_title
    self.board_data = board_data or {}

    self.pages_title = {}
    self.pages_content = {}
    self.pages_viewlayout = {}
    for _, page in ipairs(self.board_data) do
        table.insert(self.pages_title, page.title)
        table.insert(self.pages_content, page.lists)
        local page_viewlayout = ViewLayoutColumns.new(page.lists, self.context)

        local vl = page_viewlayout
        -- Determine what to render based on the available space and the number of lists
        vl.last_left_collapsed, vl.last_right_collapsed, vl.layout_space_taken = vl:compute_layout()
        vl.visibility_window_left = math.max(1, vl.last_left_collapsed + 1) -- Ensure we don't go below 1
        vl.visibility_window_right = math.min(#vl.lists, vl.last_right_collapsed - 1) -- Ensure we don't go above the number of lists
        vl.list_focus_index = math.ceil((vl.last_left_collapsed + vl.last_right_collapsed) / 2) -- Set the focus index to the middle of the collapsed lists
        vl.card_focus_index = 1
        -- if list focused has no items, move focus to the next list with items
        local current_list = vl.lists[vl.list_focus_index]
        if #current_list.cards == 0 then
            vl.list_focus_index = vl.list_focus_index + 1
        end
        current_list.cards[vl.card_focus_index].win:focus()

        table.insert(self.pages_viewlayout, page_viewlayout)
    end

    self.active_page_index = 1

    print("Board created with title: " .. self.board_title)
    print(vim.inspect(self.board_data))

    return self
end

function Board:go_to_page(direction)
    local new_index = self.active_page_index + direction
    if new_index < 1 then
        new_index = #self.pages_title -- wrap left
    elseif new_index > #self.pages_title then
        new_index = 1 -- wrap right
    end

    -- hide current page layout
    -- if self.view_layout then
    -- 	self.view_layout:close()
    -- end
    self:hide()

    -- update active page
    self.active_page_index = new_index

    self:render()
end

function Board:render()
    self:render_page_selection()
    self:render_view()
end

function Board:close()
    for _, vl in ipairs(self.pages_viewlayout) do
        vl:close()
    end
end

function Board:hide()
    local active_page_viewlayout = self.pages_viewlayout[self.active_page_index]
    if active_page_viewlayout then
        active_page_viewlayout:hide()
    else
        -- vim.notify("No viewlayout for active page index " .. tostring(self.active_page_index), vim.log.levels.WARN)
    end
end

-- TODO  Display in the center of the page selection window ?? Not sure it is worth it
function Board:render_page_selection()
    local buf = self.page_selection_win.buf

    local pages_line = table.concat(self.pages_title, " | ")

    -- Final line with decorations
    local line = "<S-h>  <--  " .. pages_line .. "   --> <S-l>"

    -- Put the line into the buffer (replace first line, or you can append)
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { line })

    -- First, apply "Comment" highlight to everything except pages
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, 0, 11) -- "<S-h>  <--  "
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 0, #line - 9, -1) -- "   --> <S-l>"

    -- Now underline the active page
    local col_start = 12 -- starting col of first page (after "<S-h>  <--  ")
    for i, title in ipairs(self.pages_title) do
        local col_end = col_start + #title
        if i == self.active_page_index then
            vim.api.nvim_buf_add_highlight(buf, -1, "Underlined", 0, col_start, col_end)
        end
        col_start = col_end + 3 -- skip " | "
    end
end

function Board:render_view()
    local active_page_viewlayout = self.pages_viewlayout[self.active_page_index]
    if active_page_viewlayout then
        active_page_viewlayout:render()
    else
        -- vim.notify("No viewlayout for active page index " .. tostring(self.active_page_index), vim.log.levels.WARN)
    end
end

-- Focus on the n-th entry in board_data (across all pages and lists)
function Board:focus(entry_idx)
    print("Looking to focus on card with entry_idx:" .. entry_idx)
    local idx = 1 -- let's find the idx of the entry across all pages and lists of the one selected
    -- find the page whose cards/entries has given title
    for _, pages_viewlayout in ipairs(self.pages_viewlayout) do
        for list_index, list in ipairs(pages_viewlayout.lists) do
            print("Checking list: " .. list.title)
            print("List has " .. tostring(#list.cards) .. " cards")
            print(vim.inspect(list.cards))
            for item_index, item in ipairs(list.cards) do
                if idx == entry_idx then
                    -- focus this item
                    -- pages_viewlayout.list_focus_index = list_index
                    -- pages_viewlayout.card_focus_index = item_index
                    pages_viewlayout:move_focus_idx(list_index, item_index)
                    -- item.win:focus()
                    print("Focusing entry idx: " .. tostring(entry_idx))
                    print("In list: " .. list.title .. " (list index: " .. tostring(list_index) .. ")")
                    print("Card title: " .. item.title .. " (item index: " .. tostring(item_index) .. ")")
                    return
                end
                idx = idx + 1
            end
        end
    end



    -- local active_page_viewlayout = self.pages_viewlayout[self.active_page_index]
    -- if active_page_viewlayout then
    --     active_page_viewlayout:focus()
    -- else
    --     -- vim.notify("No viewlayout for active page index " .. tostring(self.active_page_index), vim.log.levels.WARN)
    -- end
end

function Board:focus_back()
    vim.notify("Get focus back on viewlayout", vim.log.levels.INFO)
    print("Get focus back on viewlayout")
    self.pages_viewlayout[self.active_page_index]:move_focus_horizontal("left")
    self.pages_viewlayout[self.active_page_index]:move_focus_horizontal("right")
end

-- TODO
function Board:pick_list()
    local entry_titles = {}
    for page_idx, page in ipairs(self.board_data) do
        for _, list in ipairs(page.lists) do
            for _, item in ipairs(list.items) do
                table.insert(entry_titles, item.title)
            end
        end
    end
    print("Entry titles:")
    print(vim.inspect(entry_titles))

    Snacks.picker.pick({
        items = entry_titles,
        finder = function()
            local finder_items = {}
            for idx, e in ipairs(entry_titles) do
                -- `text` is what will be shown. `item` can be the full table so you can use more fields later
                table.insert(finder_items, {
                    idx = idx,
                    text = e,
                    item = e,
                })
            end
            return finder_items
        end,
        format = function(item, _)
            local ret = {}
            ret[#ret + 1] = { tostring(item.idx), "SnacksPickerLabel" }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { item.text, "SnacksPickerComment" }
            return ret
        end,
        confirm = function(picker, item)
            picker:close()
            require("vaultview._commands.open.runner").run_focus(item.idx)
            -- go to the picked page
            if item then
                print("Picking page " .. item.text)
            end
        end,

        actions = {
            ["<CR>"] = "confirm",
            ["q"] = function(picker)
                picker:close()
                require("vaultview._commands.open.runner").run_focus()
            end,
            ["<ESC>"] = "close",
        },
    })
end

function Board:pick_card()
    local entry_titles = {}
    for page_idx, page in ipairs(self.board_data) do
        for _, list in ipairs(page.lists) do
            for _, item in ipairs(list.items) do
                table.insert(entry_titles, {
                    title = item.title,
                    rootfile = item.filepath
                })
            end
        end
    end
    print("Entry titles:")
    print(vim.inspect(entry_titles))

    Snacks.picker.pick({
        items = entry_titles,
        finder = function()
            local finder_items = {}
            for idx, e in ipairs(entry_titles) do
                -- `text` is what will be shown. `item` can be the full table so you can use more fields later
                table.insert(finder_items, {
                    idx = idx,
                    item = e,
                    text = e.title,
                    file = e.rootfile,
                })
            end
            return finder_items
        end,
        format = function(item, _)
            local ret = {}
            local _, filename, _ = utils.SplitFilename(item.file)
            ret[#ret + 1] = { tostring(item.idx), "SnacksPickerIdx" }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { item.text, "SnacksPickerTime" }
            return ret
        end,
        confirm = function(picker, item)
            picker:close()
            require("vaultview._commands.open.runner").run_focus(item.idx)
            -- go to the picked page
            if item then
                print("Picking page " .. item.text)
            end
        end,
        on_close = function()
            print("Get focus back on viewlayout on close")
            require("vaultview._commands.open.runner").run_focus_back()
        end,

        actions = {
            ["<CR>"] = "confirm",
            ["q"] = "close",
            ["<ESC>"] = "close",
        },
    })
end

--TODO
function Board:pick_content()
    local entry_contents = {}
    local idx = 1 -- idx of the card/entry of the content
    for page_idx, page in ipairs(self.board_data) do
        for list_idx, list in ipairs(page.lists) do
            for item_idx, item in ipairs(list.items) do
                if item.content and type(item.content) == "table" then
                    for content_idx, line in ipairs(item.content) do
                        entry_content_ = {
                            entry_idx = idx,
                            content = line,
                            rootfile = item.filepath,
                        }
                        table.insert(entry_contents, entry_content_)

                    end

                end
                idx = idx + 1
            end
        end
    end
    print("Entry contents:")
    print(vim.inspect(entry_contents))

    Snacks.picker.pick({
        items = entry_contents,
        finder = function()
            local finder_items = {}
            for idx, e in ipairs(entry_contents) do
                -- `text` is what will be shown. `item` can be the full table so you can use more fields later
                table.insert(finder_items, {
                    idx = idx,
                    text = e.content,
                    item = e.content,
                    entry_idx = e.entry_idx,
                    file = e.rootfile,
                })
            end
            return finder_items
        end,
        format = function(item, _)
            local ret = {}
            local _, filename, _ = utils.SplitFilename(item.file)
            ret[#ret + 1] = { tostring(item.idx), "SnacksPickerIdx" }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { item.text, "SnacksPickerTime" }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { filename, "SnacksPickerComment" }
            return ret
        end,
        confirm = function(picker, item)
            picker:close()
            print("Selected item:..." .. vim.inspect(item))
            require("vaultview._commands.open.runner").run_focus(item.entry_idx)
            -- -- go to the picked page
            -- if item then
            --     print("Picking page " .. item.text)
            -- end
        end,
        on_close = function()
            print("Get focus back on viewlayout on close")
            require("vaultview._commands.open.runner").run_focus_back()
        end,

        actions = {
            ["<CR>"] = "confirm",
            ["q"] = "close",
            ["<ESC>"] = "close",
        },

    })
end

return Board
