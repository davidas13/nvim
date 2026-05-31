-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["hlchunk.nvim"],
}
-- }}}

-- Setup {{{
require("hlchunk").setup {
    chunk = {
        enable = true,
        priority = 15,
        duration = 0,
        delay = 0,
        -- style = "#C99B54",
        style = "#EA6962",
    },
    line_num = {
        enable = true,
        -- style = "#7CAEA3",
        style = "#C99B54",
        priority = 10,
    },
    indent = {
        enable = true,
    },
}
-- }}}
