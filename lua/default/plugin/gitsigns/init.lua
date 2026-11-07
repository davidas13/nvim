-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["snacks.nvim"],
    specs["gitsigns.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("gitsigns").setup {
    signs = require "default.plugin.gitsigns.signs",
    signs_staged = require "default.plugin.gitsigns.signs_staged",
    on_attach = require "default.plugin.gitsigns.on_attach",
}

require("snacks")
    .toggle({
        name = "Git Signs",
        get = function()
            return require("gitsigns.config").config.signcolumn
        end,
        set = function(state)
            require("gitsigns").toggle_signs(state)
        end,
    })
    :map "<leader>tG"
-- }}}
