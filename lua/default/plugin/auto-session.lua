-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add { specs["auto-session"] }
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("auto-session").setup {
    suppressed_dirs = { "~/", "~/Desktop", "~/Documents", "~/Downloads", "/", "~/.config" },
}
-- }}}
