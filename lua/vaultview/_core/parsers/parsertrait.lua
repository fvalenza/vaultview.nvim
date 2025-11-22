---
--- ParserTrait: Mixin/trait for parsing vault files into board data structures.
--- Provides methods for:
---   1. Selecting input files to build board pages/lists (parseVaultForBoardInputs)
---   2. Extracting content from entry files (findContentInEntryFile)
---   3. Populating board entries with parsed content (parseBoardDataEntriesForContent)
---
--- The functions of this trait is intended to be applied to other parsers to provide them default implementation.
--- These parsers can also overwrite them if necessary
---
---
--- @module ParserTrait
---
local ParserTrait = {}

local utils = require("vaultview._core.utils.utils")

-----------------------------------------------------------------------------------------------------
--
-- Input Selection = get the files to be used as board inputs by the parser to build the board data
--
-----------------------------------------------------------------------------------------------------
local input_selectors = {
    ["*"] = [[find %q -type f | sort ]],
    ["*.md"] = [[find %q -type f -name '*.md' | sort ]],
    ["yyyy-mm-dd.md"] = [[find %q -type f | sort | grep -E '/[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\.md$']],
}

--- Merge user-defined input selectors with defaults
--- @param user_selectors table? User-defined input selectors
--- @return table Merged input selectors
local function merge_input_selectors(user_selectors)
    local merged = vim.deepcopy(input_selectors)
    if type(user_selectors) == "table" then
        for k, v in pairs(user_selectors) do
            merged[k] = v
        end
    end
    return merged
end

--- Parse vault directory to get the list of files to use as board inputs
--- @param base_dir string Base vault directory path
--- @param custom_selectors table Table of user-defined input/content selectors -- TODO(roadmap): merge table in configuraiton.lua
--- @param board_config table Configuration for the board (input_selector, subfolder, etc.)
--- @return table[] List of board input objects: { name = string, path = string }
function ParserTrait.parseVaultForBoardInputs(base_dir, custom_selectors, board_config)
    local boardData = {}

    -- Build the directory in which to look for files
    local subdir = board_config.subfolder or ""
    local target_dir = base_dir
    if subdir and subdir ~= "" and subdir ~= "." then
        target_dir = base_dir .. "/" .. subdir
    end

    -- Retrieve the input_selector wanted (from configuration of the board) between the user-defined ones and default ones
    local find_commands = merge_input_selectors(custom_selectors.input_selectors)
    local mode = board_config.input_selector or "all_md"
    local selector = find_commands[mode]

    if not selector then
        error("Unknown input_selector mode: " .. tostring(mode))
        return boardData
    end

    local board_input_files

    -- Case 1: string (shell command)
    if type(selector) == "string" then
        local cmd = string.format(selector, target_dir)
        board_input_files = vim.fn.systemlist(cmd)

    -- Case 2: lua function(target_dir) -> list of files
    elseif type(selector) == "function" then
        local ok, result = pcall(selector, target_dir)
        if not ok then
            error("Error executing input_selector function for mode '" .. mode .. "': " .. tostring(result))
        end
        if type(result) ~= "table" then
            error("Function selector for mode '" .. mode .. "' must return a table, got " .. type(result))
        end
        board_input_files = result

    -- Case 3: List of files directly
    elseif type(selector) == "table" then
        board_input_files = selector

    else
        error("Invalid input_selector type for mode '" .. mode .. "': " .. type(selector))
    end

    -- Get interesting stuff needed by the parser to build the board data
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
local content_selectors = {
    headings = [=[grep -E '^#+[[:space:]]+.+' %q | sed -E 's/^#+[[:space:]]+//' ]=],
    h1 = [=[grep -E '^#[[:space:]]+.+' %q | sed -E 's/^#[[:space:]]+//' ]=],
    h2 = [=[grep -E '^##[[:space:]]+.+' %q | sed -E 's/^##[[:space:]]+//' ]=],
    h3 = [=[grep -E '^###[[:space:]]+.+' %q | sed -E 's/^###[[:space:]]+//' ]=],
    h4 = [=[grep -E '^####[[:space:]]+.+' %q | sed -E 's/^####[[:space:]]+//' ]=],
    h2_awk_noexcalidraw = [=[awk '/^# Excalidraw Data/ { exit } /^##[[:space:]]+.+/ { sub(/^##[[:space:]]+/, ""); print }' %q]=],
    h2_rg_noexcalidraw = [=[rg --until-pattern '^# Excalidraw Data' '^##[[:space:]]+.+$' %q | sed -E 's/^##[[:space:]]+//' ]=],
    uncompleted_tasks = [=[grep -E '^\s*-\s*\[ \]' %q | sed -E 's/^\s*-\s*\[ \]\s*//' ]=], -- TODO test
    completed_tasks = [=[grep -E '^\s*-\s*\[x\]' %q | sed -E 's/^\s*-\s*\[x\]\s*//' ]=], -- TODO test
    tasks = [=[grep -E '^\s*-\s*\[[ x]\]' %q | sed -E 's/^\s*-\s*\[[ x]\]\s*//' ]=], -- TODO test
}

--- Merge user-defined content selectors with defaults
--- @param user_selectors table? User-defined content selectors
--- @return table Merged content selectors
local function merge_content_selectors(user_selectors)
    local merged = vim.deepcopy(content_selectors)
    if type(user_selectors) == "table" then
        for k, v in pairs(user_selectors) do
            merged[k] = v
        end
    end
    return merged
end

--- Extract content lines from a file
--- @param path string File path
--- @param custom_selectors table? User-defined commands (input + content selectors)
--- @param boardConfig table? Board configuration (content_selector)
--- @return string[] Lines of content
function ParserTrait.findContentInEntryFile(path, custom_selectors, boardConfig)
    custom_selectors = custom_selectors or {}
    boardConfig = boardConfig or {}

    -- Retrieve the grep command template between the user-defined and default ones
    local grep_commands = merge_content_selectors(custom_selectors.content_selectors) -- TODO(roadmap) when merge at plugin loading, no need to merge again so to remove here
    local mode = boardConfig.content_selector or "h2_awk_noexcalidraw" -- default to awk version
    local template = grep_commands[mode]

    if not template then
        error("Unknown content_selector: " .. tostring(mode))
    end

    -- Build and run the shell command
    local cmd = string.format(template, path)
    local lines = vim.fn.systemlist(cmd)

    -- if #lines == 0 then
    --     table.insert(lines, "(No items found)")
    -- end

    return lines
end

--- Populate all entries in boardData with content from their files
--- @param boardData table Board data structure: pages → lists → entries
function ParserTrait.parseBoardDataEntriesForContent(boardData)
    for _, page in ipairs(boardData) do
        for _, list in ipairs(page.lists) do
            for _, entry in ipairs(list.items) do
                local expanded_path = utils.expand_path(entry.filepath)
                local entryContent = ParserTrait.findContentInEntryFile(expanded_path)
                    for _, line in ipairs(entryContent) do
                        table.insert(entry.content, "- " .. line)
                    end
            end
        end
    end
end

return ParserTrait
