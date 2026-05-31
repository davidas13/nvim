-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["grug-far.nvim"],
}

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set({ "n", "x" }, "<leader>sr", function()
    local ext = vim.bo.buftype == "" and vim.fn.expand "%:e"

    require("grug-far").open {
        transient = true,
        prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
        },
    }
end, { desc = "Search and Replace" })
