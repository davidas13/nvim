-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs.xeno.nvim,
}
-- }}}

-- Setup {{{
local xeno = require "xeno"

xeno.config {
    -- Appearance adjustments
    contrast = 0.0, -- Adjust contrast (-1 to 1, 0 is default)
    variation = 0.0, -- Adjust color variation strength (-1 to 1, 0 is default)
    transparent = true, -- enable transparent background
}

xeno.new_theme("xeno-kanagawa", {
    base = "#16161D",
    accent = "#E4C184",
    -- contrast = -0.1,
})

vim.cmd [[colorscheme xeno-kanagawa]]
-- }}}
