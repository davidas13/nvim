-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["kanso.nvim"],
}

-- ==== Setup =================================================================
--

require("kanso").setup {
    transparent = true,
    bold = true,
    italics = false,
    background = {
        dark = "ink",
    },
    foreground = "default",
    minimal = true,
}

vim.cmd [[colorscheme kanso]]
