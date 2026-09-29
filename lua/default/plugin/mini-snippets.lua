-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["mini.snippets"],
}
-- }}}

-- Setup {{{
require("mini.snippets").setup()
-- }}}
