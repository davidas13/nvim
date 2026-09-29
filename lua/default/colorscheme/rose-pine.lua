-- Intallation ------------------------------------------------------------- {{{
local specs = require "specs"

vim.pack.add {
    specs["rose-pine"],
}

-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("rose-pine").setup {
    -- dim_inactive_windows = true,
    -- extend_background_behind_borders = true,
}

vim.cmd [[colorscheme rose-pine-moon]]
-- }}}
