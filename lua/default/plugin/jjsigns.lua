-- Intallation ------------------------------------------------------------- {{{
local specs = require "specs"

vim.pack.add {
    specs["jjsigns.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("jjsigns").setup {
    -- config options, see below
}
-- }}}
