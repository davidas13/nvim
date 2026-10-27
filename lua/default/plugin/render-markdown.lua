-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["render-markdown.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("render-markdown").setup {}
-- }}}
