-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["persistence.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("persistence").setup()

vim.keymap.set("n", "<leader>ql", function()
    require("persistence").load()
end, { desc = "Load Session" })

vim.keymap.set("n", "<leader>qL", function()
    require("persistence").select()
end, { desc = "Select Session" })
-- }}}
