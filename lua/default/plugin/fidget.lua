-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["fidget.nvim"],
}
-- }}}

-- Setup {{{
require("fidget").setup()
-- }}}
