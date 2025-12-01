-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/kyza0d/xeno.nvim", version = "master" },
}

-- ==== Setup =================================================================
--
local xeno = require "xeno"

xeno.config {
    -- Appearance adjustments
    contrast = 0.0, -- Adjust contrast (-1 to 1, 0 is default)
    variation = 0.0, -- Adjust color variation strength (-1 to 1, 0 is default)
    transparent = true, -- enable transparent background
}

xeno.new_theme("xeno-kanagawa", {
    base = "#1F1F28",
    accent = "#54546D",
    contrast = -0.1,
})

vim.cmd [[colorscheme xeno-kanagawa]]
