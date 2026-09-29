-- Intallation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["opencode.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------ {{{
require("opencode").setup {}
-- }}}
