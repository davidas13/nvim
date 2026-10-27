-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["marks.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("marks").setup {}
-- }}}
