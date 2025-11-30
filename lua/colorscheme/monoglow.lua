-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/wnkz/monoglow.nvim", version = "main" },
}

-- ==== Setup =================================================================
--
require("monoglow").setup()

vim.cmd [[colorscheme monoglow-void]]
