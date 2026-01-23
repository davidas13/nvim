-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/neanias/everforest-nvim" },
}

-- ==== Setup =================================================================
--
require("everforest").setup {
    background = "hard",
    transparent_background_level = 2,
}

vim.cmd [[colorscheme everforest]]
