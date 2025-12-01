-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/nvzone/volt" },

    -- Main plugin.
    { src = "https://github.com/gisketch/triforce.nvim" },
}

-- ==== Setup =================================================================
--
local triforce = require "triforce"

triforce.setup()

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set(
    "n",
    "<leader>\"p",
    triforce.show_profile,
    { noremap = true, silent = true, desc = "Open Triforce Profile" }
)

vim.keymap.set("n", "<leader>\"s", triforce.get_stats, { noremap = true, silent = true, desc = "Get Triforce Stats" })

vim.keymap.set(
    "n",
    "<leader>\"r",
    triforce.reset_stats,
    { noremap = true, silent = true, desc = "Reset Triforce Stats" }
)

vim.keymap.set("n", "<leader>\"S", triforce.save_stats, { noremap = true, silent = true, desc = "Save Triforce Stats" })

vim.keymap.set(
    "n",
    "<leader>\"d",
    triforce.debug_languages,
    { noremap = true, silent = true, desc = "Debug Triforce Languages" }
)
