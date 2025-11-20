-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/folke/snacks.nvim" },
    { src = "https://github.com/jameswolensky/marker-groups.nvim" },
}

-- ==== Setup =================================================================
--
require("marker-groups").setup()
