local ParserTrait = {}

local utils = require("vaultview._core.utils.utils")

local filepattern = {
    ["yyyy-mm-dd"] = "^%d%d%d%d%-%d%d%-%d%d%.md$",
    ["*"] = ".*%.md$",
}

function ParserTrait.parseVaultForBoardInputs(base_dir, config)
    local boardData = {}

    -- Build the directory in which to look for files
    local target_dir = base_dir
    local subdir = config.subfolder or ""
    if subdir and subdir ~= "" and subdir ~= "." then
        target_dir = base_dir .. "/" .. subdir
    end

    local pattern = filepattern[config.pattern] or filepattern["*"]
    dprint("Parsing directory with pattern:", pattern)

    -- Get all markdown files in the target directory recursively
    local scanned = utils.scandir_recursive_markdown(target_dir)
    dprint("Scanned entries in target dir:", scanned)

    -- Filter files matching the pattern
    for _, path in ipairs(scanned) do
        local fdir, fname, fext = utils.SplitPath(path)
        dprint("Checking file:", path, "Dir:", fdir, "Name:", fname, "Ext:", fext)
        if fname:match(pattern) then
            local filename_no_ext = fname:gsub("%." .. fext .. "$", "")
            table.insert(boardData, {
                name = filename_no_ext,
                path = path,
            })
        end
    end

    dprint("Parsed directory for board inputs:")
    dprint(boardData)

    return boardData
end

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
