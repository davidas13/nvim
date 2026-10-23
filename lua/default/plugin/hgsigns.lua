-- Intallation ------------------------------------------------------------- {{{
local specs = require "specs"

vim.pack.add {
    specs["hgsigns.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("hgsigns").setup {
    -- config options, see below
}
-- }}}
