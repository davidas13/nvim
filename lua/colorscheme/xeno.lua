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
    contrast = -0.4, -- Adjust contrast (-1 to 1, 0 is default)
    variation = 0.0, -- Adjust color variation strength (-1 to 1, 0 is default)
    transparent = false, -- Enable transparent background
}

xeno.new_theme("xeno", {
    base = "#1F1F28",
    accent = "#5c554c",
    contrast = -0.1,
})

vim.cmd [[colorscheme xeno]]
