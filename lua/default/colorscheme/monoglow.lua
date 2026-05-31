-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["monoglow.nvim"],
}

-- ==== Setup =================================================================
--
require("monoglow").setup()

vim.cmd [[colorscheme monoglow-lack]]
