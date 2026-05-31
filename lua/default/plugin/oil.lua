-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["oil.nvim"],
}

-- ==== Setup =================================================================
--
require("oil").setup {
    delete_to_trash = true,
    float = {
        max_width = 0.9,
    },
}

-- ==== Setup Keybindings =====================================================
--
