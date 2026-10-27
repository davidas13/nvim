local specs = require "specs"

vim.pack.add {
    specs["mini.snippets"],
    specs["mini.icons"],
    specs["astrolsp"],

    -- AI plugins.
    -- Supermaven
    specs["supermaven-nvim"],
    specs["blink-cmp-supermaven"],

    specs["blink.compat"],
    specs["blink.cmp"],
}

require("blink.compat").setup {}

local blink = require "blink.cmp"

blink.setup {
    appearance = require "default.plugin.blink.appearance",
    sources = require "default.plugin.blink.sources",
    fuzzy = require "default.plugin.blink.fuzzy",
    keymap = require "default.plugin.blink.keymap",
    completion = require "default.plugin.blink.completion",
    signature = require "default.plugin.blink.signature",
    cmdline = require "default.plugin.blink.cmdline",
    snippets = require "default.plugin.blink.snippets",
}
