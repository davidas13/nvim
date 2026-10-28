local specs = require "specs"

vim.pack.add {
    specs["plenary.nvim"],
    specs["todo-comments.nvim"],
    specs["snacks.nvim"],
}

local snacks = require "snacks"

snacks.setup {
    input = require "default.plugin.snacks.input",
    debug = require "default.plugin.snacks.debug",
    explorer = require "default.plugin.snacks.explorer",
    bufdelete = require "default.plugin.snacks.bufdelete",
    indent = require "default.plugin.snacks.indent",
    picker = require "default.plugin.snacks.picker",
    notifier = require "default.plugin.snacks.notifier",
    toggle = require "default.plugin.snacks.toggle",
}

require "default.plugin.snacks.keymaps"
