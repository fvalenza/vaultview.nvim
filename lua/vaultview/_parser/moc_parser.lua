if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local tutils = require("vaultview.utils.table_utils")
local utils = require("vaultview.utils.utils")


local function expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end

local M = {}

local function split_pattern(pattern)
	local dir, filepattern = pattern:match("^(.*)/(.*)$")
	-- if there was no "/" in pattern, dir is ".", filepattern is pattern
	if not dir then
		dir, filepattern = ".", pattern
	end
	return dir, filepattern
end

function M.parseDirForBoardInputs(dir, config)
	local boardData = {}
	local dir = dir
	local pattern = config.pattern
	local file_title = config.file_title

	-- Considering vault dir path given + parser pattern on "What to look for" inside the fault, adjust the final dir where to search and the pattern to match
	local patternDir, patternFile = split_pattern(pattern)
	-- if patternDir is not ".", we need to go into that subdir first
	if patternDir ~= "." then
		dir = dir .. "/" .. patternDir
		print("[MOC Parser] Adjusted directory to:", dir)
	end

	local cb = function(path, isDir, callback_params)
		print("[MOC Parser] Walking path:", path)
		local keep = false
		if isDir then
			print("[MOC Parser] It's a directory, skipping.")
			return
		else
			local fdir, fname, fext = utils.SplitFilename(path)
			-- local filename = path:match("([^/]+)$")
			print("[MOC Parser] It's a file.")
			print("[MOC Parser] Filename:", fname)

			-- Check if patternFile is in the form *.ext
			local patExt = patternFile:match("^%*%.(.+)$")
			if patExt then
				-- Just compare extensions directly
				if fext == patExt then
					print("[MOC Parser] Filename matches pattern:", callback_params.patternFile)
					local title = fname:gsub("%.md$", "")
					print("[MOC Parser] Initial title:", title)
					keep = true
					table.insert(callback_params.boardData, {
						date = "", -- no date here
						name = title,
						path = path,
					})
				end
			else
				-- Fallback: use Lua pattern matching
				if filename:match(patternFile) then
					print("[MOC Parser] Filename matches pattern:", callback_params.patternFile)
					local title = fname:gsub("%.md$", "")
					print("[MOC Parser] Initial title:", title)
					table.insert(callback_params.boardData, {
						date = "", -- no date here
						name = title,
						path = path,
					})
				else
					print("Pattern did not match:", filename)
				end
			end
		end
	end

	local callback_params = {
		patternFile = patternFile,
		file_title = file_title,
		boardData = boardData,
	}

	utils.walk(dir, cb, callback_params)

	return boardData
end

function M.arrangeBoardInputs(entries)
	return entries -- Do nothing, as recursive walking dirs shall have given already an alphabetically ordered table
end

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

function M.testwikilink_search(dir, name)
	print("MOC Parser test function")

	local results = search_wikilink(dir, name)
	local unique_results = tutils.remove_duplicates(results)
	for _, line in ipairs(unique_results) do
		print(line)
	end
end

function M.findContentInEntryFile(path)
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
			print("[MarkdownParser] Excalidraw section found, stopping parsing.")
			break -- Exit the loop entirely
		end

		table.insert(result.lines, line)
		local heading = line:match("^##%s+(.+)$") -- Match only level 2 headings
		if heading then
			print("[MarkdownParser] Found level 2 heading:", heading)
			table.insert(result.headings, heading)
		end
	end

	print("[MarkdownParser] Done parsing file. Found " .. #result.headings .. " level 2 headings.")
	return result
end

function M.parseInputs(inputs, vaultDir)
	local results = {}

	-- foreach moc
	for _, mocEntry in ipairs(inputs) do
		print("MOC Entry:", mocEntry.name, "Path:", mocEntry.path)
		local resEntry = {}
		resEntry.title = mocEntry.name
		resEntry.content = {}

		-- find backlinks to this mocEntry.name
		local notesBacklinking = search_wikilink(vaultDir, mocEntry.name)
		local unique_results = tutils.remove_duplicates(notesBacklinking)
		for _, line in ipairs(unique_results) do
			print(line)
			table.insert(resEntry.content, line)
		end
		table.insert(results, resEntry)
	end

	return results
end

function M.parseBoard(vault, boardConfig)
    local vaultRootPath = expand_path(vault.path)
    local boardMocInputs = M.parseDirForBoardInputs(vaultRootPath, boardConfig)

    local boardParsedMocInputs = M.parseInputs(boardMocInputs, vaultRootPath)
    -- tutils.printTable(boardParsedInputs, "boardParsedInputs")
    print("Final parsed board inputs:")
    print(vim.inspect(boardParsedMocInputs))

    return boardParsedMocInputs
end

function M.printBoardData(data)
	print("BoardData: ")
	for k, v in tutils.sortedPairs(data) do
		print('["', k, '"] = {')
		--print the v.title and then the v.lists (is a table)
		print("\ttitle:", v.title)
		print("\tlists: {")

		-- for _, vlist in tutils.sortedPairs(v.lists) do
		for _, vlist in ipairs(v.lists) do
			print("\t\t{")
			print("\t\t\ttitle:", vlist.title)
			print("\t\t\titems: {")
			for _, item in ipairs(vlist.items) do
				print("\t\t\t\t{")
				print("\t\t\t\t\ttitle:", item.title)
				print("\t\t\t\t\tcontent: {")
				for _, line in ipairs(item.content) do
					print("\t\t\t\t\t\t" .. line)
				end
				print("\t\t\t\t\t} -- content")
				print("\t\t\t\t} -- item")
			end
			print("\t\t\t} -- items")
			print("\t\t} -- list")
		end

		print("\t} -- lists")
		print("} -- page")
	end
end

return M
