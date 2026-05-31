-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["plenary.nvim"],
    specs["snacks.nvim"],
    specs["marker-groups.nvim"],
}
-- }}}

-- Setup {{{
require("marker-groups").setup()
-- }}}
