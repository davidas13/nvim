-- ==== Intallation ===========================================================
vim.pack.add {
    {
        src = "https://github.com/gkeep/iceberg-dark",
        version = "master",
    },

    -- Main plugin.
    {
        src = "https://github.com/cocopon/iceberg.vim",
        version = "master",
    },
}
-- ==== Setup =================================================================
vim.cmd [[colorscheme iceberg]]
