
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

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
  local t = {}
  local cmd
  if is_windows() then
    cmd = 'dir "'..dir..'" /b'
  else
    cmd = 'ls -1 "'..dir..'"'
  end

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


local uv = vim.loop  -- works in Neovim; use luv for standalone Lua

function M.scandir_recursive(dir, results)
    results = results or {}

    local fd = uv.fs_scandir(dir)
    if not fd then
        return results
    end

    while true do
        local name, type = uv.fs_scandir_next(fd)
        if not name then break end

        local fullpath = dir .. "/" .. name

        if type == "directory" then
            -- Recurse into subdirectories
            M.scandir_recursive(fullpath, results)
        else
            table.insert(results, fullpath)
        end
    end

    return results
end

function M.scandir_recursive_markdown(dir, results)
    results = results or {}

    local fd = uv.fs_scandir(dir)
    if not fd then
        return results
    end

    while true do
        local name, type = uv.fs_scandir_next(fd)
        if not name then break end

        local fullpath = dir .. "/" .. name

        if type == "directory" then
            -- Recurse into subdirectories
            M.scandir_recursive_markdown(fullpath, results)
        else
            local _, _, ext = M.SplitPath(name)
            if ext == "md" then
                table.insert(results, fullpath)
            end
        end
    end

    return results
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

local function is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

function M.SplitPath(strFilename)
  -- Returns the Path, Filename, and Extension as 3 values
  if is_dir(strFilename) then
    local strPath = strFilename:gsub("[\\/]$","")
    return strPath.."\\","",""
  end
  strFilename = strFilename.."."
  return strFilename:match("^(.-)([^\\/]-%.([^\\/%.]-))%.?$")
end

M.SplitFilename = M.SplitPath


return M
