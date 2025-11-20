-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/echasnovski/mini.pairs" },
}

-- ==== Setup =================================================================
--
require("mini.pairs").setup {
    modes = {
        insert = true,
        command = false,
        terminal = false,
    },
}
