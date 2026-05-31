-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["diffview.nvim"],
}

-- ==== Setup =================================================================
--
require("diffview").setup()
