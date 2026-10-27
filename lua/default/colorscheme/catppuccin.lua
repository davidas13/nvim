-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["catppuccin"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("catppuccin").setup {
    auto_integrations = true,
}
-- }}}

-- Implementation ---------------------------------------------------------- {{{
vim.cmd [[colorscheme catppuccin-nvim]]
-- }}}
