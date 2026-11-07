-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["tabby.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("tabby").setup {
    line = require "default.plugin.tabby.line",
}

require "default.plugin.tabby.keymaps"
-- }}}
