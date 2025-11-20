-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/folke/persistence.nvim" },
}

-- ==== Setup =================================================================
--
require("persistence").setup()

vim.keymap.set("n", "<leader>ql", function()
    require("persistence").load()
end, { desc = "Load Session" })

vim.keymap.set("n", "<leader>qL", function()
    require("persistence").select()
end, { desc = "Select Session" })
