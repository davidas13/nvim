local specs = require "specs"

vim.pack.add {
    specs["tabby.nvim"],
}

require("tabby").setup {
    line = require "default.plugin.tabby.line",
}

require "default.plugin.tabby.keymaps"
