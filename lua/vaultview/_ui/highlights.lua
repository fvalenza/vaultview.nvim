-- lua/myplugin/highlights.lua
local M = {}

-- Default highlight definitions (fallbacks)
M.defaults = {
    TabActive    = "Title",
    TabInactive  = "Comment",
    TabSeparator = { fg = "#5f5f5f" },
    PageActive   = "Title",
    PageInactive = "Normal",
    EntryWindowActive = {bg = "#303040"},
    EntryWindowInactive = {bg = "#202020"},
    TabHint      = "Comment",
}

--- Apply or link highlights
---@param user_hl table|nil user-defined overrides
function M.apply(user_hl)
    local merged = vim.tbl_deep_extend("force", {}, M.defaults, user_hl or {})

    for group, opts in pairs(merged) do
        if type(opts) == "table" then
            -- Normal definition: fg/bg/bold etc.
            vim.api.nvim_set_hl(0, group, opts)
        elseif type(opts) == "string" then
            -- Link to an existing group, e.g. "Identifier"
            vim.api.nvim_set_hl(0, group, { link = opts, default = false })
        end
    end

    return merged
end

return M
