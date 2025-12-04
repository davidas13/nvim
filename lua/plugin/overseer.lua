-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/stevearc/overseer.nvim" },
}

-- ==== Setup =================================================================
--
require("overseer").setup()

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set("n", "<leader>oo", ":OverseerOpen<CR>", { noremap = true, silent = true, desc = "Overseer Open" })

vim.keymap.set("n", "<leader>oc", ":OverseerClose<CR>", { noremap = true, silent = true, desc = "Overseer Close" })

vim.keymap.set("n", "<leader>ot", ":OverseerToggle<CR>", { noremap = true, silent = true, desc = "Overseer Toggle" })

vim.keymap.set("n", "<leader>or", ":OverseerRun<CR>", { noremap = true, silent = true, desc = "Overseer Run" })

vim.keymap.set("n", "<leader>os", ":OverseerShell<CR>", { noremap = true, silent = true, desc = "Overseer Shell" })

vim.keymap.set(
    "n",
    "<leader>oa",
    ":OverseerTaskAction<CR>",
    { noremap = true, silent = true, desc = "Overseer Task Action" }
)
