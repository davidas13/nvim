-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["vague.nvim"],
}

-- ==== Setup =================================================================
--
require("vague").setup()

vim.cmd [[colorscheme vague]]
