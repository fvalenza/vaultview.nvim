local ParserTrait = {}

local utils = require("vaultview._core.utils.utils")

-----------------------------------------------------------------------------------------------------
--
-- Input Selection = get the files to be used as board inputs by the parser to build the board data
--
-----------------------------------------------------------------------------------------------------
local input_selectors = {
    all_files = [[find %q -type f]],
    all_md = [[find %q -type f -name '*.md']],
    ["yyyy-mm-dd_md"] = [[find %q -type f | grep -E '/[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\.md$']],
}

-- Merge user-defined find commands with defaults
local function merge_input_selectors(user_selectors)
    local merged = vim.deepcopy(input_selectors)
    if type(user_selectors) == "table" then
        for k, v in pairs(user_selectors) do
            merged[k] = v
        end
    end
    return merged
end

function ParserTrait.parseVaultForBoardInputs(base_dir, user_commands, board_config)
    local boardData = {}

    -- Build the directory in which to look for files
    local subdir = board_config.subfolder or ""
    local target_dir = base_dir
    if subdir and subdir ~= "" and subdir ~= "." then
        target_dir = base_dir .. "/" .. subdir
    end

    local input_selectors_augmented = merge_input_selectors(user_commands.input_selectors)
    local mode = user_commands.input_selector or "all_md"
    local template = input_selectors_augmented[mode] -- the find command to be formatted with path where to search

    if not template then
        error("Unknown find_mode: " .. tostring(mode))
        return boardData
    end

    -- Build the real shell command
    local cmd = string.format(template, target_dir)

    local board_input_files = vim.fn.systemlist(cmd)

    for _, path in ipairs(board_input_files) do
        local _, fname, fext = utils.SplitPath(path)
        local filename_no_ext = fname:gsub("%." .. fext .. "$", "")
        table.insert(boardData, {
            name = filename_no_ext,
            path = path,
        })
    end

    return boardData
end

------------------------------------------------------------------------------------------------------------
--
-- Content selection = get the content(lines) to display in the card associated to each entry (within lists)
--
------------------------------------------------------------------------------------------------------------
function ParserTrait.findContentInEntryFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Could not open file: " .. path
    end

    local content = file:read("*all")
    file:close()

    local result = {}
    result.path = path
    result.content = content
    result.lines = {}
    result.headings = {} -- Store cleaned level 2 headings here

    -- local in_metadata = false

    for line in content:gmatch("[^\n]+") do
        if line:match("^#%s*Excalidraw Data") then
            -- in_metadata = true
            dprint("[MarkdownParser] Excalidraw section found, stopping parsing.")
            break -- Exit the loop entirely
        end

        table.insert(result.lines, line)
        local heading = line:match("^##%s+(.+)$") -- Match only level 2 headings
        if heading then
            dprint("[MarkdownParser] Found level 2 heading:", heading)
            table.insert(result.headings, heading)
        end
    end

    dprint("[MarkdownParser] Done parsing file. Found " .. #result.headings .. " level 2 headings.")
    return result
end

function ParserTrait.parseBoardDataEntriesForContent(boardData)
    for _, page in ipairs(boardData) do
        for _, list in ipairs(page.lists) do
            for _, entry in ipairs(list.items) do
                local expanded_path = utils.expand_path(entry.filepath)
                local entryContent = ParserTrait.findContentInEntryFile(expanded_path)
                if entryContent then
                    for _, line in ipairs(entryContent.headings) do
                        table.insert(entry.content, "- " .. line)
                    end
                else
                    entry.content = { "- (No items found in Todo)" }
                end
            end
        end
    end
    dprint("Parsed board data entries for content.")
    dprint(boardData)
end

return ParserTrait
