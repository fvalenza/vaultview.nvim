

local A = require("vaultview.actions")

local function map(lhs, action)
    vim.keymap.set("n", lhs, A[action], { buffer = true, silent = true, noremap = true })
end

-- defaults
map("q", "Hide")
map("<S-h>", "PreviousPage")
map("<S-l>", "NextPage")
map("p", "PreviousBoard")
map("n", "NextBoard")
map("1", "Board1")
map("2", "Board2")
map("3", "Board3")
map("4", "Board4")
map("5", "Board5")
map("6", "Board6")
map("7", "Board7")
map("8", "Board8")
map("9", "Board9")
map("?", "Help")
