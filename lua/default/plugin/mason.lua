-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/mason-org/mason.nvim", version = "v2.1.0" },
}

-- ==== Setup =================================================================
--
require("mason").setup()
