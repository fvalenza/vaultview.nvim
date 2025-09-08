
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local M = {}

-- local mixedTable = {
-- 	["01"] = "January",
-- 	["02"] = "February",
-- 	["10"] = "October",
-- 	["abc"] = "Alphabetic",
-- 	[5] = "Number key",
-- 	["1"] = "One",
-- }
--
-- for k, v in sortedPairs(mixedTable) do
--     print(k, v)
-- end
--
-- local sortedKeys = sortKeys(mixedTable)
-- for _, k in ipairs(sortedKeys) do
-- 	print(k, mixedTable[k])
-- end

function M.sortedPairs(t)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		-- Try to compare as numbers first
		local numA, numB = tonumber(a), tonumber(b)
		if numA and numB then
			return numA < numB
		elseif numA then
			return true -- numbers come before strings
		elseif numB then
			return false -- strings come after numbers
		else
			return tostring(a) < tostring(b) -- fallback to string comparison
		end
	end)
	local i = 0
	return function()
		i = i + 1
		return keys[i], t[keys[i]]
	end
end

function M.sortKeys(t)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		-- Try to compare as numbers first
		local numA, numB = tonumber(a), tonumber(b)
		if numA and numB then
			return numA < numB
		elseif numA then
			return true -- numbers come before strings
		elseif numB then
			return false -- strings come after numbers
		else
			return tostring(a) < tostring(b) -- fallback to string comparison
		end
	end)
	return keys
end
 
function M.remove_duplicates(arr)
  local seen = {}
  local result = {}
  for _, v in ipairs(arr) do
    if not seen[v] then
      seen[v] = true
      table.insert(result, v)
    end
  end
  return result
end

return M
