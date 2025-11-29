-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/nvzone/volt" },

    -- Main plugin.
    { src = "https://github.com/gisketch/triforce.nvim" },
}

-- ==== Setup =================================================================
--
require("triforce").setup()

-- ==== Setup Keybindings =====================================================
--
