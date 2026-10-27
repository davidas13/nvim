-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["supermaven-nvim"],
    specs["blink-cmp-supermaven"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
local supermaven = require "supermaven-nvim"

supermaven.setup {
    log_level = "off",
    -- disables inline completion for use with cmp.
    disable_inline_completion = true,
    -- disables built in keymaps for more manual control.
    disable_keymaps = true,
    ignore_filetypes = { env = true },
}
-- }}}
