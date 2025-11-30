-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/vague-theme/vague.nvim", version = "main" },
}

-- ==== Setup =================================================================
--
require("vague").setup()

vim.cmd [[colorscheme vague]]
