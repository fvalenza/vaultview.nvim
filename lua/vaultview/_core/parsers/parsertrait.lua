local ParserTrait = {}

local utils = require("vaultview._core.utils.utils")

-----------------------------------------------------------------------------------------------------
--
-- Input Selection = get the files to be used as board inputs by the parser to build the board data
--
-----------------------------------------------------------------------------------------------------
local input_selectors = {
    all_files = [[find %q -type f | sort ]],
    all_md = [[find %q -type f -name '*.md' | sort ]],
    ["yyyy-mm-dd_md"] = [[find %q -type f | sort | grep -E '/[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\.md$']],
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

    -- Retrieve the input_selector wanted (from configuration of the board) between the user-defined ones and default ones
    local find_commands = merge_input_selectors(user_commands.input_selectors)
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
    all_headings = [=[grep -E '^#+[[:space:]]+.+' %q | sed -E 's/^#+[[:space:]]+//' ]=],
    lvl2headings_noexcalidraw_awk = [=[awk '/^# Excalidraw Data/ { exit } /^##[[:space:]]+.+/ { sub(/^##[[:space:]]+/, ""); print }' %q]=],
    lvl2headings_noexcalidraw_rg = [=[rg --until-pattern '^# Excalidraw Data' '^##[[:space:]]+.+$' %q | sed -E 's/^##[[:space:]]+//' ]=],
    uncompleted_tasks = [=[grep -E '^\s*-\s*\[ \]' %q | sed -E 's/^\s*-\s*\[ \]\s*//' ]=], -- TODO test
    completed_tasks = [=[grep -E '^\s*-\s*\[x\]' %q | sed -E 's/^\s*-\s*\[x\]\s*//' ]=], -- TODO test
    tasks = [=[grep -E '^\s*-\s*\[[ x]\]' %q | sed -E 's/^\s*-\s*\[[ x]\]\s*//' ]=], -- TODO test
}

-- Merge user-defined grep commands with defaults
local function merge_content_selectors(user_selectors)
    local merged = vim.deepcopy(content_selectors)
    if type(user_selectors) == "table" then
        for k, v in pairs(user_selectors) do
            merged[k] = v
        end
    end
    return merged
end

function ParserTrait.findContentInEntryFile(path, user_commands, config)
    user_commands = user_commands or {}
    config = config or {}

    -- Retrieve the grep command template between the user-defined and default ones
    local grep_commands = merge_content_selectors(user_commands.content_selectors)
    local mode = config.input_selector or "lvl2headings_noexcalidraw_awk" -- default to awk version
    local template = grep_commands[mode]

    if not template then
        error("Unknown input_selector: " .. tostring(mode))
    end

    -- Build and run the shell command
    local cmd = string.format(template, path)
    local lines = vim.fn.systemlist(cmd)

    -- if #lines == 0 then
    --     table.insert(lines, "(No items found)")
    -- end

    return lines
end

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
    -- dprint("Parsed board data entries for content.")
    -- dprint(boardData)
end

return ParserTrait
