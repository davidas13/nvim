-- Intallation ------------------------------------------------------------- {{{
local specs = require "specs"

vim.pack.add {
    specs["everforest-nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("everforest").setup {
    background = "hard",
    transparent_background_level = 2,
}
-- }}}

-- Implementation ---------------------------------------------------------- {{{
vim.cmd [[colorscheme everforest]]
-- }}}
