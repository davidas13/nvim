-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["defold.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("defold").setup {
    -- config options, see below
}
-- }}}
