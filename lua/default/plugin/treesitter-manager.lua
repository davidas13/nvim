-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["tree-sitter-manager.nvim"],
}
-- }}}

-- Setup {{{
require("tree-sitter-manager").setup {}
-- }}}
