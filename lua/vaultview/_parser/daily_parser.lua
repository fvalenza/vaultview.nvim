
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


--
-- A parser takes from a directory a set of files respecting a certain pattern (daily_parser.lua takes yyyy-mm-dd/yyyy-mm-dd.md files, moc_files takes all files in 1-MOCc/ folder)
--

-- TODO pour le parseDirForBoardInput ca peut etre soit regex nom de fichier, soit nom de dossier et tout prendre dedans, etc, trouver une configuration qui permet tout ca
local M = {}

--- Parses a directory for daily markdown files names as yyyy-mm-dd (obsidian note folder makes them stored in yyyy-mm-dd/yyyy-mm-dd.md by the way)
---@param dir string directory path
---@return table array of {date=yyyy-mm-dd, name=..., path=...}
function M.parseDirForBoardInputs(dir)
	local boardData = {}
	for _, name in ipairs(utils.scandir(dir)) do
		if name:match("^%d%d%d%d%-%d%d%-%d%d$") then
			local subdir_path = dir .. "/" .. name
			local file_path = subdir_path .. "/" .. name .. ".md"
			if utils.file_exists(file_path) then
				table.insert(boardData, {
					date = name,
					name = name,
					path = file_path,
				})
			end
		end
	end
	return boardData
end

function M.arrangeBoardInputs(entries)
	-- entries is a flat array of {date=yyyy-mm-dd, name=..., path=...}
	-- we want to group them by year and month
	local grouped = {}

	for _, item in ipairs(entries) do
		-- extract yyyy and mm
		local year, month = item.date:match("^(%d%d%d%d)%-(%d%d)")

		if year and month then
			-- initialize year if missing
			if not grouped[year] then
				grouped[year] = {}
			end
			-- initialize month if missing
			if not grouped[year][month] then
				grouped[year][month] = {}
			end
			-- insert item into year->month
			table.insert(grouped[year][month], item)
		end
	end

	-- Now ensure all months (01 → 12) exist
	for year, months in pairs(grouped) do
		for m = 1, 12 do
			local mm = string.format("%02d", m)
			if not months[mm] then
				months[mm] = {}
			end
		end
	end
	return grouped
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

function M.parseInputs(inputs)
	local results = {}

	-- foreach page
	for key_page, val_page in tutils.sortedPairs(inputs) do
		print("Key:", key_page, "Value:", val_page)
		local resPage = {}
		resPage.title = key_page
        resPage.dataType = "page"
		resPage.lists = {}

		-- for each category
		for key_category, val_category in tutils.sortedPairs(val_page) do
			print("  Category:", key_category)
			local resCategory = {}
			resCategory.title = key_category
            resCategory.dataType = "list"
			resCategory.items = {}

			for _, entry in ipairs(val_category) do
				print("    Entry:", entry.name, "Path:", entry.path)
				local resEntry = {}
				resEntry.title = entry.name
                resEntry.dataType = "entry"
				resEntry.content = {}
				local expanded_path = expand_path(entry.path)
				local entryContent = M.findContentInEntryFile(expanded_path)
				if entryContent then
					for _, line in ipairs(entryContent.headings) do
						table.insert(resEntry.content, "- " .. line)
					end
				else
					resEntry.content = { "- (No items found in Todo)" }
				end
				table.insert(resCategory.items, resEntry)
			end

			-- resPage[key_category] = resCategory
			table.insert(resPage.lists, resCategory)
		end

		-- results[key_page] = resPage
		table.insert(results, resPage)
	end

	return results
end

function M.parseBoard(vault, boardConfig)

    local dailyDirPath = utils.expand_path(vault.path .. "/" .. boardConfig.daily_notes_folder)
    local boardRawInputs = M.parseDirForBoardInputs(dailyDirPath) -- shall take board config to know what to looking for
    -- printTable(boardRawInputs, "boardRawInputs")
    local boardArrangedInputs = M.arrangeBoardInputs(boardRawInputs) -- shall take board config to know how to arrange (category/entry)
    -- printTable(boardArrangedInputs, "boardArrangedInputs")
    local boardParsedInputs = M.parseInputs(boardArrangedInputs) -- shall take board config to know how to parse (which headings, etc)
    -- printTable(boardParsedInputs, "boardParsedInputs")

    return boardParsedInputs
end

function M.printBoardData(data)
	print("BoardData: ")
	for k, v in tutils.sortedPairs(data) do
		print('[\"',k,'\"] = {')
		--print the v.title and then the v.lists (is a table)
        print("\tdataType:", v.dataType)
		print("\ttitle:", v.title)
		print("\tlists: {")

		-- for _, vlist in tutils.sortedPairs(v.lists) do
		for _, vlist in ipairs(v.lists) do
            print("\t\t{")
            print("\t\t\tdataType:", vlist.dataType)
            print("\t\t\ttitle:", vlist.title)
            print("\t\t\titems: {")
            for _, item in ipairs(vlist.items) do
                print("\t\t\t\t{")
                print("\t\t\t\t\tdataType:", item.dataType)
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
