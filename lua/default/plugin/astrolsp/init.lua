-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["blink.cmp"],
    specs["conform.nvim"],
    specs["nvim-lspconfig"],
    specs["snacks.nvim"],
    specs["astrolsp"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
-- Default LSP keymaps are removed so the on_attach mappings own them.
local keys = { "gra", "gri", "grn", "grr", "grt", "grO" }

for _, key in ipairs(keys) do
    pcall(vim.keymap.del, "n", key)
end

local astrolsp = require "astrolsp"

astrolsp.setup {
    features = require "default.plugin.astrolsp.features",
    autocmds = require "default.plugin.astrolsp.autocmds",
    commands = require "default.plugin.astrolsp.commands",
    capabilities = require "default.plugin.astrolsp.capabilities",
    defaults = require "default.plugin.astrolsp.defaults",
    file_operations = require "default.plugin.astrolsp.file_operations",
    flags = require "default.plugin.astrolsp.flags",
    formatting = require "default.plugin.astrolsp.formatting",
    handlers = require "default.plugin.astrolsp.handlers",
    servers = require "default.plugin.astrolsp.servers",
    config = require "default.plugin.astrolsp.config",
    on_attach = require "default.plugin.astrolsp.on_attach",
}

vim.tbl_map(astrolsp.lsp_setup, astrolsp.config.servers)
-- }}}
