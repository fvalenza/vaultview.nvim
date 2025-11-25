local M = {}

M.debug_print = function(...)
    local args = { ... }
    local raw_debug_console = require("vaultview").opts.logging.raw_debug_console
    if not raw_debug_console then
        return
    end
    vim.schedule(function()
        for _, v in ipairs(args) do
            vim.print(v)
        end
    end)
end

return M.debug_print
