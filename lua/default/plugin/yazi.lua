-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["plenary.nvim"],
    specs["yazi.nvim"],
}

-- ==== Setup =================================================================
--
require("yazi").setup {
    open_for_directories = false,
    keymaps = {
        show_help = "<f1>",
    },
}

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set("n", "<leader>0", "<cmd>Yazi<cr>", { desc = "Open yazi at the current file" })
vim.keymap.set("n", "<leader>=", "<cmd>Yazi cwd<cr>", { desc = "Open the file manager in nvim's working directory" })
vim.keymap.set("n", "<leader>-", "<cmd>Yazi toggle<cr>", { desc = "Resume (Toggle) the last yazi session" })
