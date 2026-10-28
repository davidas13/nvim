local specs = require "specs"

vim.pack.add {
    specs["conform.nvim"],
}

require("conform").setup {
    default_format_opts = require "default.plugin.conform.default_format_opts",
    formatters_by_ft = require "default.plugin.conform.formatters_by_ft",
    formatters = require "default.plugin.conform.formatters",
}

require "default.plugin.conform.keymaps"
