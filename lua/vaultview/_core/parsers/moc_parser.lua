if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local layouts = require("vaultview._core.view.layouts")
local tutils = require("vaultview._core.utils.table_utils")
local utils = require("vaultview._core.utils.utils")
local Constants = require("vaultview._ui.constants")

local M = {}

--- Parse a single ripgrep line into its components.
---
--- Expected format: `filepath:line:column:match`
---
--- NOTE: For now, only the filepath is returned.
---
--- @param line string A line of ripgrep output
--- @return string filepath The extracted file path
local function parse_rg_line(line)
    -- match: (filepath):(line):(col):(rest of line)
    local filepath, lnum, col, rgmatch = line:match("^(.-):(%d+):(%d+):(.*)$")
    return filepath
    -- return {
    --   filepath = filepath,
    --   line = tonumber(lnum),
    --   col = tonumber(col),
    --   rgmatch = rgmatch,
    -- }
end

--- Search for a wiki link (`[[name]]`) inside a directory using ripgrep.
---
--- @param dir string The directory where ripgrep should search
--- @param name string The wikilink target name (without surrounding brackets)
--- @return string[] results A list of filepaths that contain the wikilink
local function search_wikilink(dir, name)
    -- escape [ and ] for rg (Lua pattern -> literal)
    local pattern = "\\[\\[" .. name .. "\\]\\]" -- e.g. [[MyNote]]

    -- wrap in quotes for shell safety
    local cmd = string.format(
        'rg --no-config --type=md --no-heading --with-filename --line-number --column "%s" "%s"',
        pattern,
        dir
    )

    local handle = io.popen(cmd)
    if not handle then
        callback({})
        return
    end

    local results = {}
    for line in handle:lines() do
        -- table.insert(results, line)
        table.insert(results, parse_rg_line(line))
    end
    handle:close()

    return results
end

------------------------------------------------------------------------------------------------------------------------
-- Board construction
------------------------------------------------------------------------------------------------------------------------

--- Transform raw board inputs into structured multi-page board data.
---
--- The editor width determines how many lists fit on one page hence splits into multiple pages if needed.
---
--- @param boardInputs table[] Raw items parsed from the vault
--- @param boardConfig table Board configuration (contains viewlayout, parser type, etc)
--- @param vaultRootPath string Absolute path to the root of the vault
--- @return table boardData A multi-page board structure groupd alphabetically into pages/ lists(moc-files)/entries(files linking to moc)
function M.arrangeInputsIntoBoardData(boardInputs, boardConfig, vaultRootPath)
    local boardData = {}

    local totalAvailableWidth = vim.o.columns
    local viewlayoutType = type(boardConfig.viewlayout) == "string" and layouts[boardConfig.viewlayout].name()
    local listWinWidth = Constants.list_win[viewlayoutType].width or 32
    local paddingBetWeenLists = 2
    local maxNumberOfListsPerPage = math.max(1, math.floor(totalAvailableWidth / (listWinWidth + paddingBetWeenLists)))
    local totalInputs = #boardInputs
    local numPages = math.ceil(totalInputs / maxNumberOfListsPerPage)

    for pageIndex = 1, numPages do
        local page = {
            dataType = "page",
            title = "MOC Page" .. pageIndex,
            lists = {},
        }

        -- Compute the slice range for this page
        local startIdx = (pageIndex - 1) * maxNumberOfListsPerPage + 1
        local endIdx = math.min(startIdx + maxNumberOfListsPerPage - 1, totalInputs)

        -- Fill lists for this page
        for i = startIdx, endIdx do
            local board_input = boardInputs[i]
            local list = {
                dataType = "list",
                title = board_input.name,
                filepath = board_input.path,
                items = {},
            }

            -- find backlinks to this moc
            local notesBacklinking = search_wikilink(vaultRootPath, board_input.name)
            local unique_results = tutils.remove_duplicates(notesBacklinking)

            -- Sort wikilinks by filename before parsing them (using utils.SplitFilename)
            table.sort(unique_results, function(a, b)
                local _, afname = utils.SplitFilename(a)
                local _, bfname = utils.SplitFilename(b)
                return (afname or ""):lower() < (bfname or ""):lower()
            end)

            for _, wikilink in ipairs(unique_results) do
                local wikilink_fdir, wikilink_fname, wikilink_fext = utils.SplitFilename(wikilink)
                local item = {
                    dataType = "entry",
                    title = wikilink_fname,
                    filepath = wikilink,
                    content = {},
                }
                table.insert(list.items, item)
            end

            table.insert(page.lists, list)
        end

        -- Override page title based on first letters of first and last list
        if #page.lists > 0 then
            local firstLetter = (page.lists[1].title:sub(1, 1) or ""):lower()
            local lastLetter = (page.lists[#page.lists].title:sub(1, 1) or ""):lower()
            page.title = string.format("[%s - %s]", firstLetter, lastLetter)
        else
            page.title = "[empty]"
        end
        table.insert(boardData, page)
    end

    return boardData
end

------------------------------------------------------------------------------------------------------------------------
-- Board Parsing Entry Point
------------------------------------------------------------------------------------------------------------------------

--- Parse a vault folder and generate a full board data structure.
---
--- This function:
--- 1. Expands the vault path
--- 2. Extracts the files that will serve as board inputs via parseVaultForBoardInputs
--- 3. Groups inputs into a paginated board
--- 4. Parses the content for each entry of the paginatd board data
---
--- @param vault table { path: string, name: string }
--- @param boardConfig table { name: string, parser: string|function, viewlayout: string, subfolder: string, pattern: string }
---
--- @return table boardData Fully structured board data compatible with all ViewLayouts
function M.parseBoard(vault, boardConfig)
    local vaultRootPath = utils.expand_path(vault.path)

    local boardRawInputs = M.parseVaultForBoardInputs(vaultRootPath, boardConfig)

    local boardData = M.arrangeInputsIntoBoardData(boardRawInputs, boardConfig, vaultRootPath)
    M.parseBoardDataEntriesForContent(boardData, boardConfig)

    return boardData

end

return M
