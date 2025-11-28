-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/thesimonho/kanagawa-paper.nvim", version = "master" },

    -- Main plugin.
    { src = "https://github.com/rebelot/kanagawa.nvim", version = "master" },
}

-- ==== Setup =================================================================
--

require("kanagawa").setup {
    transparent = true,
    theme = "wave",
    colors = {
        theme = {
            all = {
                ui = {
                    bg_gutter = "none",
                },
            },
        },
    },
}

-- vim.cmd [[colorscheme kanagawa]]
vim.cmd [[colorscheme kanagawa-paper]]
