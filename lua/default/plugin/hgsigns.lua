-- Skip outside a Mercurial working directory.
-- shortcut: checks cwd at startup only, re-entering an hg repo after :cd needs a restart
if not vim.fs.root(vim.fn.getcwd(), { ".hg" }) then
    return
end

-- Installation ------------------------------------------------------------ {{{
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
