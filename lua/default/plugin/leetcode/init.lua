-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["plenary.nvim"],
    specs["nui.nvim"],
    specs["leetcode.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("leetcode").setup {
    arg = require "default.plugin.leetcode.arg",
    lang = require "default.plugin.leetcode.lang",
    cn = require "default.plugin.leetcode.cn",
    storage = require "default.plugin.leetcode.storage",
    plugins = require "default.plugin.leetcode.plugins",
    logging = require "default.plugin.leetcode.logging",
    injector = require "default.plugin.leetcode.injector",
    cache = require "default.plugin.leetcode.cache",
    editor = require "default.plugin.leetcode.editor",
    console = require "default.plugin.leetcode.console",
    description = require "default.plugin.leetcode.description",
    picker = require "default.plugin.leetcode.picker",
    hooks = require "default.plugin.leetcode.hooks",
    keys = require "default.plugin.leetcode.keys",
    theme = require "default.plugin.leetcode.theme",
    image_support = require "default.plugin.leetcode.image_support",
}
-- }}}
