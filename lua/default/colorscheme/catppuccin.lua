-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["catppuccin.nvim"],
}

-- ==== Setup =================================================================
--
vim.cmd [[colorscheme catppuccin]]
