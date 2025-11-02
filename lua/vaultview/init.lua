--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local configuration = require("vaultview._core.configuration")

local M = {}

configuration.initialize_data_if_needed()

-- TODO: (you) - Change this file to whatever you need. These are just examples


--- [TODO:description]
function M.run_toggle_vaultview()
    local runner = require("vaultview._commands.open.runner")

    runner.run_toggle()
end


return M
