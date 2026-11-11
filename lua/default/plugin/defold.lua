-- Installation ------------------------------------------------------------ {{{
-- Defold tooling only loads inside a project root, marked by game.project.
if not vim.fs.root(0, "game.project") then
    return
end

local specs = require "specs"

vim.pack.add {
    specs["defold.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("defold").setup {
    -- config options, see below
}
-- }}}
