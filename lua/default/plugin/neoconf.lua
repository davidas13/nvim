-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["neoconf.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("neoconf").setup()
-- }}}
