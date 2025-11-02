if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local layouts = require("vaultview._core.viewlayouts")
local tutils = require("vaultview._core.utils.table_utils")
local utils = require("vaultview._core.utils.utils")
local Constants = require("vaultview._ui.constants")

local M = {}

-- parse rg line into filepath, line, col, match
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

-- search for wikilink of a given name
local function search_wikilink(dir, name)
    -- escape [ and ] for rg (Lua pattern -> literal)
    local pattern = "\\[\\[" .. name .. "\\]\\]" -- e.g. [[MyNote]]
    -- wrap in quotes for shell safety
    local cmd = string.format(
        'rg --no-config --type=md --no-heading --with-filename --line-number --column "%s" "%s"',
        pattern,
        dir
    )

    print("Executing command:", cmd)

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

            -- necessary ??
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

function M.parseBoard(vault, boardConfig)
    local vaultRootPath = utils.expand_path(vault.path)

    local boardRawInputs = M.parseVaultForBoardInputs(vaultRootPath, boardConfig)

    local boardData = M.arrangeInputsIntoBoardData(boardRawInputs, boardConfig, vaultRootPath)
    M.parseBoardDataEntriesForContent(boardData)

    return boardData

end

return M
