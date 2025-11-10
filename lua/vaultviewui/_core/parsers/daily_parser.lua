if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tutils = require("vaultviewui._core.utils.table_utils")
local utils = require("vaultviewui._core.utils.utils")

-- TODO pour le parseDirForBoardInput ca peut etre soit regex nom de fichier, soit nom de dossier et tout prendre dedans, etc, trouver une configuration qui permet tout ca
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

local function mmToMonthString(month)
    return monthsMap[month] or month
end

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


--- parse a vault folder to create a board data structure depending on the board configuration
---@param vault configuration of the vault {path: string, name: string}
---@param boardConfig configuration of the board {name:string, parser: string|function, viewlayout: string, subfolder: string, pattern: string}
---@return The BoardDataStructure as expected by a ViewLayout
function M.parseBoard(vault, user_commands, boardConfig)
    local vaultRootPath = utils.expand_path(vault.path)

    local boardRawInputs = M.parseVaultForBoardInputs(vaultRootPath, user_commands, boardConfig)

    local boardData = M.arrangeInputsIntoBoardData(boardRawInputs)
    M.parseBoardDataEntriesForContent(boardData)

    return boardData
end

return M
