if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tutils = require("vaultviewui._core.utils.table_utils")
local utils = require("vaultviewui._core.utils.utils")

local M = {}

local monthsMap = {
    ["01"] = "January",
    ["02"] = "February",
    ["03"] = "March",
    ["04"] = "April",
    ["05"] = "May",
    ["06"] = "June",
    ["07"] = "July",
    ["08"] = "August",
    ["09"] = "September",
    ["10"] = "October",
    ["11"] = "November",
    ["12"] = "December",
}
local months = {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    }

--- Convert a numeric month ("01") into a month name ("January")
--- @param month string
--- @return string
local function mmToMonthString(month)
    return monthsMap[month] or month
end

------------------------------------------------------------------------------------------------------------------------
-- Board Construction
------------------------------------------------------------------------------------------------------------------------

--- Build a board structure grouped by **year → month**.
---
--- Expected boardInputs structure:
--- {
---   { name = "2024-01-MyNote", path = "/full/path", ... },
---   { name = "2024-09-X", path = "/full/path", ... },
--- }
---
--- Output structure:
--- {
---   {
---     title = "2024",
---     lists = {
---        { title = "January", items = { ... } },
---        { title = "February", items = { ... } },
---        ...
---     }
---   }
--- }
---
--- @param boardInputs table[] List of raw notes
--- @return table boardData Multi-page board structure grouped by pages(year)/lists(month)/entries(dailynote of that month)
function M.arrangeInputsIntoBoardData(boardInputs)
    local boardData = {}

    -- Create pages and lists structure
    local years_found = {}
    for _, board_input in ipairs(boardInputs) do
        local year, _ = board_input.name:match("^(%d%d%d%d)%-(%d%d)")
        if year then
            if not vim.tbl_contains(years_found, year) then
                table.insert(years_found, year)
            end
        end
    end

    for _, year in ipairs(years_found) do
        local page = {
            dataType = "page",
            title = year,
            lists = {},
        }
        for _, month_name in ipairs(months) do
            local list = {
                dataType = "list",
                title = month_name,
                items = {},
            }
            table.insert(page.lists, list)
        end

        table.insert(boardData, page)
    end


    -- Insert entries into the right page/list
    for _, board_input in ipairs(boardInputs) do
        local year, month = board_input.name:match("^(%d%d%d%d)%-(%d%d)")
        if not year or not month then
            goto continue
        end

        local board_entry = {
            dataType = "entry",
            title = board_input.name,
            filepath = board_input.path,
            content = {},
        }

        -- Find the page for this year
        local page
        for _, p in ipairs(boardData) do
            if p.title == year then
                page = p
                break
            end
        end

        -- Find the list for this month
        local month_name = mmToMonthString(month)
        local list
        for _, l in ipairs(page.lists) do
            if l.title == month_name then
                list = l
                break
            end
        end

        -- Add the entry to the right list
        table.insert(list.items, board_entry)

        ::continue::
    end

    return boardData
end

------------------------------------------------------------------------------------------------------------------------
-- Entry point: parse vault into a board
------------------------------------------------------------------------------------------------------------------------

--- Parse a vault folder and generate a  full board data structure (**year–month board**.)
---
--- Steps:
--- 1. Expand vault path
--- 2. Extracts the files that will serve as board inputs via parseVaultForBoardInputs
--- 3. Groups inputs into a paginated board
--- 4. Parse file contents for each entry
---
--- @param vault table { path: string, name: string }
--- @param user_commands table Additional user parser commands
--- @param boardConfig table { name:string, parser:string|function, viewlayout:string, subfolder:string, pattern:string }
---
--- @return table boardData The BoardDataStructure required by ViewLayouts
function M.parseBoard(vault, user_commands, boardConfig)
    local vaultRootPath = utils.expand_path(vault.path)

    local boardRawInputs = M.parseVaultForBoardInputs(vaultRootPath, user_commands, boardConfig)

    local boardData = M.arrangeInputsIntoBoardData(boardRawInputs)
    M.parseBoardDataEntriesForContent(boardData)

    return boardData
end

return M
