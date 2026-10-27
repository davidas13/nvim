-- Skip outside a Jujutsu working directory.
-- shortcut: checks cwd at startup only, re-entering a jj repo after :cd needs a restart
if not vim.fs.root(vim.fn.getcwd(), { ".jj" }) then
    return
end

-- Installation ------------------------------------------------------------ {{{
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
