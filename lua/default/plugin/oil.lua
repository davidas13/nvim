-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main Plugin.
    { src = "https://github.com/stevearc/oil.nvim" },
}

-- ==== Setup =================================================================
--
require("oil").setup {
    delete_to_trash = true,
    float = {
        max_width = 0.9,
    }
}

-- ==== Setup Keybindings =====================================================
--
