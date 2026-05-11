-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/webhooked/kanso.nvim", version = "main" },
}

-- ==== Setup =================================================================
--

require("kanso").setup {
    transparent = false,
    bold = true,
    italics = false,
    background = {
        dark = "ink",
    },
    foreground = "default",
    minimal = false,
}

vim.cmd [[colorscheme kanso]]
