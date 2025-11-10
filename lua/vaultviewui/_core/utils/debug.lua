local M = {}

M.debug_print = function(...)
  local args = { ... }
  vim.schedule(function()
    for _, v in ipairs(args) do
      vim.print(v)
    end
  end)
end

return M.debug_print
