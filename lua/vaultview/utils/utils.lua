
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local lfs = require("lfs")

local M = {}

function M.expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end
local function is_windows()
    return package.config:sub(1,1) == "\\"
end

--- list all entries recursively in a directory (no . or ..)
function M.scanDirRecursive(dir)
    -- print("[scanDirRecursive] Scanning directory:", dir)
  local t = {}
  local cmd
  if is_windows() then
    cmd = 'dir "'..dir..'" /b'
  else
    cmd = 'ls -1 "'..dir..'"'
  end
    -- print("[scanDirRecursive] Running command:", cmd)
  local p = io.popen(cmd)
  if p then
    for entry in p:lines() do
      if entry ~= "." and entry ~= ".." then
        table.insert(t, entry)
      end
    end
    p:close()
  end
  return t
end

function M.scandir(dir)
	local t = {}
	local p = io.popen('ls -1 "' .. dir .. '"')
	if not p then
		return t
	end
	for entry in p:lines() do
		table.insert(t, entry)
	end
	p:close()
	return t
end

function M.file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

--- Check if a file or directory exists in this path
function M.exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

--- Check if a directory exists in this path
function M.isdir(path)
   -- "/" works on both Unix and Windows
   return M.exists(path.."/")
end

function M.walk(dir, callback, callback_params)
    -- print("[walk] Scanning directory:", dir)
  for _, entry in ipairs(M.scanDirRecursive(dir)) do
    local path = dir .. "/" .. entry
    if M.isdir(path) then
      callback(path, true, callback_params)
      M.walk(path, callback, callback_params) -- recurse
    else
      callback(path, false, callback_params)
    end
  end
end

function M.SplitFilename(strFilename)
  -- Returns the Path, Filename, and Extension as 3 values
  if lfs.attributes(strFilename,"mode") == "directory" then
    local strPath = strFilename:gsub("[\\/]$","")
    return strPath.."\\","",""
  end
  strFilename = strFilename.."."
  return strFilename:match("^(.-)([^\\/]-%.([^\\/%.]-))%.?$")
end


return M
