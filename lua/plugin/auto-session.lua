-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/rmagatti/auto-session" },
}

-- ==== Setup =================================================================
--

require("auto-session").setup {
    suppressed_dirs = { "~/", "~/Desktop", "~/Documents", "~/Downloads", "/", "~/.config" },
}
